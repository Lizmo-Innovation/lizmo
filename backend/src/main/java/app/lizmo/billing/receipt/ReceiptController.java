package app.lizmo.billing.receipt;

import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * Acknowledgement receipts, for both ends of a tenancy.
 *
 * <p>Read only. A receipt is issued by confirming or recording a payment,
 * never on its own, and never changed after.
 */
@RestController
@Tag(name = "Receipts", description = "Acknowledgement receipts for confirmed payments")
public class ReceiptController {

    private final ReceiptService receipts;
    private final CurrentUser currentUser;

    public ReceiptController(ReceiptService receipts, CurrentUser currentUser) {
        this.receipts = receipts;
        this.currentUser = currentUser;
    }

    @GetMapping("/api/v1/me/leases/{leaseId}/receipts")
    @Operation(operationId = "listMyReceipts", summary = "My receipts",
            description = "One for every payment the landlord confirmed or recorded, "
                    + "newest first. Not BIR official receipts.")
    @ApiResponse(responseCode = "200", description = "The receipts",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = ReceiptResponse.class))))
    public List<ReceiptResponse> mine(@PathVariable UUID leaseId) {
        return receipts.forTenant(leaseId, currentUser.requireId());
    }

    @GetMapping("/api/v1/leases/{leaseId}/receipts")
    @Operation(operationId = "listLeaseReceipts", summary = "Receipts on this tenancy",
            description = "Everything acknowledged on it, newest first.")
    @ApiResponse(responseCode = "200", description = "The receipts",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = ReceiptResponse.class))))
    public List<ReceiptResponse> forLandlord(@PathVariable UUID leaseId) {
        return receipts.forLandlord(leaseId, currentUser.requireId());
    }
}
