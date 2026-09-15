package app.lizmo.paymentchannel.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * What goes over the wire for a list of ways to pay.
 *
 * <p>The same shapes whether the money goes to Lizmo or to a landlord, so the
 * apps draw both with one card.
 */
public final class PaymentChannelDtos {

    private PaymentChannelDtos() {
    }

    /**
     * Adding or changing a channel.
     *
     * @param visible whether it is shown to whoever pays. Left as it is when not
     *                sent, and shown when adding.
     */
    @Schema(description = "A way to be paid, as its owner enters it")
    public record PaymentChannelRequest(
            @NotBlank @Size(max = 40) @Schema(example = "GCash") String channel,
            @NotBlank @Size(max = 120) @Schema(example = "Ariel Asebias") String accountName,
            @NotBlank @Size(max = 60) @Schema(example = "09771231234") String accountNumber,
            Boolean visible) {
    }

    /**
     * A channel as its owner sees it, hidden ones included.
     *
     * @param qrUrl presigned, good for {@code qrUrlExpiresInSeconds}. Null when
     *              the channel has no QR.
     */
    @Schema(description = "A way to be paid, for its owner")
    public record PaymentChannelResponse(
            UUID id,
            String channel,
            String accountName,
            String accountNumber,
            boolean visible,
            int sortOrder,
            String qrUrl,
            long qrUrlExpiresInSeconds) {
    }

    /**
     * A channel as whoever pays sees it. No visibility or ordering: they only
     * ever get the visible ones, already in order.
     */
    @Schema(description = "A way to pay")
    public record PaymentChannelView(
            UUID id,
            String channel,
            String accountName,
            String accountNumber,
            String qrUrl,
            long qrUrlExpiresInSeconds) {
    }

    /**
     * Everything somebody needs to pay.
     *
     * @param note the free-text line kept under the channels, such as "put your
     *             property name in the reference". Null when blank.
     */
    @Schema(description = "How to pay")
    public record PaymentDetails(List<PaymentChannelView> channels, String note) {
    }

    /** The whole list, top to bottom. Every channel exactly once. */
    @Schema(description = "The order channels are shown in")
    public record PaymentChannelOrder(@NotEmpty List<UUID> ids) {
    }

    /** The line shown under a landlord's channels. Blank clears it. */
    @Schema(description = "A note shown under the channels")
    public record PaymentNote(
            @Size(max = 500) @Schema(example = "Cash to Aling Nena at unit 1A") String note) {
    }
}
