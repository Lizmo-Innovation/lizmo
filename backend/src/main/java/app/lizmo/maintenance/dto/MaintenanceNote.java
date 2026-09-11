package app.lizmo.maintenance.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;

/**
 * A line said alongside a change: a landlord's remark as they start on or fix
 * something, or a tenant's reason for saying it is still broken.
 */
@Schema(description = "Something said alongside a change")
public record MaintenanceNote(
        @Size(max = 1000)
        @Schema(example = "The plumber is coming on Saturday morning.")
        String text) {
}
