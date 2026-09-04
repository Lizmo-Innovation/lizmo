package app.lizmo.auth.invitation.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

/**
 * @param hasAccount whether this address already signs in to Lizmo. It decides
 *                   the whole of the accept screen: somebody new is choosing a
 *                   password, somebody who already rents through Lizmo is
 *                   confirming the one they have.
 */
@Schema(description = "What an invitation is for")
public record InvitationDetailsResponse(
        String email, boolean hasAccount, Instant expiresAt) {
}
