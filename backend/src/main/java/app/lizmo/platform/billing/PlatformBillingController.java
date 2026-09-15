package app.lizmo.platform.billing;

import app.lizmo.common.ApiError;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentForAdmin;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentRejection;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentRequest;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformStatementResponse;
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
 * <p>A landlord is billed by the month, not by the building: one statement
 * covering every property, which is what they pay. The per-property invoices
 * are the statement's lines, and are only numbered once it is settled.
 *
 * <p>The admin half sits under /api/v1/admin, which the security config closes
 * to anybody without the ADMIN role as a whole.
 */
@RestController
public class PlatformBillingController {

    private final PlatformBillingService billing;
    private final CurrentUser currentUser;

    public PlatformBillingController(PlatformBillingService billing, CurrentUser currentUser) {
        this.billing = billing;
        this.currentUser = currentUser;
    }

    // ---- the landlord --------------------------------------------------------

    @GetMapping("/api/v1/me/platform-statements")
    @Tag(name = "Lizmo billing", description = "What a landlord owes Lizmo")
    @Operation(operationId = "listMyPlatformStatements", summary = "My Lizmo statements",
            description = "One a month, newest first, itemised by property, with what has "
                    + "been sent against each. A line carries an invoice number once the "
                    + "statement is paid.")
    @ApiResponse(responseCode = "200", description = "The statements",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PlatformStatementResponse.class))))
    public List<PlatformStatementResponse> mine() {
        return billing.forLandlord(currentUser.requireId());
    }

    @PostMapping(path = "/api/v1/me/platform-statements/{id}/payments",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Tag(name = "Lizmo billing", description = "What a landlord owes Lizmo")
    @Operation(operationId = "payPlatformStatement", summary = "Say I have paid Lizmo",
            description = "Waits for a Lizmo admin to confirm it. Proof is required. The "
                    + "photograph is re-encoded, so no EXIF or location leaves the phone.")
    @ApiResponse(responseCode = "201", description = "The statement, with the payment",
            content = @Content(schema = @Schema(implementation = PlatformStatementResponse.class)))
    @ApiResponse(responseCode = "400", description = "No proof, no amount, or already paid",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "404", description = "Not your statement",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PlatformStatementResponse pay(
            @PathVariable UUID id,
            @Valid @RequestPart("payment") PlatformPaymentRequest request,
            @RequestPart(value = "proof", required = false) MultipartFile proof) {
        return billing.pay(id, currentUser.requireId(), request, proof);
    }

    // ---- Lizmo's admins --------------------------------------------------------

    @GetMapping("/api/v1/admin/platform-payments")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "listPlatformPaymentsToReview",
            summary = "Payments waiting to be checked",
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
            description = "Credits the statement. Settling it in full issues an invoice for "
                    + "each property and lifts the locks it caused.")
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
        return billing.reject(
                id, currentUser.requireId(), reason == null ? null : reason.remarks());
    }

    @GetMapping("/api/v1/admin/landlords/{id}/statements")
    @Tag(name = "Admin", description = "Lizmo's own staff")
    @Operation(operationId = "listLandlordStatements", summary = "One landlord's statements")
    @ApiResponse(responseCode = "200", description = "The statements",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PlatformStatementResponse.class))))
    public List<PlatformStatementResponse> landlordStatements(@PathVariable UUID id) {
        return billing.forLandlord(id);
    }
}
