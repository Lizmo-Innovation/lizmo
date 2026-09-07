package app.lizmo.billing;

import app.lizmo.billing.dto.BillingPeriodResponse;
import app.lizmo.common.ApiError;
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
 * Rent, month by month.
 *
 * <p>Two paths for the two audiences rather than one endpoint that decides who
 * is asking. Reading them apart is what keeps a landlord's list of tenancies
 * and a tenant's own rent from ever being served by the same permission check.
 */
@RestController
@Tag(name = "Rent", description = "What is owed, and what has come in")
public class BillingController {

    private final BillingService billing;
    private final CurrentUser currentUser;

    public BillingController(BillingService billing, CurrentUser currentUser) {
        this.billing = billing;
        this.currentUser = currentUser;
    }

    @GetMapping("/api/v1/leases/{leaseId}/billing")
    @Operation(operationId = "listLeaseBilling", summary = "Rent on this tenancy",
            description = "Oldest month first. Months are created as they begin, so "
                    + "opening this is what brings the schedule up to date.")
    @ApiResponse(responseCode = "200", description = "The months",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = BillingPeriodResponse.class))))
    @ApiResponse(responseCode = "404", description = "Not your lease",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<BillingPeriodResponse> forLandlord(@PathVariable UUID leaseId) {
        return billing.forLandlord(leaseId, currentUser.requireId());
    }

    @GetMapping("/api/v1/me/leases/{leaseId}/billing")
    @Operation(operationId = "listMyBilling", summary = "My rent",
            description = "The same months the landlord sees. Readable after the "
                    + "tenancy ends: what you paid is worth having afterwards.")
    @ApiResponse(responseCode = "200", description = "The months",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = BillingPeriodResponse.class))))
    @ApiResponse(responseCode = "404", description = "Not your lease",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<BillingPeriodResponse> forTenant(@PathVariable UUID leaseId) {
        return billing.forTenant(leaseId, currentUser.requireId());
    }
}
