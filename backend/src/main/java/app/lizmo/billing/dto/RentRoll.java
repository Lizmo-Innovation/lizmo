package app.lizmo.billing.dto;

import app.lizmo.billing.PaymentMethod;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Every tenancy's rent for one month, across everything a landlord owns.
 *
 * <p>A month's rent belongs to the month it falls due in -- the same rule the
 * dashboard uses -- so the Rent tab and Today cannot disagree about which
 * month a payment was for.
 *
 * <p>Tenancies that have since ended are still here for the months they owed.
 * Leaving them out would rewrite August every time somebody moved out, and a
 * landlord looking back at August wants August as it was.
 *
 * @param month         the month asked about, as {@code 2026-09}.
 * @param earliestMonth the first month any tenancy owed rent, so the app knows
 *                      how far back there is anything to see. Null when nothing
 *                      has ever been due.
 * @param due           everything that fell due in the month.
 * @param collected     of that, what has been confirmed. A tenant's unverified
 *                      claim is not money, here or anywhere.
 * @param outstanding   what is still owed for the month. Never negative.
 * @param rows          by property, then unit, then bed.
 */
@Schema(description = "Every tenancy's rent for one month")
public record RentRoll(
        String month,
        String earliestMonth,
        BigDecimal due,
        BigDecimal collected,
        BigDecimal outstanding,
        List<RentRollRow> rows) {

    /**
     * One tenancy's rent for the month.
     *
     * @param current whether the tenancy is still running. False for somebody
     *                who has moved out and still appears for a month they owed.
     * @param waiting what the tenant says they have paid towards this month and
     *                the landlord has not yet answered, oldest first.
     */
    @Schema(description = "One tenancy's rent for the month")
    public record RentRollRow(
            UUID propertyId,
            String propertyName,
            UUID leaseId,
            boolean current,
            String tenantName,
            String unitNumber,
            String bedLabel,
            BillingPeriodResponse period,
            List<WaitingPayment> waiting) {
    }

    /**
     * A payment a tenant says they made, waiting on the landlord.
     *
     * @param note what the tenant wrote alongside it, which is often the thing
     *             that decides whether the landlord believes it.
     * @param sentTo which of the landlord's accounts the tenant says it went to,
     *               so they know where to look. Null for cash.
     */
    @Schema(description = "A payment waiting for the landlord to confirm it")
    public record WaitingPayment(
            UUID paymentId,
            BigDecimal amount,
            LocalDate paidOn,
            PaymentMethod method,
            String note,
            String sentTo) {
    }
}
