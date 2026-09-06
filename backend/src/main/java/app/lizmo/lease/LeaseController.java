package app.lizmo.lease;

import app.lizmo.common.ApiError;
import app.lizmo.lease.dto.EndLeaseRequest;
import app.lizmo.lease.dto.LeaseResponse;
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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Leases, from both sides.
 *
 * <p>A tenant reads their own; a landlord reads their property's and is the
 * only one who can end one.
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "Leases", description = "Who is living where")
public class LeaseController {

    private final LeaseService leases;
    private final CurrentUser currentUser;

    public LeaseController(LeaseService leases, CurrentUser currentUser) {
        this.leases = leases;
        this.currentUser = currentUser;
    }

    @GetMapping("/me/leases")
    @Operation(operationId = "listMyLeases", summary = "My leases")
    @ApiResponse(responseCode = "200", description = "Newest first",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = LeaseResponse.class))))
    public List<LeaseResponse> mine() {
        return leases.mine(currentUser.requireId());
    }

    @GetMapping("/me/tenants")
    @Operation(operationId = "listMyTenants",
            summary = "Everyone renting from me",
            description = "Active leases across every property this landlord owns, so "
                    + "the tenant list is one request rather than one per property.")
    @ApiResponse(responseCode = "200", description = "The active leases",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = LeaseResponse.class))))
    public List<LeaseResponse> myTenants() {
        return leases.forLandlord(currentUser.requireId());
    }

    @GetMapping("/properties/{propertyId}/leases")
    @Operation(operationId = "listLeasesForProperty", summary = "Who is living here")
    @ApiResponse(responseCode = "200", description = "The active leases",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = LeaseResponse.class))))
    @ApiResponse(responseCode = "404", description = "Not your property",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<LeaseResponse> forProperty(@PathVariable UUID propertyId) {
        return leases.forProperty(propertyId, currentUser.requireId());
    }

    @PostMapping("/leases/{id}/end")
    @Operation(operationId = "endLease", summary = "End a tenancy",
            description = "Frees the bed or unit back to the vacancy list. "
                    + "Defaults to ended today; pass terminated for a tenancy "
                    + "stopped early.")
    @ApiResponse(responseCode = "200", description = "The ended lease",
            content = @Content(schema = @Schema(implementation = LeaseResponse.class)))
    public LeaseResponse end(
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) EndLeaseRequest command) {
        return leases.end(id, currentUser.requireId(), command);
    }
}
