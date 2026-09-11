package app.lizmo.maintenance.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * A tenant describing what is broken.
 *
 * <p>No category and no priority, as the spec has it. Nobody reporting a leak
 * wants to be asked which of eight kinds of leak it is.
 */
@Schema(description = "Reporting something broken")
public record ReportProblemRequest(
        @NotBlank
        @Size(max = 2000)
        @Schema(example = "The tap in the shared bathroom will not stop dripping.")
        String description) {
}
