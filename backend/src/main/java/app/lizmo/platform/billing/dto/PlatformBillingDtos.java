package app.lizmo.platform.billing.dto;

import app.lizmo.billing.PaymentMethod;
import app.lizmo.billing.PaymentStatus;
import app.lizmo.platform.billing.PlatformStatementStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** What goes over the wire for Lizmo billing a landlord. */
public final class PlatformBillingDtos {

    private PlatformBillingDtos() {
    }

    /**
     * One month's bill for a landlord, itemised by property.
     *
     * @param label   "September 2026".
     * @param overdue past due with something still owed, worked out today.
     * @param locksOn the day their properties stop being added to if this is
     *                still unpaid. Null once paid, or once it has locked them.
     * @param locked  whether this statement is what locked them.
     * @param lines   one per property. Each carries an invoice number once the
     *                statement has been paid in full, and none before.
     */
    @Schema(description = "What a landlord owes Lizmo for one month")
    public record PlatformStatementResponse(
            UUID id,
            String label,
            LocalDate billingDate,
            LocalDate dueDate,
            BigDecimal amountDue,
            BigDecimal amountPaid,
            BigDecimal outstanding,
            PlatformStatementStatus status,
            boolean overdue,
            LocalDate locksOn,
            boolean locked,
            List<PlatformInvoiceLine> lines,
            List<PlatformPaymentResponse> payments) {
    }

    /**
     * One property's share of the month.
     *
     * @param invoiceNumber what it is called once it is an invoice, such as
     *                      LZM-2026-09-0007. Null while the statement is
     *                      unpaid: nothing has been paid for yet.
     * @param issuedAt      when it became an invoice.
     */
    @Schema(description = "One property's share of a month, and its invoice once paid")
    public record PlatformInvoiceLine(
            UUID id,
            UUID propertyId,
            String propertyName,
            int occupiedUnits,
            int occupiedBeds,
            BigDecimal unitRate,
            BigDecimal bedRate,
            BigDecimal amountDue,
            String invoiceNumber,
            Instant issuedAt) {
    }

    /**
     * A payment sent against a statement.
     *
     * @param proofUrl presigned, good for {@code proofUrlExpiresInSeconds}.
     */
    @Schema(description = "A payment sent to Lizmo")
    public record PlatformPaymentResponse(
            UUID id,
            BigDecimal amountPaid,
            LocalDate paymentDate,
            PaymentMethod paymentMethod,
            PaymentStatus status,
            String remarks,
            String proofUrl,
            long proofUrlExpiresInSeconds,
            Instant submittedAt) {
    }

    /**
     * A payment waiting in the admin's queue, with enough to decide on it
     * without opening anything else.
     *
     * @param properties how many properties the statement covers, which is why
     *                   the figure is what it is.
     */
    @Schema(description = "A landlord's payment to Lizmo, for an admin to review")
    public record PlatformPaymentForAdmin(
            UUID id,
            UUID statementId,
            UUID landlordId,
            String landlordName,
            String statementLabel,
            int properties,
            BigDecimal statementAmountDue,
            BigDecimal statementOutstanding,
            BigDecimal amountPaid,
            LocalDate paymentDate,
            PaymentMethod paymentMethod,
            PaymentStatus status,
            String remarks,
            String proofUrl,
            long proofUrlExpiresInSeconds,
            Instant submittedAt) {
    }

    /**
     * A landlord saying they have paid.
     *
     * @param paymentDate when the money moved, which is often not today.
     *                    Defaults to today.
     */
    @Schema(description = "Paying a Lizmo statement")
    public record PlatformPaymentRequest(
            @NotNull @Schema(example = "850.00") BigDecimal amountPaid,
            @Schema(example = "2026-09-03") LocalDate paymentDate,
            @Schema(example = "GCASH") PaymentMethod paymentMethod,
            @Size(max = 500) @Schema(example = "Reference 4012 8876 1123") String remarks) {
    }

    /** Why an admin refused a payment. Shown to the landlord. */
    @Schema(description = "Why a payment was refused")
    public record PlatformPaymentRejection(
            @Size(max = 500) @Schema(example = "Nothing arrived under that reference.")
            String remarks) {
    }
}
