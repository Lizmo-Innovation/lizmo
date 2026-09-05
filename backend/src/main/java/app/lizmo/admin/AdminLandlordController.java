package app.lizmo.admin;

import app.lizmo.admin.dto.AdminPropertySummary;
import app.lizmo.admin.dto.LandlordDetail;
import app.lizmo.admin.dto.LandlordSummary;
import app.lizmo.admin.dto.PendingInvitation;
import app.lizmo.auth.invitation.LandlordInvitationService;
import app.lizmo.common.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * What the console reads and does.
 *
 * <p>Behind /api/v1/admin, which the security config restricts to the ADMIN
 * authority as a whole — so a route added here cannot be left open by
 * forgetting an annotation on it.
 */
@RestController
@RequestMapping("/api/v1/admin")
@Tag(name = "Admin", description = "Lizmo's own staff")
public class AdminLandlordController {

    private final AdminLandlordService landlords;
    private final LandlordInvitationService invitations;

    public AdminLandlordController(
            AdminLandlordService landlords, LandlordInvitationService invitations) {
        this.landlords = landlords;
        this.invitations = invitations;
    }

    @GetMapping("/landlords")
    @Operation(operationId = "listLandlords", summary = "Every landlord",
            description = "With their property count, how many are locked, and how many "
                    + "slots are occupied. Counts only — no tenant is named.")
    @ApiResponse(responseCode = "200", description = "The landlords")
    @ApiResponse(responseCode = "403", description = "Not a Lizmo administrator",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<LandlordSummary> all() {
        return landlords.all();
    }

    @GetMapping("/landlords/{id}")
    @Operation(operationId = "getLandlord", summary = "One landlord and their properties",
            description = "Each property carries its own status, because each carries "
                    + "its own invoice.")
    @ApiResponse(responseCode = "200", description = "The landlord")
    @ApiResponse(responseCode = "404", description = "No such landlord",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public LandlordDetail one(@PathVariable UUID id) {
        return landlords.one(id);
    }

    @PostMapping("/properties/{id}/lock")
    @Operation(operationId = "lockProperty", summary = "Stop a property being added to",
            description = "Blocks new units, new beds and accepting requests. Never "
                    + "affects the tenants already living there, and never stops the "
                    + "landlord ending a lease or declining a request.")
    @ApiResponse(responseCode = "200", description = "Locked")
    public AdminPropertySummary lock(@PathVariable UUID id) {
        return landlords.lock(id);
    }

    @PostMapping("/properties/{id}/unlock")
    @Operation(operationId = "unlockProperty", summary = "Let a property be managed again")
    @ApiResponse(responseCode = "200", description = "Unlocked")
    public AdminPropertySummary unlock(@PathVariable UUID id) {
        return landlords.unlock(id);
    }

    @GetMapping("/landlord-invitations")
    @Operation(operationId = "listInvitations", summary = "Invitations not yet taken up",
            description = "Expired ones included: somebody has to notice that a landlord "
                    + "never signed up. Never includes the token.")
    @ApiResponse(responseCode = "200", description = "The invitations")
    public List<PendingInvitation> invitations() {
        return invitations.pending();
    }

    @DeleteMapping("/landlord-invitations/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "revokeInvitation", summary = "Withdraw an invitation",
            description = "For a wrong address, or somebody who should not have been "
                    + "invited. The link stops working immediately.")
    @ApiResponse(responseCode = "204", description = "Withdrawn")
    @ApiResponse(responseCode = "400", description = "Already used or withdrawn",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public void revoke(@PathVariable UUID id) {
        invitations.revoke(id);
    }
}
