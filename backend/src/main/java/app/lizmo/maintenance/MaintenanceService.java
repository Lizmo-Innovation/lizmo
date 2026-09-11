package app.lizmo.maintenance;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.DocumentType;
import app.lizmo.document.ImageNormaliser;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeasePaperworkAccess;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.maintenance.dto.MaintenanceNote;
import app.lizmo.maintenance.dto.MaintenanceReportResponse;
import app.lizmo.maintenance.dto.ReportProblemRequest;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.property.BedRepository;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.user.UserRepository;
import java.io.IOException;
import java.time.Clock;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * Something broken, reported and dealt with.
 *
 * <p>A conversation with two sides, and every step reaches the side that did
 * not take it: the landlord hears a report arrive, the tenant hears it started
 * and fixed, the landlord hears it is still broken. A report nobody on the
 * other end hears about is a suggestion box, and a tenant only has to be
 * ignored once to stop using it.
 *
 * <p>Whether a step is allowed is decided here rather than on the entity,
 * because the answer goes back to a person as a sentence.
 */
@Service
public class MaintenanceService {

    private static final Duration URL_LIFETIME = Duration.ofMinutes(10);

    private static final long MAX_UPLOAD_BYTES = 10L * 1024 * 1024;

    /** Enough for a close-up and the wall around it, and not a photo album. */
    private static final int MAX_PHOTOS = 3;

    private final MaintenanceReportRepository reports;
    private final LeaseRepository leases;
    private final LeasePaperworkAccess paperwork;
    private final PropertyRepository properties;
    private final PropertyAccess access;
    private final UnitRepository units;
    private final BedRepository beds;
    private final UserRepository users;
    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;
    private final NotificationService notifications;
    private final Clock clock;

    public MaintenanceService(
            MaintenanceReportRepository reports,
            LeaseRepository leases,
            LeasePaperworkAccess paperwork,
            PropertyRepository properties,
            PropertyAccess access,
            UnitRepository units,
            BedRepository beds,
            UserRepository users,
            StoredDocumentRepository documents,
            DocumentStore store,
            ImageNormaliser normaliser,
            NotificationService notifications,
            Clock clock) {
        this.reports = reports;
        this.leases = leases;
        this.paperwork = paperwork;
        this.properties = properties;
        this.access = access;
        this.units = units;
        this.beds = beds;
        this.users = users;
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
        this.notifications = notifications;
        this.clock = clock;
    }

    // ---- the tenant --------------------------------------------------------

    /**
     * Reports something broken, against the tenancy the tenant lives under now.
     *
     * <p>The tenancy is worked out rather than asked for: somebody reporting a
     * leak should not be choosing a lease id, and there is nothing to report
     * about a room they no longer live in.
     */
    @Transactional
    public MaintenanceReportResponse report(UUID tenantId, ReportProblemRequest command) {
        Lease lease = leases.findByTenantIdOrderByStartDateDesc(tenantId).stream()
                .filter(Lease::isActive)
                .findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.VALIDATION_FAILED,
                        "You can report a problem once you are renting through Lizmo."));

        String description = command.description() == null ? "" : command.description().trim();
        if (description.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "Say what is broken.");
        }

        MaintenanceReport report = reports.save(new MaintenanceReport(
                lease.getId(), lease.getUnitId(), lease.getBedId(), tenantId,
                description, clock.instant()));

        // Where, not who, and not what. A notification is read on a lock
        // screen, and the tenant told their landlord about the problem, not
        // everybody standing near the landlord's phone.
        notifications.raise(
                paperwork.landlordOf(lease),
                NotificationType.MAINTENANCE_REPORTED,
                "Something needs fixing",
                "A tenant reported a problem in " + where(report) + ".",
                NotificationEntityType.MAINTENANCE_REQUEST,
                report.getId());

        return describe(report);
    }

    /** Adds one photograph, while nobody has started working from what was sent. */
    @Transactional
    public MaintenanceReportResponse addPhoto(UUID reportId, UUID tenantId, MultipartFile file) {
        MaintenanceReport report = tenantsOwn(reportId, tenantId);
        require(report, "Photos can only be added before your landlord starts on it.",
                MaintenanceStatus.SUBMITTED);

        if (photosOf(report).size() >= MAX_PHOTOS) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A report can have up to " + MAX_PHOTOS + " photos.");
        }
        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "That photo was empty.");
        }
        if (file.getSize() > MAX_UPLOAD_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file is larger than 10MB. Please upload a smaller photo.");
        }

        byte[] original;
        try {
            original = file.getBytes();
        } catch (IOException e) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That upload did not arrive in one piece. Please try again.");
        }

        // Re-encoded like every other photograph, so no EXIF and no location
        // leaves somebody's phone.
        byte[] normalised = normaliser.normalise(original);
        String key = "maintenance/%s/%s.jpg".formatted(report.getId(), UUID.randomUUID());
        store.put(key, normalised, ImageNormaliser.OUTPUT_CONTENT_TYPE);

        documents.save(new StoredDocument(
                DocumentOwnerType.MAINTENANCE_REQUEST,
                report.getId(),
                tenantId,
                DocumentType.OTHER,
                key,
                ImageNormaliser.OUTPUT_CONTENT_TYPE,
                normalised.length));

        return describe(report);
    }

    @Transactional(readOnly = true)
    public List<MaintenanceReportResponse> mine(UUID tenantId) {
        return reports.findBySubmittedByOrderBySubmittedAtDesc(tenantId).stream()
                .map(this::describe)
                .toList();
    }

    /**
     * Takes a report back, while nobody has started on it.
     *
     * <p>Not after: somebody may already have bought the part.
     */
    @Transactional
    public MaintenanceReportResponse withdraw(UUID reportId, UUID tenantId) {
        MaintenanceReport report = tenantsOwn(reportId, tenantId);
        require(report,
                "Your landlord has already started on this, so it can no longer be taken back.",
                MaintenanceStatus.SUBMITTED);

        report.withdraw(clock.instant());
        reports.save(report);

        tellLandlord(report, "A report was taken back",
                "The problem reported in " + where(report) + " was taken back by the tenant.");
        return describe(report);
    }

    /** The tenant agreeing it is fixed, which only they can say. */
    @Transactional
    public MaintenanceReportResponse confirmFixed(UUID reportId, UUID tenantId) {
        MaintenanceReport report = tenantsOwn(reportId, tenantId);
        require(report, "Only something your landlord has marked fixed can be closed.",
                MaintenanceStatus.RESOLVED);

        report.close(clock.instant());
        reports.save(report);
        return describe(report);
    }

    /** The tenant saying it is still broken, and why. */
    @Transactional
    public MaintenanceReportResponse reopen(UUID reportId, UUID tenantId, MaintenanceNote note) {
        MaintenanceReport report = tenantsOwn(reportId, tenantId);
        require(report, "Only something your landlord has marked fixed can be reopened.",
                MaintenanceStatus.RESOLVED);

        String reason = note == null || note.text() == null ? "" : note.text().trim();
        if (reason.isEmpty()) {
            // The reason is the whole of what the landlord needs to hear.
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "Say what is still wrong.");
        }

        report.reopen(reason, clock.instant());
        reports.save(report);

        tellLandlord(report, "Still not fixed",
                "The tenant in " + where(report) + " says the problem is still there.");
        return describe(report);
    }

    // ---- the landlord ------------------------------------------------------

    /** Every report on this landlord's properties, newest first. */
    @Transactional(readOnly = true)
    public List<MaintenanceReportResponse> forLandlord(UUID landlordId) {
        List<UUID> unitIds = new ArrayList<>();
        for (Property property : properties.findByLandlordIdOrderByNameAsc(landlordId)) {
            for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(property.getId())) {
                unitIds.add(unit.getId());
            }
        }
        if (unitIds.isEmpty()) {
            return List.of();
        }
        return reports.findByUnitIdInOrderBySubmittedAtDesc(unitIds).stream()
                .map(this::describe)
                .toList();
    }

    @Transactional(readOnly = true)
    public MaintenanceReportResponse one(UUID reportId, UUID landlordId) {
        return describe(landlordsOwn(reportId, landlordId));
    }

    @Transactional
    public MaintenanceReportResponse start(UUID reportId, UUID landlordId, MaintenanceNote note) {
        MaintenanceReport report = landlordsOwn(reportId, landlordId);
        require(report, "That is already being dealt with.", MaintenanceStatus.SUBMITTED);

        String remarks = textOf(note);
        report.start(remarks, clock.instant());
        reports.save(report);

        tellTenant(report, "Your landlord is on it",
                remarks == null
                        ? "Your landlord has started on the problem you reported."
                        : remarks);
        return describe(report);
    }

    /**
     * The landlord saying it is fixed.
     *
     * <p>From SUBMITTED as well as IN_PROGRESS: a bulb gets changed before
     * anybody thinks to press "start".
     */
    @Transactional
    public MaintenanceReportResponse resolve(UUID reportId, UUID landlordId, MaintenanceNote note) {
        MaintenanceReport report = landlordsOwn(reportId, landlordId);
        require(report, "That is not open.",
                MaintenanceStatus.SUBMITTED, MaintenanceStatus.IN_PROGRESS);

        String remarks = textOf(note);
        report.resolve(remarks, clock.instant());
        reports.save(report);

        tellTenant(report, "Your landlord says it is fixed",
                (remarks == null ? "" : remarks + " ")
                        + "Is it? Say so, or say it is still broken.");
        return describe(report);
    }

    // ---- shared ------------------------------------------------------------

    /**
     * @throws ApiException 404 unless the caller sent it, so a report id from
     *                      anywhere reveals nothing
     */
    private MaintenanceReport tenantsOwn(UUID reportId, UUID tenantId) {
        return reports.findById(reportId)
                .filter(report -> report.getSubmittedBy().equals(tenantId))
                .orElseThrow(MaintenanceService::notFound);
    }

    /**
     * Also after the tenancy ends. A landlord still needs to finish, and find,
     * the work on a room somebody has moved out of.
     *
     * @throws ApiException 404 unless the report is on the caller's property
     */
    private MaintenanceReport landlordsOwn(UUID reportId, UUID landlordId) {
        MaintenanceReport report = reports.findById(reportId)
                .orElseThrow(MaintenanceService::notFound);
        Unit unit = units.findById(report.getUnitId())
                .orElseThrow(MaintenanceService::notFound);
        // Throws the same not-found if the property is not theirs.
        access.readable(unit.getPropertyId(), landlordId);
        return report;
    }

    private static void require(
            MaintenanceReport report, String why, MaintenanceStatus... allowed) {
        for (MaintenanceStatus status : allowed) {
            if (report.getStatus() == status) {
                return;
            }
        }
        throw new ApiException(ErrorCode.VALIDATION_FAILED, why);
    }

    private void tellLandlord(MaintenanceReport report, String title, String message) {
        leases.findById(report.getLeaseId()).ifPresent(lease -> notifications.raise(
                paperwork.landlordOf(lease),
                NotificationType.MAINTENANCE_STATUS_CHANGED,
                title,
                message,
                NotificationEntityType.MAINTENANCE_REQUEST,
                report.getId()));
    }

    private void tellTenant(MaintenanceReport report, String title, String message) {
        notifications.raise(
                report.getSubmittedBy(),
                NotificationType.MAINTENANCE_STATUS_CHANGED,
                title,
                message,
                NotificationEntityType.MAINTENANCE_REQUEST,
                report.getId());
    }

    /** "Bed 1 in 2B", or "Unit 2B". */
    private String where(MaintenanceReport report) {
        String unit = units.findById(report.getUnitId()).map(Unit::getUnitNumber).orElse("?");
        String bed = report.getBedId() == null ? null
                : beds.findById(report.getBedId()).map(b -> b.getBedLabel()).orElse(null);
        return bed == null ? "Unit " + unit : bed + " in " + unit;
    }

    private static String textOf(MaintenanceNote note) {
        if (note == null || note.text() == null || note.text().isBlank()) {
            return null;
        }
        return note.text().trim();
    }

    private List<StoredDocument> photosOf(MaintenanceReport report) {
        return documents.findByOwnerTypeAndOwnerId(
                DocumentOwnerType.MAINTENANCE_REQUEST, report.getId());
    }

    private MaintenanceReportResponse describe(MaintenanceReport report) {
        Unit unit = units.findById(report.getUnitId()).orElse(null);
        Property property = unit == null ? null
                : properties.findById(unit.getPropertyId()).orElse(null);
        String bedLabel = report.getBedId() == null ? null
                : beds.findById(report.getBedId()).map(b -> b.getBedLabel()).orElse(null);

        List<String> photoUrls = photosOf(report).stream()
                .sorted(Comparator.comparing(StoredDocument::getUploadedAt))
                .map(document -> store.presignedUrl(document.getStorageKey(), URL_LIFETIME))
                .toList();

        return new MaintenanceReportResponse(
                report.getId(),
                report.getLeaseId(),
                property == null ? null : property.getId(),
                property == null ? null : property.getName(),
                unit == null ? null : unit.getUnitNumber(),
                bedLabel,
                users.findById(report.getSubmittedBy()).map(user -> user.getName()).orElse(null),
                report.getDescription(),
                report.getStatus(),
                report.getLandlordRemarks(),
                report.getReopenedAt() != null,
                report.getReopenReason(),
                report.getSubmittedAt(),
                report.getUpdatedAt(),
                report.getResolvedAt(),
                report.getClosedAt(),
                photoUrls,
                URL_LIFETIME.toSeconds());
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No such report.");
    }
}
