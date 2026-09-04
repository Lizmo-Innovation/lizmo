package app.lizmo.auth.invitation.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * @param name what to call them in the email. Optional: an admin taking a
 *             phone call may have an address and nothing else, and a greeting
 *             is not worth blocking an invitation over.
 */
@Schema(description = "Inviting somebody to be a landlord")
public record InviteLandlordRequest(
        @NotBlank @Email @Size(max = 255)
        @Schema(example = "elena@example.com") String email,

        @Size(max = 255)
        @Schema(example = "Elena Bautista") String name) {
}
