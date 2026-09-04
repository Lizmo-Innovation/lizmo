package app.lizmo.auth.invitation.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

/**
 * What the admin gets back. Not the token: the whole point is that it exists
 * only in the invitee's inbox, and putting it in an API response would make
 * the console a second place to steal it from.
 */
@Schema(description = "An invitation on its way")
public record InvitationSentResponse(String email, Instant expiresAt) {
}
