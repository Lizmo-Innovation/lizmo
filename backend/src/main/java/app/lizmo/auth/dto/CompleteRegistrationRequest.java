package app.lizmo.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Everything needed to turn a verified address into an account.
 *
 * <p>The name is collected here rather than at the start: the address arrives
 * first, and asking for a name before somebody has even proved they can read
 * their email is a field they may never come back to fill in.
 *
 * <p>The password is deliberately unconstrained by annotations. PasswordPolicy
 * checks it, so one failure can name every rule that was missed instead of
 * bean validation reporting "size must be between..." for the first one.
 */
@Schema(description = "Finishing a sign-up")
public record CompleteRegistrationRequest(
        @NotBlank @Email @Size(max = 255)
        @Schema(example = "ana@example.com") String email,

        @NotBlank @Size(max = 10)
        @Schema(example = "483920") String code,

        @NotBlank @Size(max = 255)
        @Schema(example = "Ana Reyes") String name,

        @NotBlank @Size(max = 100)
        @Schema(example = "Sunrise2Bed!") String password) {

    public CompleteRegistrationRequest {
        email = email == null ? null : email.trim();
        code = code == null ? null : code.trim();
        name = name == null ? null : name.trim();
    }
}
