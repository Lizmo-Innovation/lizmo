package app.lizmo.billing.channel;

import app.lizmo.common.ApiError;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelOrder;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelRequest;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelResponse;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentDetails;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentNote;
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
 * Where a tenant sends rent: kept by the landlord, read by their tenants.
 *
 * <p>Everything under /me/payment-channels is the caller's own list, and reads
 * as not found for anybody who is not a landlord.
 */
@RestController
public class LandlordPaymentChannelController {

    private static final String MINE = "/api/v1/me/payment-channels";

    private final LandlordPaymentChannelService payment;
    private final CurrentUser currentUser;

    public LandlordPaymentChannelController(
            LandlordPaymentChannelService payment, CurrentUser currentUser) {
        this.payment = payment;
        this.currentUser = currentUser;
    }

    // ---- a tenant paying ----------------------------------------------------------------

    @GetMapping("/api/v1/me/leases/{leaseId}/payment-details")
    @Tag(name = "Rent", description = "What is owed, and what has come in")
    @Operation(operationId = "getLeasePaymentDetails", summary = "How to pay my landlord",
            description = "The channels the landlord behind this lease has switched on, in "
                    + "order, each with its QR when it has one, and their note. Also after "
                    + "moving out.")
    @ApiResponse(responseCode = "200", description = "The channels and note",
            content = @Content(schema = @Schema(implementation = PaymentDetails.class)))
    @ApiResponse(responseCode = "404", description = "Not your lease",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentDetails forTenant(@PathVariable UUID leaseId) {
        return payment.forTenant(leaseId, currentUser.requireId());
    }

    // ---- the landlord's own list ---------------------------------------------------------

    @GetMapping(MINE)
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "listMyPaymentChannels", summary = "How my tenants pay me",
            description = "Hidden ones included, in the order tenants see them.")
    @ApiResponse(responseCode = "200", description = "The channels",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PaymentChannelResponse.class))))
    @ApiResponse(responseCode = "404", description = "Not a landlord",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<PaymentChannelResponse> mine() {
        return payment.mine(currentUser.requireId());
    }

    @PostMapping(MINE)
    @ResponseStatus(HttpStatus.CREATED)
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "addMyPaymentChannel", summary = "Add a way to pay me",
            description = "Added at the bottom, and shown to tenants unless visible is false.")
    @ApiResponse(responseCode = "201", description = "The channel",
            content = @Content(schema = @Schema(implementation = PaymentChannelResponse.class)))
    @ApiResponse(responseCode = "400", description = "Something left blank",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentChannelResponse add(@Valid @RequestBody PaymentChannelRequest request) {
        return payment.add(currentUser.requireId(), request);
    }

    @PutMapping(MINE + "/order")
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "reorderMyPaymentChannels", summary = "Put my channels in order",
            description = "Every channel exactly once, top to bottom.")
    @ApiResponse(responseCode = "200", description = "The channels, in their new order",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PaymentChannelResponse.class))))
    @ApiResponse(responseCode = "400", description = "A channel missing or repeated",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<PaymentChannelResponse> reorder(@Valid @RequestBody PaymentChannelOrder order) {
        return payment.reorder(currentUser.requireId(), order.ids());
    }

    @PutMapping(MINE + "/{id}")
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "updateMyPaymentChannel", summary = "Change a way to pay me",
            description = "Visibility is left as it is when not sent. Past payments keep "
                    + "the details they were sent to.")
    @ApiResponse(responseCode = "200", description = "The channel",
            content = @Content(schema = @Schema(implementation = PaymentChannelResponse.class)))
    @ApiResponse(responseCode = "404", description = "Not your channel",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentChannelResponse update(
            @PathVariable UUID id, @Valid @RequestBody PaymentChannelRequest request) {
        return payment.change(currentUser.requireId(), id, request);
    }

    @DeleteMapping(MINE + "/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "deleteMyPaymentChannel", summary = "Delete a way to pay me",
            description = "With its QR. Hide it instead to bring it back later.")
    @ApiResponse(responseCode = "204", description = "Deleted")
    @ApiResponse(responseCode = "404", description = "Not your channel",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public void delete(@PathVariable UUID id) {
        payment.remove(currentUser.requireId(), id);
    }

    @PostMapping(path = MINE + "/{id}/qr", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "uploadMyPaymentChannelQr", summary = "Set a channel's QR",
            description = "Replaces any QR it had. Re-encoded, so no EXIF or location is kept.")
    @ApiResponse(responseCode = "200", description = "The channel, with its QR",
            content = @Content(schema = @Schema(implementation = PaymentChannelResponse.class)))
    @ApiResponse(responseCode = "400", description = "Empty, too large, or not an image",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentChannelResponse uploadQr(
            @PathVariable UUID id, @RequestPart("qr") MultipartFile qr) {
        return payment.attachQr(currentUser.requireId(), id, qr);
    }

    @DeleteMapping(MINE + "/{id}/qr")
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "removeMyPaymentChannelQr", summary = "Remove a channel's QR",
            description = "The channel stays, with its name and number.")
    @ApiResponse(responseCode = "200", description = "The channel, without a QR",
            content = @Content(schema = @Schema(implementation = PaymentChannelResponse.class)))
    public PaymentChannelResponse removeQr(@PathVariable UUID id) {
        return payment.removeQr(currentUser.requireId(), id);
    }

    @GetMapping("/api/v1/me/payment-note")
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "getMyPaymentNote", summary = "The note under my channels")
    @ApiResponse(responseCode = "200", description = "The note",
            content = @Content(schema = @Schema(implementation = PaymentNote.class)))
    public PaymentNote note() {
        return payment.note(currentUser.requireId());
    }

    @PutMapping("/api/v1/me/payment-note")
    @Tag(name = "Payment channels", description = "How a landlord's tenants pay them")
    @Operation(operationId = "updateMyPaymentNote", summary = "Change the note under my channels",
            description = "Blank clears it.")
    @ApiResponse(responseCode = "200", description = "The note",
            content = @Content(schema = @Schema(implementation = PaymentNote.class)))
    public PaymentNote changeNote(@Valid @RequestBody PaymentNote note) {
        return payment.changeNote(currentUser.requireId(), note.note());
    }
}
