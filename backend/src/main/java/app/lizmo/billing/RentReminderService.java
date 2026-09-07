package app.lizmo.billing;

import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.notification.Notification;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationRepository;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Telling tenants that rent is coming, and that it is late.
 *
 * <p>Run from Cloud Scheduler rather than generated when somebody looks, which
 * is the opposite of how billing periods work and deliberately so. A period
 * nobody has opened can be created on demand because nobody needed it until
 * they looked. A reminder is for the tenant who has <em>stopped</em> looking,
 * so it cannot wait to be asked for.
 *
 * <p>In-app only for now, on Ariel's call. That limits what it can achieve —
 * the reminder appears in the bell rather than arriving anywhere — but the
 * records are the thing push delivers a copy of when it exists, so the same
 * work starts arriving without changing any of this.
 */
@Service
public class RentReminderService {

    /** How long before rent falls due to say so. */
    static final int DAYS_BEFORE = 5;

    /** And how often to keep saying it once it is late. */
    static final Duration WHILE_LATE = Duration.ofDays(7);

    private static final Logger log = LoggerFactory.getLogger(RentReminderService.class);

    private final PropertyRepository properties;
    private final UnitRepository units;
    private final LeaseRepository leases;
    private final BillingPeriodRepository periods;
    private final NotificationRepository notifications;
    private final NotificationService raise;
    private final BillingService billing;
    private final Clock clock;

    public RentReminderService(
            PropertyRepository properties,
            UnitRepository units,
            LeaseRepository leases,
            BillingPeriodRepository periods,
            NotificationRepository notifications,
            NotificationService raise,
            BillingService billing,
            Clock clock) {
        this.properties = properties;
        this.units = units;
        this.leases = leases;
        this.periods = periods;
        this.notifications = notifications;
        this.raise = raise;
        this.billing = billing;
        this.clock = clock;
    }

    /**
     * One pass over every live tenancy.
     *
     * @return how many reminders were sent, for the job log. A run that sends
     *         nothing and a run that failed look identical otherwise.
     */
    @Transactional
    public int run() {
        LocalDate today = LocalDate.now(clock);
        Instant now = clock.instant();
        int sent = 0;

        for (Lease lease : liveLeases()) {
            // Far enough ahead that the month being warned about exists. Without
            // this the first month of a tenancy could never be warned about at
            // all: its period is not written until the tenancy starts, and by
            // then the five days are gone.
            billing.catchUp(lease, today.plusDays(DAYS_BEFORE));

            for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(
                    lease.getId())) {

                if (period.getStatus() == BillingPeriodStatus.PAID) {
                    continue;
                }

                if (period.isOverdue(today)) {
                    if (remind(lease, period, NotificationType.RENT_OVERDUE, now)) {
                        sent++;
                    }
                } else if (!today.isBefore(period.getDueDate().minusDays(DAYS_BEFORE))) {
                    if (remind(lease, period, NotificationType.RENT_DUE_REMINDER, now)) {
                        sent++;
                    }
                }
            }
        }

        log.info("Rent reminders: sent {}", sent);
        return sent;
    }

    /**
     * Sends one, unless it has been said recently enough.
     *
     * <p>The notifications already raised are the record of what was sent, so
     * no second table is needed to keep this idempotent. A due reminder goes
     * once per period; an overdue one repeats weekly.
     *
     * <p>That matters more than it looks. Cloud Scheduler retries a failed run
     * three times, and a job that resent everything on each retry would put
     * four identical messages in somebody's bell for one late month.
     */
    private boolean remind(
            Lease lease, BillingPeriod period, NotificationType type, Instant now) {

        Notification last = notifications
                .findFirstByRecipientUserIdAndTypeAndRelatedEntityIdOrderByCreatedAtDesc(
                        lease.getTenantId(), type, period.getId())
                .orElse(null);

        if (last != null) {
            if (type == NotificationType.RENT_DUE_REMINDER) {
                // Said once. Repeating it before the due date has even arrived
                // would be nagging about something nobody is late for.
                return false;
            }
            if (last.getCreatedAt() != null
                    && last.getCreatedAt().plus(WHILE_LATE).isAfter(now)) {
                return false;
            }
        }

        BigDecimal owed = period.outstanding();

        if (type == NotificationType.RENT_DUE_REMINDER) {
            raise.raise(
                    lease.getTenantId(),
                    type,
                    "Rent is due soon",
                    "P%s for %s, due on %s."
                            .formatted(plain(owed), period.getPeriodLabel(),
                                    period.getDueDate()),
                    NotificationEntityType.BILLING_PERIOD,
                    period.getId());
        } else {
            raise.raise(
                    lease.getTenantId(),
                    type,
                    "Rent is overdue",
                    // No threat and no penalty: Lizmo does not know what the
                    // arrangement is between these two people, and inventing
                    // consequences would be speaking for the landlord.
                    "P%s for %s was due on %s and has not been recorded as paid."
                            .formatted(plain(owed), period.getPeriodLabel(),
                                    period.getDueDate()),
                    NotificationEntityType.BILLING_PERIOD,
                    period.getId());
        }
        return true;
    }

    /**
     * Every active tenancy, across every landlord.
     *
     * <p>Walked from properties rather than straight from leases so that a
     * lease orphaned by a deleted property cannot keep reminding somebody
     * about a room that is not there.
     */
    private List<Lease> liveLeases() {
        List<Lease> live = new java.util.ArrayList<>();
        for (Property property : properties.findAll()) {
            for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(property.getId())) {
                live.addAll(leases.findByUnitIdAndStatus(unit.getId(), LeaseStatus.ACTIVE));
            }
        }
        return live;
    }

    private static String plain(BigDecimal amount) {
        return amount.stripTrailingZeros().toPlainString();
    }
}
