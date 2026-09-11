package app.lizmo.platform.billing.dto;

import app.lizmo.billing.PaymentMethod;
import app.lizmo.billing.PaymentStatus;
import app.lizmo.platform.billing.PlatformInvoiceStatus;
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
     * One property's invoice for one month, as the landlord and an admin see it.
     *
     * @param label        "September 2026".
     * @param overdue      past due with something still owed, worked out today.
     * @param locksOn      the day the property stops being added to if this is
     *                     still unpaid. Null once paid, or once it has locked.
     * @param lockedByThis whether this invoice is what locked the property.
     */
    @Schema(description = "What one property owes Lizmo for one month")
    public record PlatformInvoiceResponse(
            UUID id,
            UUID propertyId,
            String propertyName,
            String label,
            LocalDate billingDate,
            LocalDate dueDate,
            int occupiedUnits,
            int occupiedBeds,
            BigDecimal unitRate,
            BigDecimal bedRate,
            BigDecimal amountDue,
            BigDecimal amountPaid,
            BigDecimal outstanding,
            PlatformInvoiceStatus status,
            boolean overdue,
            LocalDate locksOn,
            boolean lockedByThis,
            List<PlatformPaymentResponse> payments) {
    }

    /**
     * A payment sent against an invoice.
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
     */
    @Schema(description = "A landlord's payment to Lizmo, for an admin to review")
    public record PlatformPaymentForAdmin(
            UUID id,
            UUID invoiceId,
            UUID landlordId,
            String landlordName,
            String propertyName,
            String invoiceLabel,
            BigDecimal invoiceAmountDue,
            BigDecimal invoiceOutstanding,
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
    @Schema(description = "Paying a Lizmo invoice")
    public record PlatformPaymentRequest(
            @NotNull @Schema(example = "450.00") BigDecimal amountPaid,
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

    /** Where to send money to Lizmo, as an admin wrote it. */
    @Schema(description = "How to pay Lizmo")
    public record PaymentInstructions(
            @Schema(example = "GCash 0917 123 4567 (Lizmo Innovation)") String instructions) {
    }
}
