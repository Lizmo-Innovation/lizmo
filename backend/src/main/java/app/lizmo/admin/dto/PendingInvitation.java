package app.lizmo.admin.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

/**
 * An invitation that has been sent and not yet taken up.
 *
 * <p>Never the token. It exists in one inbox; putting it in an API response
 * would make the console a second place to steal a landlord account from.
 */
@Schema(description = "An invitation still waiting to be accepted")
public record PendingInvitation(
        UUID id,
        String email,
        Instant sentAt,
        Instant expiresAt,
        boolean expired) {
}
