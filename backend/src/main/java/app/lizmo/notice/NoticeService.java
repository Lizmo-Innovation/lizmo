package app.lizmo.notice;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.notice.NoticeDtos.MyNoticeResponse;
import app.lizmo.notice.NoticeDtos.NoticeResponse;
import app.lizmo.notice.NoticeDtos.PostNotice;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.user.UserRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Announcements: a landlord telling everybody in a building, or in one unit,
 * the same thing at once.
 *
 * <p>Who sees one is worked out from where people live now, not from who was
 * told: somebody who moves in next week sees the house rules posted last
 * month, and somebody who moved out stops seeing them. Only the people living
 * there when it is posted are notified -- a notification is news, and a
 * notice from before you arrived is not.
 */
@Service
public class NoticeService {

    /** Whose calendar "until" is read in. */
    private static final ZoneId PHILIPPINES = ZoneId.of("Asia/Manila");

    /** How much of the message a lock screen is given. */
    private static final int PREVIEW = 140;

    private final NoticeRepository notices;
    private final PropertyAccess access;
    private final PropertyRepository properties;
    private final UnitRepository units;
    private final LeaseRepository leases;
    private final UserRepository users;
    private final NotificationService notifications;
    private final JdbcTemplate jdbc;
    private final Clock clock;

    public NoticeService(
            NoticeRepository notices,
            PropertyAccess access,
            PropertyRepository properties,
            UnitRepository units,
            LeaseRepository leases,
            UserRepository users,
            NotificationService notifications,
            JdbcTemplate jdbc,
            Clock clock) {
        this.notices = notices;
        this.access = access;
        this.properties = properties;
        this.units = units;
        this.leases = leases;
        this.users = users;
        this.notifications = notifications;
        this.jdbc = jdbc;
        this.clock = clock;
    }

    // ---- the landlord ------------------------------------------------------

    /**
     * Posts one, and tells everybody it is for who lives there now.
     *
     * <p>Allowed while the property is locked for an unpaid Lizmo invoice:
     * "the water is off on Saturday" must not wait on a bill.
     */
    @Transactional
    public NoticeResponse post(UUID propertyId, UUID landlordId, PostNotice command) {
        Property property = access.readable(propertyId, landlordId);
        Unit unit = command.unitId() == null ? null : unitIn(property, command.unitId());

        LocalDate today = LocalDate.now(clock.withZone(PHILIPPINES));
        if (command.until() != null && command.until().isBefore(today)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Pick a last day from today on.");
        }

        Notice notice = notices.save(new Notice(
                landlordId,
                propertyId,
                unit == null ? null : unit.getId(),
                command.title().trim(),
                command.message().trim(),
                clock.instant(),
                command.until() == null
                        ? null
                        // Shown through the whole of its last day, here.
                        : command.until().plusDays(1).atStartOfDay(PHILIPPINES).toInstant()));

        for (UUID tenant : audience(notice)) {
            notifications.raise(
                    tenant,
                    NotificationType.NEW_NOTICE_POSTED,
                    "%s: %s".formatted(property.getName(), notice.getTitle()),
                    preview(notice.getMessage()),
                    NotificationEntityType.NOTICE,
                    notice.getId());
        }

        return describe(notice, property);
    }

    /** What is up on one building, newest first, with who has seen each. */
    @Transactional(readOnly = true)
    public List<NoticeResponse> forProperty(UUID propertyId, UUID landlordId) {
        Property property = access.readable(propertyId, landlordId);
        return notices.findByPropertyIdAndArchivedFalseOrderByPostedAtDesc(propertyId).stream()
                .map(notice -> describe(notice, property))
                .toList();
    }

    /** Gone from every tenant's screen. Kept, not deleted: it was said. */
    @Transactional
    public void takeDown(UUID noticeId, UUID landlordId) {
        Notice notice = notices.findById(noticeId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such notice."));
        access.readable(notice.getPropertyId(), landlordId);
        if (!notice.isArchived()) {
            notice.takeDown(clock.instant());
            notices.save(notice);
        }
    }

    // ---- the tenant --------------------------------------------------------

    /** What is up where they live now, newest first. */
    @Transactional(readOnly = true)
    public List<MyNoticeResponse> mine(UUID tenantId) {
        List<Lease> living = leases.findByTenantIdOrderByStartDateDesc(tenantId).stream()
                .filter(Lease::isActive)
                .toList();
        if (living.isEmpty()) {
            return List.of();
        }

        Set<UUID> theirUnits = new HashSet<>();
        Map<UUID, UUID> propertyOfUnit = new HashMap<>();
        for (Lease lease : living) {
            theirUnits.add(lease.getUnitId());
            units.findById(lease.getUnitId())
                    .ifPresent(unit -> propertyOfUnit.put(unit.getId(), unit.getPropertyId()));
        }
        Set<UUID> theirBuildings = new LinkedHashSet<>(propertyOfUnit.values());

        Instant now = clock.instant();
        Set<UUID> read = readBy(tenantId);
        return notices.findByPropertyIdInAndArchivedFalseOrderByPostedAtDesc(theirBuildings)
                .stream()
                .filter(notice -> notice.isLive(now))
                .filter(notice -> notice.getUnitId() == null
                        || theirUnits.contains(notice.getUnitId()))
                .map(notice -> new MyNoticeResponse(
                        notice.getId(),
                        properties.findById(notice.getPropertyId())
                                .map(Property::getName).orElse(null),
                        notice.getUnitId() == null ? null : unitNumber(notice.getUnitId()),
                        users.findById(notice.getPostedBy())
                                .map(user -> user.getName()).orElse(null),
                        notice.getTitle(),
                        notice.getMessage(),
                        notice.getPostedAt(),
                        until(notice),
                        read.contains(notice.getId())))
                .toList();
    }

    /**
     * Opened. Only a notice they can see now: a tenant cannot mark one from a
     * building they do not live in, which would count them as somebody it
     * reached.
     */
    @Transactional
    public void read(UUID noticeId, UUID tenantId) {
        boolean theirs = mine(tenantId).stream()
                .anyMatch(notice -> notice.id().equals(noticeId));
        if (!theirs) {
            throw new ApiException(ErrorCode.NOT_FOUND, "No such notice.");
        }
        jdbc.update("""
                INSERT INTO notice_reads (notice_id, tenant_id) VALUES (?, ?)
                ON CONFLICT DO NOTHING
                """, noticeId, tenantId);
    }

    // ---- the shared parts --------------------------------------------------

    /** Everybody renting where it is for, now. */
    private Set<UUID> audience(Notice notice) {
        List<UUID> where = notice.getUnitId() != null
                ? List.of(notice.getUnitId())
                : units.findByPropertyIdOrderByUnitNumberAsc(notice.getPropertyId()).stream()
                        .map(Unit::getId)
                        .toList();
        Set<UUID> tenants = new LinkedHashSet<>();
        if (where.isEmpty()) {
            return tenants;
        }
        for (Lease lease : leases.findByUnitIdInAndStatus(where, LeaseStatus.ACTIVE)) {
            tenants.add(lease.getTenantId());
        }
        return tenants;
    }

    private NoticeResponse describe(Notice notice, Property property) {
        Set<UUID> audience = audience(notice);
        int seen = 0;
        if (!audience.isEmpty()) {
            List<UUID> readers = jdbc.queryForList(
                    "SELECT tenant_id FROM notice_reads WHERE notice_id = ?",
                    UUID.class, notice.getId());
            // Of the people it is for now: somebody who read it and moved out
            // is no longer one of them.
            seen = (int) readers.stream().filter(audience::contains).count();
        }
        return new NoticeResponse(
                notice.getId(),
                property.getId(),
                property.getName(),
                notice.getUnitId(),
                notice.getUnitId() == null ? null : unitNumber(notice.getUnitId()),
                notice.getTitle(),
                notice.getMessage(),
                notice.getPostedAt(),
                until(notice),
                notice.isLive(clock.instant()),
                seen,
                audience.size());
    }

    private Set<UUID> readBy(UUID tenantId) {
        return new HashSet<>(jdbc.queryForList(
                "SELECT notice_id FROM notice_reads WHERE tenant_id = ?",
                UUID.class, tenantId));
    }

    private Unit unitIn(Property property, UUID unitId) {
        return units.findById(unitId)
                .filter(unit -> unit.getPropertyId().equals(property.getId()))
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such unit here."));
    }

    private String unitNumber(UUID unitId) {
        return units.findById(unitId).map(Unit::getUnitNumber).orElse(null);
    }

    /** The last day it is shown, in the calendar it was chosen in. */
    private static LocalDate until(Notice notice) {
        Instant expires = notice.getExpiresAt();
        return expires == null ? null : expires.atZone(PHILIPPINES).toLocalDate().minusDays(1);
    }

    private static String preview(String message) {
        String flat = message.replaceAll("\\s+", " ").trim();
        return flat.length() <= PREVIEW ? flat : flat.substring(0, PREVIEW - 1).trim() + "…";
    }
}
