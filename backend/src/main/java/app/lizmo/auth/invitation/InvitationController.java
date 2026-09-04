package app.lizmo.auth.invitation;

import app.lizmo.auth.dto.AuthResponse;
import app.lizmo.auth.invitation.dto.AcceptInvitationRequest;
import app.lizmo.auth.invitation.dto.InvitationDetailsResponse;
import app.lizmo.common.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * The invitee's side: what the link is for, and taking it up.
 *
 * <p>Unauthenticated, because the person following the link has no account yet
 * — or has one and is not signed in on the device the email opened. The token
 * is the credential, which is why it is 256 random bits, single use, and stored
 * only as a hash.
 */
@RestController
@RequestMapping("/api/v1/auth/invitations")
@Tag(name = "Signing up", description = "Creating an account")
public class InvitationController {

    private final LandlordInvitationService invitations;

    public InvitationController(LandlordInvitationService invitations) {
        this.invitations = invitations;
    }

    @GetMapping("/{token}")
    @Operation(operationId = "getInvitation", summary = "What this invitation is for",
            description = "Says which address was invited and whether it already has a "
                    + "Lizmo account, so the screen knows whether to ask for a new "
                    + "password or the existing one.")
    @ApiResponse(responseCode = "200", description = "The invitation is good",
            content = @Content(schema = @Schema(implementation = InvitationDetailsResponse.class)))
    @ApiResponse(responseCode = "400", description = "Unknown, expired or already used",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public InvitationDetailsResponse describe(@PathVariable String token) {
        var details = invitations.describe(token);
        return new InvitationDetailsResponse(
                details.email(), details.hasAccount(), details.expiresAt());
    }

    @PostMapping("/accept")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "acceptInvitation", summary = "Become a landlord",
            description = "Spends the invitation and signs you in. A new account needs a "
                    + "name and a password of its own; an address that already signs in "
                    + "to Lizmo needs that account's password, and keeps its tenant side.")
    @ApiResponse(responseCode = "201", description = "Signed in, now a landlord",
            content = @Content(schema = @Schema(implementation = AuthResponse.class)))
    @ApiResponse(responseCode = "400",
            description = "The invitation is unusable, or the password is too weak",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "401",
            description = "The address has an account and that is not its password",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public AuthResponse accept(@Valid @RequestBody AcceptInvitationRequest request) {
        return invitations.accept(request.token(), request.name(), request.password());
    }
}
