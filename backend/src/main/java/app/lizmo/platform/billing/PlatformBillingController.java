package app.lizmo.platform.billing;

import app.lizmo.common.ApiError;
import app.lizmo.platform.PlatformSettingsService;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PaymentInstructions;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformInvoiceResponse;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentForAdmin;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentRejection;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentRequest;
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
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * What a landlord owes Lizmo, paying it, and Lizmo's admins checking it.
 *
 * <p>The admin half sits under /api/v1/admin, which the security config closes
 * to anybody without the ADMIN role as a whole.
 */
@RestController
public class PlatformBillingController {

    private final PlatformBillingService billing;
    private final PlatformSettingsService settings;
    private final CurrentUser currentUser;

    public PlatformBillingController(
            PlatformBillingService billing,
            PlatformSettingsService settings,
            CurrentUser currentUser) {
        this.billing = billing;
        this.settings = settings;
        this.currentUser = currentUser;
    }

    // ---- the landlord --------------------------------------------------------

    @GetMapping("/api/v1/me/platform-invoices")
    @Tag(name = "Lizmo billing", description = "What a landlord owes Lizmo")
    @Operation(operationId = "listMyPlatformInvoices", summary = "My Lizmo invoices",
            description = "One per property per month, newest first, with what has been "
                    + "sent against each.")
    @ApiResponse(responseCode = "200", description = "The invoices",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PlatformInvoiceResponse.class))))
    public List<PlatformInvoiceResponse> mine() {
        return billing.forLandlord(currentUser.requireId());
    }

    @PostMapping(path = "/api/v1/me/platform-invoices/{id}/payments",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Tag(name = "Lizmo billing", description = "What a landlord owes Lizmo")
    @Operation(operationId = "payPlatformInvoice", summary = "Say I have paid Lizmo",
            description = "Waits for a Lizmo admin to confirm it. Proof is required. The "
                    + "photograph is re-encoded, so no EXIF or location leaves the phone.")
    @ApiResponse(responseCode = "201", description = "The invoice, with the payment",
            content = @Content(schema = @Schema(implementation = PlatformInvoiceResponse.class)))
    @ApiResponse(responseCode = "400", description = "No proof, no amount, or already paid",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "404", description = "Not your invoice",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PlatformInvoiceResponse pay(
            @PathVariable UUID id,
            @Valid @RequestPart("payment") PlatformPaymentRequest request,
            @RequestPart(value = "proof", required = false) MultipartFile proof) {
        return billing.pay(id, currentUser.requireId(), request, proof);
    }

    @GetMapping("/api/v1/me/platform-payment-instructions")
    @Tag(name = "Lizmo billing", description = "What a landlord owes Lizmo")
    @Operation(operationId = "getPlatformPaymentInstructions", summary = "How to pay Lizmo",
            description = "As an admin wrote it in the console. Empty until one has.")
    @ApiResponse(responseCode = "200", description = "The instructions",
            content = @Content(schema = @Schema(implementation = PaymentInstructions.class)))
    public PaymentInstructions instructions() {
        return new PaymentInstructions(settings.paymentInstructions());
    }

    // ---- Lizmo's admins --------------------------------------------------------

    @GetMapping("/api/v1/admin/platform-payments")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "listPlatformPaymentsToReview", summary = "Payments waiting to be checked",
            description = "Across every landlord, oldest first.")
    @ApiResponse(responseCode = "200", description = "The queue",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PlatformPaymentForAdmin.class))))
    public List<PlatformPaymentForAdmin> queue() {
        return billing.queue();
    }

    @PostMapping("/api/v1/admin/platform-payments/{id}/confirm")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "confirmPlatformPayment", summary = "The money arrived",
            description = "Credits the invoice. Paying it in full lifts the lock it caused.")
    @ApiResponse(responseCode = "200", description = "The payment",
            content = @Content(schema = @Schema(implementation = PlatformPaymentForAdmin.class)))
    public PlatformPaymentForAdmin confirm(@PathVariable UUID id) {
        return billing.confirm(id, currentUser.requireId());
    }

    @PostMapping("/api/v1/admin/platform-payments/{id}/reject")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "rejectPlatformPayment", summary = "It did not arrive",
            description = "The landlord is told, with the reason.")
    @ApiResponse(responseCode = "200", description = "The payment",
            content = @Content(schema = @Schema(implementation = PlatformPaymentForAdmin.class)))
    public PlatformPaymentForAdmin reject(
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) PlatformPaymentRejection reason) {
        return billing.reject(id, currentUser.requireId(), reason == null ? null : reason.remarks());
    }

    @GetMapping("/api/v1/admin/landlords/{id}/invoices")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "listLandlordInvoices", summary = "One landlord's invoices")
    @ApiResponse(responseCode = "200", description = "The invoices",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PlatformInvoiceResponse.class))))
    public List<PlatformInvoiceResponse> landlordInvoices(@PathVariable UUID id) {
        return billing.forLandlord(id);
    }
}
