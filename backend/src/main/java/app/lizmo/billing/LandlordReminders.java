package app.lizmo.billing;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeasePaperworkAccess;
import app.lizmo.notification.Notification;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationRepository;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A landlord reminding a tenant, by hand, that rent is late.
 *
 * <p>On top of the weekly reminder the daily job already sends, for the
 * landlord who would otherwise text. It says what is owed and nothing else:
 * no threat and no penalty, because Lizmo does not know what the two of them
 * have agreed, and inventing consequences would be speaking for the landlord.
 *
 * <p>Once a day at most, per tenancy. Tapped twice by mistake, or every hour
 * by somebody frustrated, it would turn a reminder into harassment.
 */
@Service
public class LandlordReminders {

    /** How long before another can be sent for the same tenancy. */
    static final Duration ONCE_A_DAY = Duration.ofHours(20);

    private final LeasePaperworkAccess access;
    private final BillingPeriodRepository periods;
    private final BillingService billing;
    private final NotificationRepository notifications;
    private final NotificationService raise;
    private final Clock clock;

    public LandlordReminders(
            LeasePaperworkAccess access,
            BillingPeriodRepository periods,
            BillingService billing,
            NotificationRepository notifications,
            NotificationService raise,
            Clock clock) {
        this.access = access;
        this.periods = periods;
        this.billing = billing;
        this.notifications = notifications;
        this.raise = raise;
        this.clock = clock;
    }

    @Transactional
    public Instant remind(UUID leaseId, UUID landlordId) {
        Lease lease = access.requireLandlord(leaseId, landlordId);
        if (!lease.isActive()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "That tenancy has ended.");
        }

        LocalDate today = LocalDate.now(clock);
        // The month may not have been billed yet if nobody has looked since.
        billing.catchUp(lease, today);
        BigDecimal late = BigDecimal.ZERO;
        BillingPeriod oldest = null;
        for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(leaseId)) {
            if (period.isOverdue(today)) {
                late = late.add(period.outstanding());
                if (oldest == null) {
                    oldest = period;
                }
            }
        }
        if (late.signum() <= 0) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "Nothing is late on this tenancy.");
        }

        Instant now = clock.instant();
        Instant last = lastSent(lease);
        if (last != null) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "You reminded them today. Another can go tomorrow.");
        }

        raise.raise(
                lease.getTenantId(),
                NotificationType.RENT_OVERDUE,
                "A reminder from your landlord",
                "P%s is overdue, the oldest for %s. Pay when you can, then tap I have paid."
                        .formatted(late.stripTrailingZeros().toPlainString(), oldest.describe()),
                NotificationEntityType.LEASE,
                lease.getId());
        return now;
    }

    /** The last reminder sent by hand for this tenancy, within the last day. */
    @Transactional(readOnly = true)
    public Instant lastSent(Lease lease) {
        Instant since = clock.instant().minus(ONCE_A_DAY);
        return notifications
                .findFirstByRecipientUserIdAndTypeAndRelatedEntityIdOrderByCreatedAtDesc(
                        lease.getTenantId(), NotificationType.RENT_OVERDUE, lease.getId())
                .map(Notification::getCreatedAt)
                .filter(at -> at != null && at.isAfter(since))
                .orElse(null);
    }
}
