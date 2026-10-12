package app.lizmo.billing.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.util.List;

/**
 * What a landlord opens the app to find out.
 *
 * <p>Three questions, in the order they are asked: how much is owed me, how
 * much has come in, and who is behind. The dashboard has promised this since
 * the beginning under a placeholder reading "Needs leases and billing".
 *
 * @param dueThisMonth what fell due in the month being asked about, across
 *                     every tenancy. Not a running total of all time: a
 *                     landlord asking "how am I doing" means this month.
 * @param collectedThisMonth of that, what has been confirmed. Only confirmed:
 *                           a tenant's unverified claim is not money.
 * @param outstandingAllTime everything still owed across every live tenancy,
 *                           however old. Kept apart from the monthly figures
 *                           because a landlord owed for three past months and
 *                           paid up for this one is not doing well, and one
 *                           number cannot say both.
 * @param awaitingConfirmation how many tenant claims are waiting on the
 *                             landlord. The one figure that is about their own
 *                             behaviour rather than their tenants'.
 * @param awaiting those claims, one row each, oldest first. The count alone
 *                 told a landlord somebody was waiting and gave them no way to
 *                 find out who.
 */
@Schema(description = "Rent across every property, this month")
public record CollectionsSummary(
        BigDecimal dueThisMonth,
        BigDecimal collectedThisMonth,
        BigDecimal outstandingAllTime,
        int awaitingConfirmation,
        int tenanciesInArrears,
        List<ArrearsRow> inArrears,
        List<AwaitingRow> awaiting,
        // Deposits received on live tenancies: money held, given back at
        // move-out, and never counted as collected rent.
        BigDecimal depositsHeld) {

    /**
     * One tenant who is behind.
     *
     * @param monthsLate how many periods are past due and unpaid, which is what
     *                   a landlord judges by. Two months late is a different
     *                   conversation from two days.
     */
    @Schema(description = "A tenant who is behind")
    public record ArrearsRow(
            java.util.UUID leaseId,
            String tenantName,
            String propertyName,
            String unitNumber,
            String bedLabel,
            BigDecimal outstanding,
            int monthsLate,
            java.time.LocalDate oldestDueDate,
            // A deposit past its move-in day and not yet received. Apart from
            // rent: it is owed, but it is not income.
            BigDecimal depositOwed) {
    }

    /**
     * One payment a tenant says they have made, waiting on the landlord.
     *
     * @param paidOn the date the tenant gave, not the date they told the app.
     */
    @Schema(description = "A payment waiting for the landlord to confirm it")
    public record AwaitingRow(
            java.util.UUID leaseId,
            java.util.UUID paymentId,
            String tenantName,
            String propertyName,
            String unitNumber,
            String bedLabel,
            BigDecimal amount,
            java.time.LocalDate paidOn,
            // Which of the landlord's accounts to check. Null for cash.
            String sentTo,
            // When the tenant told the app: how long it has been waiting.
            java.time.Instant declaredAt) {
    }
}
