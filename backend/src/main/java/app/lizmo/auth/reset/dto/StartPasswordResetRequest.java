package app.lizmo.auth.reset.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** The address to send a reset code to, whether or not it has an account. */
@Schema(description = "Asking for a password reset code")
public record StartPasswordResetRequest(
        @NotBlank @Email @Size(max = 255)
        @Schema(example = "ana@example.com") String email) {

    public StartPasswordResetRequest {
        email = email == null ? null : email.trim();
    }
}
