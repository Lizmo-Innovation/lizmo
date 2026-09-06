package app.lizmo.lease;

import app.lizmo.common.ApiError;
import app.lizmo.lease.dto.TenantForLandlord;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * A landlord reading the details of whoever lives in their room.
 *
 * <p>Sits beside the photographs endpoint rather than inside it: same rule,
 * same lifetime, different half of the same disclosure. Both are addressed by
 * lease, so a tenant id opens nothing.
 */
@RestController
@RequestMapping("/api/v1/leases")
@Tag(name = "Leases", description = "Who is living where")
public class LeaseTenantController {

    private final TenantDetailsService tenants;
    private final CurrentUser currentUser;

    public LeaseTenantController(
            TenantDetailsService tenants, CurrentUser currentUser) {
        this.tenants = tenants;
        this.currentUser = currentUser;
    }

    @GetMapping("/{leaseId}/tenant")
    @Operation(operationId = "getTenantForLease", summary = "Who is living here",
            description = "The written half of what unlocks on acceptance: the "
                    + "emergency contact and the ID number, both of which a pending "
                    + "request deliberately withholds. Only while the lease is active.")
    @ApiResponse(responseCode = "200", description = "The tenant",
            content = @Content(schema = @Schema(implementation = TenantForLandlord.class)))
    @ApiResponse(responseCode = "404",
            description = "Not your lease, or the tenancy has ended",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public TenantForLandlord tenant(@PathVariable UUID leaseId) {
        return tenants.forLease(leaseId, currentUser.requireId());
    }
}
