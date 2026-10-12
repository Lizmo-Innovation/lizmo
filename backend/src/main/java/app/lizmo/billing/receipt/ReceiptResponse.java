package app.lizmo.billing.receipt;

import app.lizmo.billing.BillingPeriodKind;
import app.lizmo.billing.PaymentMethod;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Schema(description = "An acknowledgement receipt for a confirmed payment. Not a BIR "
        + "official receipt.")
public record ReceiptResponse(
        UUID id,
        UUID paymentId,
        UUID leaseId,
        @Schema(example = "2026-0042",
                description = "Numbered per landlord, per year, in the order issued")
        String number,
        Instant issuedAt,
        String receivedFrom,
        String receivedBy,
        String propertyName,
        @Schema(example = "Bed 1, 2B") String place,
        @Schema(example = "October 2026") String periodLabel,
        BillingPeriodKind kind,
        BigDecimal amount,
        PaymentMethod paymentMethod,
        String sentTo,
        LocalDate paidOn,
        @Schema(description = "What was left of that month, or the deposit, once this "
                + "was counted. Zero when it settled it.")
        BigDecimal stillOwed) {

    static ReceiptResponse of(Receipt receipt) {
        return new ReceiptResponse(
                receipt.getId(),
                receipt.getPaymentId(),
                receipt.getLeaseId(),
                receipt.getNumber(),
                receipt.getIssuedAt(),
                receipt.getReceivedFrom(),
                receipt.getReceivedBy(),
                receipt.getPropertyName(),
                receipt.getPlace(),
                receipt.getPeriodLabel(),
                receipt.getKind(),
                receipt.getAmount(),
                receipt.getPaymentMethod(),
                receipt.getSentTo(),
                receipt.getPaidOn(),
                receipt.getStillOwed());
    }
}
