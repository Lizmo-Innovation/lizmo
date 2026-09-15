package app.lizmo.billing.dto;

import app.lizmo.billing.PaymentMethod;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Money handed over, as either side writes it down.
 *
 * <p>The same shape from both, because it is the same event. What differs is
 * who is claiming it, which the endpoint knows without being told.
 *
 * @param paymentDate when the money actually moved, which is often not today:
 *                    a landlord writes down on Monday the cash they were handed
 *                    on Saturday. Defaults to today when left out.
 */
@Schema(description = "Recording a rent payment")
public record RecordPaymentRequest(
        @NotNull
        @Schema(description = "Which month this pays for")
        UUID billingPeriodId,

        @NotNull
        @Schema(example = "2500.00") BigDecimal amountPaid,

        @Schema(example = "2026-10-05") LocalDate paymentDate,

        @Schema(example = "GCASH", description = "Defaults to OTHER")
        PaymentMethod paymentMethod,

        @Size(max = 500)
        @Schema(example = "Sent from my mother's number")
        String remarks,

        @Schema(description = "Which of the landlord's payment channels it was sent to, "
                + "if any. Kept as the channel read at that moment.")
        UUID channelId) {
}
