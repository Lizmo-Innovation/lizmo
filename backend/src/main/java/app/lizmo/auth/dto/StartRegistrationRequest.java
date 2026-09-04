package app.lizmo.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** The address somebody wants to prove they own. */
@Schema(description = "Where to send a verification code")
public record StartRegistrationRequest(
        @NotBlank @Email @Size(max = 255)
        @Schema(example = "ana@example.com") String email) {

    /**
     * Trimmed on the way in, before validation sees it.
     *
     * <p>A pasted address arrives with a trailing space more often than not,
     * and "not a valid email" for something that plainly is would be the app's
     * fault rather than the reader's.
     */
    public StartRegistrationRequest {
        email = email == null ? null : email.trim();
    }
}
