package app.lizmo.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Either email or phone must be supplied — enforced in the service, since bean
 * validation cannot express "one of these two" cleanly.
 */
@Schema(description = "New account details")
public record RegisterRequest(
        @NotBlank @Size(max = 255)
        @Schema(example = "Ana Reyes") String name,

        @Email @Size(max = 255)
        @Schema(example = "ana@example.com", description = "Required unless phone is given") String email,

        @Size(max = 20)
        @Schema(example = "09171234567", description = "Required unless email is given") String phone,

        @NotBlank @Size(min = 8, max = 100)
        @Schema(example = "correct-horse-battery", minLength = 8) String password,

        @Schema(description = "Create a landlord profile as well as a tenant one", defaultValue = "false")
        boolean asLandlord) {
}
