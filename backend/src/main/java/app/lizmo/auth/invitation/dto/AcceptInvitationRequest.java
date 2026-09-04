package app.lizmo.auth.invitation.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * @param name     needed only when the address has no account yet. Somebody who
 *                 already signs in to Lizmo keeps the name they have.
 * @param password the one being chosen, for a new account; the existing one,
 *                 for an account that already exists. Which of the two is
 *                 decided by the address, not by the caller.
 */
@Schema(description = "Taking up a landlord invitation")
public record AcceptInvitationRequest(
        @NotBlank @Size(max = 512)
        @Schema(example = "k7Qm2...") String token,

        @Size(max = 255)
        @Schema(example = "Elena Bautista") String name,

        @NotBlank @Size(max = 100)
        @Schema(example = "Sunrise2Bed!") String password) {

    public AcceptInvitationRequest {
        token = token == null ? null : token.trim();
        name = name == null ? null : name.trim();
    }
}
