package app.lizmo.billing.dto;

import app.lizmo.billing.BillingPeriod;
import app.lizmo.billing.BillingPeriodStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * One month of rent, as both sides see it.
 *
 * @param overdue worked out on the server against today, not stored. A period
 *                that fell due yesterday is late today without anything having
 *                run overnight, and a client computing it from a clock that may
 *                be a day out would disagree with the landlord's screen.
 * @param outstanding what is still owed, so no screen has to subtract. Never
 *                    negative: somebody who handed over an extra hundred pesos
 *                    has not created a debt in the other direction.
 */
@Schema(description = "One month of rent")
public record BillingPeriodResponse(
        UUID id,
        String label,
        LocalDate periodStart,
        LocalDate periodEnd,
        LocalDate dueDate,
        BigDecimal amountDue,
        BigDecimal amountPaid,
        BigDecimal outstanding,
        BillingPeriodStatus status,
        boolean overdue,
        // RENT or DEPOSIT: a deposit is money held, and is shown apart.
        app.lizmo.billing.BillingPeriodKind kind) {

    public static BillingPeriodResponse of(BillingPeriod period, LocalDate today) {
        return new BillingPeriodResponse(
                period.getId(),
                period.getPeriodLabel(),
                period.getPeriodStart(),
                period.getPeriodEnd(),
                period.getDueDate(),
                period.getAmountDue(),
                period.getAmountPaid(),
                period.outstanding(),
                period.getStatus(),
                period.isOverdue(today),
                period.getKind());
    }
}
