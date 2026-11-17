package app.lizmo.billing;

import app.lizmo.lease.Lease;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * What a tenancy owes next, for the panel at the top of its conversation.
 *
 * <p>The oldest month not yet paid: the one a landlord would chase and the
 * one a tenant would pay, the same month "I have paid" is about.
 */
@Service
public class TenancyRent {

    private final BillingPeriodRepository periods;
    private final BillingService billing;
    private final Clock clock;

    public TenancyRent(BillingPeriodRepository periods, BillingService billing, Clock clock) {
        this.periods = periods;
        this.billing = billing;
        this.clock = clock;
    }

    /** Null when nothing is owed, or the tenancy has ended. */
    @Transactional
    public RentOwed owed(Lease lease) {
        if (lease == null || !lease.isActive()) {
            return null;
        }
        LocalDate today = LocalDate.now(clock);
        // The month may not have been billed yet if nobody has looked since.
        billing.catchUp(lease, today);
        for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(lease.getId())) {
            if (period.getStatus() != BillingPeriodStatus.PAID
                    && period.outstanding().signum() > 0) {
                return new RentOwed(
                        period.getId(),
                        period.describe(),
                        period.outstanding(),
                        period.getDueDate(),
                        period.isOverdue(today));
            }
        }
        return null;
    }

    /**
     * The month to settle next.
     *
     * @param label how both sides say it: "November 2026", or "the security
     *              deposit".
     */
    @Schema(description = "The oldest month a tenancy has not yet paid")
    public record RentOwed(
            UUID billingPeriodId,
            String label,
            BigDecimal outstanding,
            LocalDate dueDate,
            boolean overdue) {
    }
}
