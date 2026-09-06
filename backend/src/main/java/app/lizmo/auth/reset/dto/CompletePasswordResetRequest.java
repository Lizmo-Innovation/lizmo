package app.lizmo.auth.reset.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * A code and the password to put behind it.
 *
 * <p>The password is unconstrained by annotations, as at sign-up: PasswordPolicy
 * checks it, so one failure names every rule that was missed rather than bean
 * validation reporting the first.
 */
@Schema(description = "Setting a new password")
public record CompletePasswordResetRequest(
        @NotBlank @Email @Size(max = 255)
        @Schema(example = "ana@example.com") String email,

        @NotBlank @Size(max = 10)
        @Schema(example = "483920") String code,

        @NotBlank @Size(max = 100)
        @Schema(example = "Sunrise2Bed!") String password) {

    public CompletePasswordResetRequest {
        email = email == null ? null : email.trim();
        code = code == null ? null : code.trim();
    }
}
