package app.lizmo.lease;

import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.property.BedRepository;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Warning both sides that a lease is coming to its end.
 *
 * <p>A month out and in the last week, to the tenant and the landlord; once
 * the date has gone by with nothing done, to the landlord alone. Nothing more
 * than that: passing the date ends nothing. Somebody may still be living
 * there, paying rent, and only the landlord knows whether they are -- so the
 * tenancy stays, and keeps billing, until they extend it or end it.
 *
 * <p>Run by the daily rent-reminder job rather than a job of its own, which
 * would be the fourth and cost money every month.
 *
 * <p>Each warning is said once, recorded on the lease. A missed day, or a date
 * set only five days out, goes straight to whichever warning is due.
 */
@Service
public class LeaseTermWarnings {

    /** When "about a month" starts. */
    static final int MONTH = 30;

    /** And the last week. */
    static final int WEEK = 7;

    private final LeaseRepository leases;
    private final UnitRepository units;
    private final BedRepository beds;
    private final PropertyRepository properties;
    private final NotificationService notifications;
    private final Clock clock;

    public LeaseTermWarnings(
            LeaseRepository leases,
            UnitRepository units,
            BedRepository beds,
            PropertyRepository properties,
            NotificationService notifications,
            Clock clock) {
        this.leases = leases;
        this.units = units;
        this.beds = beds;
        this.properties = properties;
        this.notifications = notifications;
        this.clock = clock;
    }

    /** @return how many were sent, for the job log. */
    @Transactional
    public int run() {
        LocalDate today = LocalDate.now(clock);
        int sent = 0;

        for (Lease lease : leases.findByStatusAndTermEndsOnIsNotNull(LeaseStatus.ACTIVE)) {
            TermWarning due = due(today, lease.getTermEndsOn());
            if (due == null || !later(due, lease.getTermWarned())) {
                continue;
            }

            Unit unit = units.findById(lease.getUnitId()).orElse(null);
            Property property = unit == null
                    ? null
                    : properties.findById(unit.getPropertyId()).orElse(null);
            if (property == null) {
                continue;
            }

            sent += warn(lease, due, today, place(lease, unit), property);
            lease.warned(due);
            leases.save(lease);
        }
        return sent;
    }

    /** Which warning the date calls for today, or null for none yet. */
    static TermWarning due(LocalDate today, LocalDate endsOn) {
        long left = ChronoUnit.DAYS.between(today, endsOn);
        if (left < 0) {
            return TermWarning.PASSED;
        }
        if (left <= WEEK) {
            return TermWarning.WEEK;
        }
        if (left <= MONTH) {
            return TermWarning.MONTH;
        }
        return null;
    }

    private static boolean later(TermWarning due, TermWarning already) {
        return already == null || due.ordinal() > already.ordinal();
    }

    private int warn(
            Lease lease, TermWarning due, LocalDate today, String place, Property property) {
        String on = LeaseDates.spoken(lease.getTermEndsOn());
        UUID landlord = property.getLandlordId();

        if (due == TermWarning.PASSED) {
            // The room, not the tenant's name: it is read on a lock screen.
            notifications.raise(
                    landlord,
                    NotificationType.LEASE_EXPIRING,
                    "A lease has reached its end date",
                    "The tenant in %s at %s was due to leave on %s. If they are staying, "
                            .formatted(place, property.getName(), on)
                            + "extend the lease. If they have gone, end the tenancy so the "
                            + "room can be let again.",
                    NotificationEntityType.LEASE,
                    lease.getId());
            return 1;
        }

        String when = in(ChronoUnit.DAYS.between(today, lease.getTermEndsOn()));
        notifications.raise(
                lease.getTenantId(),
                NotificationType.LEASE_EXPIRING,
                "Your lease ends " + when,
                "On %s, at %s. If you want to stay, ask your landlord to extend it."
                        .formatted(on, property.getName()),
                NotificationEntityType.LEASE,
                lease.getId());
        notifications.raise(
                landlord,
                NotificationType.LEASE_EXPIRING,
                "A lease ends " + when,
                "The tenant in %s at %s, on %s. Extend it if they are staying."
                        .formatted(place, property.getName(), on),
                NotificationEntityType.LEASE,
                lease.getId());
        return 2;
    }

    /** "today", "tomorrow", "in 30 days". */
    static String in(long days) {
        if (days <= 0) {
            return "today";
        }
        if (days == 1) {
            return "tomorrow";
        }
        return "in " + days + " days";
    }

    /** "Bed 1, 2B" or "Unit 101": how both sides name the room. */
    private String place(Lease lease, Unit unit) {
        if (lease.getBedId() == null) {
            return "Unit " + unit.getUnitNumber();
        }
        return beds.findById(lease.getBedId())
                .map(bed -> bed.getBedLabel() + ", " + unit.getUnitNumber())
                .orElse("Unit " + unit.getUnitNumber());
    }
}
