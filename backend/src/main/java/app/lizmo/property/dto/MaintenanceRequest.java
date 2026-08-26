package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

/**
 * Takes a bed or a unit out of service, or puts it back.
 *
 * <p>A flag rather than a status: the only transitions a landlord may make by
 * hand are VACANT to MAINTENANCE and back. Occupancy belongs to a lease, and
 * letting a client post it would let a space be filled without a tenant.
 *
 * <p>Shared by both endpoints because it is one idea, not two that happen to
 * look alike.
 */
@Schema(description = "Whether a bed or unit is out of service")
public record MaintenanceRequest(
        @NotNull
        @Schema(example = "true") Boolean underMaintenance) {
}
