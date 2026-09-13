package app.lizmo.platform.payment.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/** What goes over the wire for the ways to pay Lizmo. */
public final class PaymentChannelDtos {

    private PaymentChannelDtos() {
    }

    /**
     * Adding or changing a channel.
     *
     * @param visible whether landlords are shown it. Left as it is when not
     *                sent, and shown when adding.
     */
    @Schema(description = "A way to pay Lizmo, as an admin enters it")
    public record PaymentChannelRequest(
            @NotBlank @Size(max = 40) @Schema(example = "GCash") String channel,
            @NotBlank @Size(max = 120) @Schema(example = "Ariel Asebias") String accountName,
            @NotBlank @Size(max = 60) @Schema(example = "09771231234") String accountNumber,
            Boolean visible) {
    }

    /**
     * A channel as the console shows it, hidden ones included.
     *
     * @param qrUrl presigned, good for {@code qrUrlExpiresInSeconds}. Null when
     *              the channel has no QR.
     */
    @Schema(description = "A way to pay Lizmo, for an admin")
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
     * A channel as a landlord sees it. No visibility or ordering: they only
     * ever get the visible ones, already in order.
     */
    @Schema(description = "A way to pay Lizmo")
    public record PaymentChannelForLandlord(
            UUID id,
            String channel,
            String accountName,
            String accountNumber,
            String qrUrl,
            long qrUrlExpiresInSeconds) {
    }

    /**
     * Everything a landlord needs to pay.
     *
     * @param note the free-text line an admin keeps under the channels, such as
     *             "put your property name in the reference". Null when blank.
     */
    @Schema(description = "How to pay Lizmo")
    public record PaymentDetails(List<PaymentChannelForLandlord> channels, String note) {
    }

    /** The whole list, top to bottom. Every channel exactly once. */
    @Schema(description = "The order channels are shown in")
    public record PaymentChannelOrder(@NotEmpty List<UUID> ids) {
    }
}
