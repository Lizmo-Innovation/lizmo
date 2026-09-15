package app.lizmo.platform.payment;

import app.lizmo.common.ApiError;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelOrder;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelRequest;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelResponse;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentDetails;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Where landlords send money to Lizmo.
 *
 * <p>The admin half sits under /api/v1/admin, which the security config closes
 * to anybody without the ADMIN role as a whole.
 */
@RestController
public class PaymentChannelController {

    private static final String ADMIN = "/api/v1/admin/platform-payment-channels";

    private final PaymentChannelService payment;
    private final CurrentUser currentUser;

    public PaymentChannelController(PaymentChannelService payment, CurrentUser currentUser) {
        this.payment = payment;
        this.currentUser = currentUser;
    }

    // ---- landlords ------------------------------------------------------------

    @GetMapping("/api/v1/me/platform-payment-details")
    @Tag(name = "Lizmo billing", description = "What a landlord owes Lizmo")
    @Operation(operationId = "getPlatformPaymentDetails", summary = "How to pay Lizmo",
            description = "The channels an admin has made visible, in order, each with its "
                    + "QR when it has one, and the note shown under them. Landlords only.")
    @ApiResponse(responseCode = "200", description = "The channels and note",
            content = @Content(schema = @Schema(implementation = PaymentDetails.class)))
    @ApiResponse(responseCode = "404", description = "Not a landlord",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentDetails details() {
        return payment.forLandlord(currentUser.requireId());
    }

    // ---- Lizmo's admins --------------------------------------------------------

    @GetMapping(ADMIN)
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "listPaymentChannels", summary = "Every payment channel",
            description = "Hidden ones included, in the order landlords see them.")
    @ApiResponse(responseCode = "200", description = "The channels",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PaymentChannelResponse.class))))
    public List<PaymentChannelResponse> list() {
        return payment.forAdmin();
    }

    @PostMapping(ADMIN)
    @ResponseStatus(HttpStatus.CREATED)
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "addPaymentChannel", summary = "Add a payment channel",
            description = "Added at the bottom, and shown to landlords unless visible is false.")
    @ApiResponse(responseCode = "201", description = "The channel",
            content = @Content(schema = @Schema(implementation = PaymentChannelResponse.class)))
    @ApiResponse(responseCode = "400", description = "Something left blank",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentChannelResponse add(@Valid @RequestBody PaymentChannelRequest request) {
        return payment.add(request, currentUser.requireId());
    }

    @PutMapping(ADMIN + "/order")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "reorderPaymentChannels", summary = "Put the channels in order",
            description = "Every channel exactly once, top to bottom.")
    @ApiResponse(responseCode = "200", description = "The channels, in their new order",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PaymentChannelResponse.class))))
    @ApiResponse(responseCode = "400", description = "A channel missing or repeated",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<PaymentChannelResponse> reorder(@Valid @RequestBody PaymentChannelOrder order) {
        return payment.reorder(order.ids(), currentUser.requireId());
    }

    @PutMapping(ADMIN + "/{id}")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "updatePaymentChannel", summary = "Change a payment channel",
            description = "Visibility is left as it is when not sent.")
    @ApiResponse(responseCode = "200", description = "The channel",
            content = @Content(schema = @Schema(implementation = PaymentChannelResponse.class)))
    @ApiResponse(responseCode = "400", description = "Something left blank",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "404", description = "No such channel",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentChannelResponse update(
            @PathVariable UUID id, @Valid @RequestBody PaymentChannelRequest request) {
        return payment.change(id, request, currentUser.requireId());
    }

    @DeleteMapping(ADMIN + "/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "deletePaymentChannel", summary = "Delete a payment channel",
            description = "With its QR. Hide it instead to bring it back later.")
    @ApiResponse(responseCode = "204", description = "Deleted")
    @ApiResponse(responseCode = "404", description = "No such channel",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public void delete(@PathVariable UUID id) {
        payment.remove(id);
    }

    @PostMapping(path = ADMIN + "/{id}/qr", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "uploadPaymentChannelQr", summary = "Set a channel's QR",
            description = "Replaces any QR it had. Re-encoded, so no EXIF or location is kept.")
    @ApiResponse(responseCode = "200", description = "The channel, with its QR",
            content = @Content(schema = @Schema(implementation = PaymentChannelResponse.class)))
    @ApiResponse(responseCode = "400", description = "Empty, too large, or not an image",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentChannelResponse uploadQr(
            @PathVariable UUID id, @RequestPart("qr") MultipartFile qr) {
        return payment.attachQr(id, qr, currentUser.requireId());
    }

    @DeleteMapping(ADMIN + "/{id}/qr")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "removePaymentChannelQr", summary = "Remove a channel's QR",
            description = "The channel stays, with its name and number.")
    @ApiResponse(responseCode = "200", description = "The channel, without a QR",
            content = @Content(schema = @Schema(implementation = PaymentChannelResponse.class)))
    public PaymentChannelResponse removeQr(@PathVariable UUID id) {
        return payment.removeQr(id, currentUser.requireId());
    }
}
