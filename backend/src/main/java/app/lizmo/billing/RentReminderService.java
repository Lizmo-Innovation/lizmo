package app.lizmo.billing;

import app.lizmo.inquiry.InquiryRepository;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.notification.Notification;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationRepository;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.property.BedRepository;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
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
 * <p>And chasing a payment a tenant has declared and nobody has answered.
 * The landlord is told when they tap, once; missed, nothing said it again,
 * and the month stayed unpaid on both sides while the tenant -- who had paid
 * -- was told weekly that their rent was overdue.
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

    /** How long a declared payment waits before its landlord is reminded. */
    static final Duration UNANSWERED = Duration.ofDays(3);

    /** And how often after that, until they confirm or reject it. */
    static final Duration UNANSWERED_AGAIN = Duration.ofDays(7);

    /** How long before the tenant is told it is worth asking. Said once. */
    static final Duration WORTH_ASKING = Duration.ofDays(7);

    private static final Logger log = LoggerFactory.getLogger(RentReminderService.class);

    private final PropertyRepository properties;
    private final UnitRepository units;
    private final LeaseRepository leases;
    private final BillingPeriodRepository periods;
    private final NotificationRepository notifications;
    private final NotificationService raise;
    private final BillingService billing;
    private final PaymentRepository payments;
    private final BedRepository beds;
    private final InquiryRepository conversations;
    private final Clock clock;

    public RentReminderService(
            PropertyRepository properties,
            UnitRepository units,
            LeaseRepository leases,
            BillingPeriodRepository periods,
            NotificationRepository notifications,
            NotificationService raise,
            BillingService billing,
            PaymentRepository payments,
            BedRepository beds,
            InquiryRepository conversations,
            Clock clock) {
        this.properties = properties;
        this.units = units;
        this.leases = leases;
        this.periods = periods;
        this.notifications = notifications;
        this.raise = raise;
        this.billing = billing;
        this.payments = payments;
        this.beds = beds;
        this.conversations = conversations;
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

        for (Live live : liveLeases()) {
            Lease lease = live.lease();
            // Far enough ahead that the month being warned about exists. Without
            // this the first month of a tenancy could never be warned about at
            // all: its period is not written until the tenancy starts, and by
            // then the five days are gone.
            billing.catchUp(lease, today.plusDays(DAYS_BEFORE));

            List<Payment> waiting = payments
                    .findByLeaseIdOrderByPaymentDateDesc(lease.getId()).stream()
                    .filter(payment -> payment.getStatus() == PaymentStatus.PENDING_VERIFICATION)
                    .toList();

            for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(
                    lease.getId())) {

                if (period.getStatus() == BillingPeriodStatus.PAID) {
                    continue;
                }

                // What the tenant has said they paid and is waiting to have
                // confirmed. A month they have paid in full is not theirs to be
                // chased about: it is waiting on the landlord.
                BigDecimal declared = waiting.stream()
                        .filter(payment -> payment.getBillingPeriodId().equals(period.getId()))
                        .map(Payment::getAmountPaid)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
                if (declared.compareTo(period.outstanding()) >= 0) {
                    continue;
                }

                if (period.isOverdue(today)) {
                    if (remind(lease, period, declared, NotificationType.RENT_OVERDUE, now)) {
                        sent++;
                    }
                } else if (!today.isBefore(period.getDueDate().minusDays(DAYS_BEFORE))) {
                    if (remind(lease, period, declared,
                            NotificationType.RENT_DUE_REMINDER, now)) {
                        sent++;
                    }
                }
            }

            for (Payment payment : waiting) {
                sent += chase(live, payment, now);
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
            Lease lease, BillingPeriod period, BigDecimal declared,
            NotificationType type, Instant now) {

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

        // Only what is not already waiting on the landlord. Part of it
        // declared is said, so the figure does not read as a contradiction
        // of what the tenant told the app.
        BigDecimal owed = period.outstanding().subtract(declared);
        String alsoWaiting = declared.signum() > 0
                ? " P%s more is waiting for your landlord to confirm."
                        .formatted(plain(declared))
                : "";

        if (type == NotificationType.RENT_DUE_REMINDER) {
            raise.raise(
                    lease.getTenantId(),
                    type,
                    period.isDeposit() ? "Your security deposit is due soon" : "Rent is due soon",
                    "P%s for %s, due on %s.%s"
                            .formatted(plain(owed), period.describe(),
                                    period.getDueDate(), alsoWaiting),
                    NotificationEntityType.BILLING_PERIOD,
                    period.getId());
        } else {
            raise.raise(
                    lease.getTenantId(),
                    type,
                    period.isDeposit() ? "Your security deposit is overdue" : "Rent is overdue",
                    // No threat and no penalty: Lizmo does not know what the
                    // arrangement is between these two people, and inventing
                    // consequences would be speaking for the landlord.
                    "P%s for %s was due on %s and has not been recorded as paid.%s"
                            .formatted(plain(owed), period.describe(),
                                    period.getDueDate(), alsoWaiting),
                    NotificationEntityType.BILLING_PERIOD,
                    period.getId());
        }
        return true;
    }

    /**
     * Chases one declared payment nobody has answered: the landlord after
     * three days and weekly after that, the tenant once after a week.
     *
     * <p>Counted from when the tenant told the app, not the date they gave --
     * a payment made on the 1st and declared on the 9th has kept nobody
     * waiting since the 1st.
     *
     * <p>Idempotent the same way rent reminders are: the notifications raised
     * are the record of what was said, keyed by the payment.
     *
     * @return how many were said, for the job log.
     */
    private int chase(Live live, Payment payment, Instant now) {
        if (payment.getCreatedAt() == null) {
            return 0;
        }
        // To the second. The database keeps microseconds and rounds what it is
        // given, so a time read back can sit a fraction past the one written --
        // and "three days" would come out a hair short of three days.
        Instant declaredAt = payment.getCreatedAt().truncatedTo(ChronoUnit.SECONDS);
        Duration waited = Duration.between(declaredAt, now);
        int said = 0;

        UUID landlord = live.property().getLandlordId();
        if (waited.compareTo(UNANSWERED) >= 0
                && quietFor(landlord, NotificationType.PAYMENT_AWAITING_CONFIRMATION,
                        payment.getId(), UNANSWERED_AGAIN, now)) {
            BillingPeriod period = periods.findById(payment.getBillingPeriodId()).orElse(null);
            raise.raise(
                    landlord,
                    NotificationType.PAYMENT_AWAITING_CONFIRMATION,
                    "A payment is still waiting for you",
                    // The room, not the name: it is read on a lock screen. And
                    // both answers, because "it did not arrive" is as useful
                    // to the tenant as "it did".
                    "The tenant in %s at %s says they paid P%s for %s, %s. Confirm it, or say "
                            .formatted(placeOf(live.lease()), live.property().getName(),
                                    plain(payment.getAmountPaid()),
                                    period == null ? "rent" : period.describe(),
                                    ago(waited))
                            + "it did not arrive.",
                    NotificationEntityType.PAYMENT,
                    payment.getId());
            said++;
        }

        UUID tenant = live.lease().getTenantId();
        UUID about = conversationOrPayment(live, payment);
        // Told already if the last one about this was said after this payment
        // became worth asking about. Keyed by time rather than by payment so
        // the reminder can point at the conversation: a later payment, waiting
        // a week months from now, is told again.
        Instant askable = declaredAt.plus(WORTH_ASKING);
        boolean told = notifications
                .findFirstByRecipientUserIdAndTypeAndRelatedEntityIdOrderByCreatedAtDesc(
                        tenant, NotificationType.PAYMENT_STILL_UNCONFIRMED, about)
                .map(last -> last.getCreatedAt() != null
                        && !last.getCreatedAt().plusSeconds(1).isBefore(askable))
                .orElse(false);
        if (waited.compareTo(WORTH_ASKING) >= 0 && !told) {
            BillingPeriod period = periods.findById(payment.getBillingPeriodId()).orElse(null);
            boolean talking = conversationOf(live) != null;
            raise.raise(
                    tenant,
                    NotificationType.PAYMENT_STILL_UNCONFIRMED,
                    "Your payment is not confirmed yet",
                    "P%s for %s has waited %s for your landlord to confirm it. It is worth "
                            .formatted(plain(payment.getAmountPaid()),
                                    period == null ? "rent" : period.describe(),
                                    days(waited))
                            + "asking them.",
                    // Their conversation with the landlord, where asking is one
                    // tap -- or the payment, for a tenancy with no thread yet.
                    talking ? NotificationEntityType.INQUIRY : NotificationEntityType.PAYMENT,
                    about);
            said++;
        }
        return said;
    }

    /** Whether nothing of this kind about this was said within {@code gap}. */
    private boolean quietFor(
            UUID recipient, NotificationType type, UUID about, Duration gap, Instant now) {
        return notifications
                .findFirstByRecipientUserIdAndTypeAndRelatedEntityIdOrderByCreatedAtDesc(
                        recipient, type, about)
                // To the second, for the same reason as the wait itself.
                .map(last -> last.getCreatedAt() == null
                        || !last.getCreatedAt().truncatedTo(ChronoUnit.SECONDS)
                                .plus(gap).isAfter(now))
                .orElse(true);
    }

    private UUID conversationOf(Live live) {
        return conversations
                .findByTenantIdAndPropertyId(live.lease().getTenantId(), live.property().getId())
                .map(inquiry -> inquiry.getId())
                .orElse(null);
    }

    /**
     * What the tenant's reminder points at: the conversation with their
     * landlord if there is one, where asking is one tap, else the payment.
     */
    private UUID conversationOrPayment(Live live, Payment payment) {
        UUID thread = conversationOf(live);
        return thread != null ? thread : payment.getId();
    }

    /** "Bed 1, 2B" or "Unit 101": how both sides name the room. */
    private String placeOf(Lease lease) {
        String unit = units.findById(lease.getUnitId())
                .map(Unit::getUnitNumber)
                .orElse("their room");
        if (lease.getBedId() == null) {
            return "Unit " + unit;
        }
        return beds.findById(lease.getBedId())
                .map(bed -> bed.getBedLabel() + ", " + unit)
                .orElse(unit);
    }

    private static String ago(Duration waited) {
        return days(waited) + " ago";
    }

    private static String days(Duration waited) {
        long days = waited.toDays();
        return days == 1 ? "1 day" : days + " days";
    }

    /**
     * Every active tenancy, across every landlord.
     *
     * <p>Walked from properties rather than straight from leases so that a
     * lease orphaned by a deleted property cannot keep reminding somebody
     * about a room that is not there.
     */
    private List<Live> liveLeases() {
        List<Live> live = new java.util.ArrayList<>();
        for (Property property : properties.findAll()) {
            for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(property.getId())) {
                for (Lease lease : leases.findByUnitIdAndStatus(
                        unit.getId(), LeaseStatus.ACTIVE)) {
                    live.add(new Live(property, lease));
                }
            }
        }
        return live;
    }

    /** A live tenancy and the property it is in, which has the landlord. */
    private record Live(Property property, Lease lease) {
    }

    private static String plain(BigDecimal amount) {
        return amount.stripTrailingZeros().toPlainString();
    }
}
