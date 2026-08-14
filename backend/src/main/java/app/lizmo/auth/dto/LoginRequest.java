package app.lizmo.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Login credentials")
public record LoginRequest(
        @NotBlank
        @Schema(example = "ana@example.com", description = "Email address or phone number") String identifier,

        @NotBlank
        @Schema(example = "correct-horse-battery") String password) {
}
