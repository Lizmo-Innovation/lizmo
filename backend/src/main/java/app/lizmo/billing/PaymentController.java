package app.lizmo.billing;

import app.lizmo.billing.dto.PaymentResponse;
import app.lizmo.billing.dto.RecordPaymentRequest;
import app.lizmo.common.ApiError;
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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Recording rent that has been paid.
 *
 * <p>Both sides can write one; who wrote it decides whether it counts at once.
 * A landlord recording money they received has nobody to disagree with. A
 * tenant saying they paid is making a claim, and it waits.
 */
@RestController
@Tag(name = "Rent", description = "What is owed, and what has come in")
public class PaymentController {

    private final PaymentService payments;
    private final CurrentUser currentUser;

    public PaymentController(PaymentService payments, CurrentUser currentUser) {
        this.payments = payments;
        this.currentUser = currentUser;
    }

    // ---- the landlord ------------------------------------------------------

    @GetMapping("/api/v1/leases/{leaseId}/payments")
    @Operation(operationId = "listLeasePayments", summary = "Payments on this tenancy",
            description = "Newest first, whatever their state. A rejected payment stays "
                    + "in the list: the disagreement is worth keeping.")
    @ApiResponse(responseCode = "200", description = "The payments",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PaymentResponse.class))))
    public List<PaymentResponse> forLandlord(@PathVariable UUID leaseId) {
        return payments.forLandlord(leaseId, currentUser.requireId());
    }

    @PostMapping("/api/v1/leases/{leaseId}/payments")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "recordPayment", summary = "Record money I received",
            description = "Confirmed immediately: the landlord received it, so there is "
                    + "nobody for them to disagree with. The month's balance moves at "
                    + "once and the tenant is told.")
    @ApiResponse(responseCode = "201", description = "The recorded payment",
            content = @Content(schema = @Schema(implementation = PaymentResponse.class)))
    @ApiResponse(responseCode = "404", description = "Not your lease, or no such month",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentResponse record(
            @PathVariable UUID leaseId,
            @Valid @RequestBody RecordPaymentRequest request) {
        return payments.recordByLandlord(leaseId, currentUser.requireId(), request);
    }

    @PostMapping("/api/v1/leases/{leaseId}/payments/{paymentId}/confirm")
    @Operation(operationId = "confirmPayment", summary = "Agree the money arrived",
            description = "The only thing that moves a balance for a payment a tenant "
                    + "declared. Answering twice is refused, which is the one way this "
                    + "could quietly invent money.")
    @ApiResponse(responseCode = "200", description = "The confirmed payment",
            content = @Content(schema = @Schema(implementation = PaymentResponse.class)))
    @ApiResponse(responseCode = "400", description = "Already answered",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentResponse confirm(
            @PathVariable UUID leaseId, @PathVariable UUID paymentId) {
        return payments.confirm(leaseId, paymentId, currentUser.requireId());
    }

    @PostMapping("/api/v1/leases/{leaseId}/payments/{paymentId}/reject")
    @Operation(operationId = "rejectPayment", summary = "Say it did not arrive",
            description = "Rejected rather than deleted: a tenant who wrote something "
                    + "down and found it gone would not know whether it was refused or "
                    + "lost. Nothing is credited.")
    @ApiResponse(responseCode = "200", description = "The rejected payment",
            content = @Content(schema = @Schema(implementation = PaymentResponse.class)))
    public PaymentResponse reject(
            @PathVariable UUID leaseId,
            @PathVariable UUID paymentId,
            @RequestParam(required = false) String remarks) {
        return payments.reject(leaseId, paymentId, currentUser.requireId(), remarks);
    }

    // ---- the tenant --------------------------------------------------------

    @GetMapping("/api/v1/me/leases/{leaseId}/payments")
    @Operation(operationId = "listMyPayments", summary = "What I have paid",
            description = "Including anything still waiting to be confirmed, and "
                    + "anything the landlord refused.")
    @ApiResponse(responseCode = "200", description = "The payments",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PaymentResponse.class))))
    public List<PaymentResponse> forTenant(@PathVariable UUID leaseId) {
        return payments.forTenant(leaseId, currentUser.requireId());
    }

    @PostMapping(path = "/api/v1/me/leases/{leaseId}/payments",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "declarePayment", summary = "Say I have paid",
            description = "Waits for the landlord to confirm; nothing about the balance "
                    + "moves until they do. A screenshot is optional -- cash is real, "
                    + "and a required field nobody can satisfy becomes one people lie "
                    + "in. Any photograph is re-encoded, so no EXIF or location leaves "
                    + "the phone.")
    @ApiResponse(responseCode = "201", description = "The declared payment",
            content = @Content(schema = @Schema(implementation = PaymentResponse.class)))
    @ApiResponse(responseCode = "404", description = "Not your lease, or no such month",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PaymentResponse declare(
            @PathVariable UUID leaseId,
            @Valid @RequestPart("payment") RecordPaymentRequest request,
            @RequestPart(value = "proof", required = false) MultipartFile proof) {
        return payments.declareByTenant(
                leaseId, currentUser.requireId(), request, proof);
    }
}
