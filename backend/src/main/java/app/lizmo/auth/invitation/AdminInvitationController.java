package app.lizmo.auth.invitation;

import app.lizmo.auth.invitation.dto.InvitationSentResponse;
import app.lizmo.auth.invitation.dto.InviteLandlordRequest;
import app.lizmo.common.ApiError;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Instant;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Lizmo staff, inviting landlords.
 *
 * <p>Behind /api/v1/admin, which the security config restricts to the ADMIN
 * authority as a whole — so a route added here later cannot be left open by
 * forgetting an annotation on it.
 *
 * <p>There is no endpoint that makes somebody an admin, and there is not going
 * to be: that row is inserted into the database by hand, so a compromised API
 * cannot mint itself an administrator.
 */
@RestController
@RequestMapping("/api/v1/admin/landlord-invitations")
@Tag(name = "Admin", description = "Lizmo's own staff")
public class AdminInvitationController {

    private final LandlordInvitationService invitations;
    private final CurrentUser currentUser;

    public AdminInvitationController(
            LandlordInvitationService invitations, CurrentUser currentUser) {
        this.invitations = invitations;
        this.currentUser = currentUser;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "inviteLandlord", summary = "Invite a landlord",
            description = "Emails a link that lets somebody set up a landlord account. "
                    + "Good for seven days and one use; inviting the same address "
                    + "again replaces the earlier link.")
    @ApiResponse(responseCode = "201", description = "The invitation is on its way",
            content = @Content(schema = @Schema(implementation = InvitationSentResponse.class)))
    @ApiResponse(responseCode = "403", description = "Not a Lizmo administrator",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "409", description = "That address is already a landlord",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public InvitationSentResponse invite(@Valid @RequestBody InviteLandlordRequest request) {
        Instant expiresAt = invitations.invite(
                request.email(), request.name(), currentUser.requireId());
        return new InvitationSentResponse(request.email().trim().toLowerCase(), expiresAt);
    }
}
