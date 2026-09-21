package app.lizmo.billing.dto;

import app.lizmo.billing.Payment;
import app.lizmo.billing.PaymentMethod;
import app.lizmo.billing.PaymentStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * One recorded payment.
 *
 * @param periodLabel which month it pays for, in words, so a list of payments
 *                    reads without a second request per row.
 * @param sentTo where the payer said the money went, as the landlord's channel
 *               read when they chose it. Null for cash and older payments.
 * @param remarks the payer's own note, as they wrote it.
 * @param rejectionReason why the landlord said it did not arrive, when it was
 *                        refused with a reason. Null otherwise, and for
 *                        payments refused before this was kept apart.
 * @param proofUrl a presigned link to the screenshot, valid for a few minutes,
 *                 or null when none was attached. Proof is optional: cash is
 *                 real, and a required field nobody can satisfy becomes one
 *                 people lie in.
 */
@Schema(description = "A recorded rent payment")
public record PaymentResponse(
        UUID id,
        UUID billingPeriodId,
        String periodLabel,
        BigDecimal amountPaid,
        LocalDate paymentDate,
        PaymentMethod paymentMethod,
        String sentTo,
        PaymentStatus status,
        String remarks,
        String rejectionReason,
        String proofUrl,
        long proofUrlExpiresInSeconds) {

    public static PaymentResponse of(
            Payment payment, String periodLabel, String proofUrl, long expiresIn) {
        return new PaymentResponse(
                payment.getId(),
                payment.getBillingPeriodId(),
                periodLabel,
                payment.getAmountPaid(),
                payment.getPaymentDate(),
                payment.getPaymentMethod(),
                payment.getSentTo(),
                payment.getStatus(),
                payment.getRemarks(),
                payment.getRejectionReason(),
                proofUrl,
                expiresIn);
    }
}
