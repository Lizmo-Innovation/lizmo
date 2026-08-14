package app.lizmo.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import java.util.UUID;

/**
 * @param profiles which profile records exist for this user, e.g. ["TENANT",
 *                 "LANDLORD"]. The app shell uses this to decide whether to
 *                 offer role switching. Staff assignments are deliberately
 *                 absent — they are per-property and change too often to sit
 *                 in a token.
 */
@Schema(description = "Issued tokens and the identity they belong to")
public record AuthResponse(
        @Schema(description = "Short-lived bearer token") String accessToken,
        @Schema(description = "Long-lived token, exchanged for new access tokens") String refreshToken,
        @Schema(example = "3600", description = "Access token lifetime in seconds") long expiresIn,
        UUID userId,
        String name,
        @Schema(example = "[\"TENANT\"]") List<String> profiles) {
}
