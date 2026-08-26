package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

/**
 * Takes a bed out of service, or puts it back.
 *
 * <p>A flag rather than a status: the only transitions a landlord may make by
 * hand are VACANT to MAINTENANCE and back. OCCUPIED belongs to a lease, and
 * letting a client post it would let a bed be filled without a tenant.
 */
@Schema(description = "Whether a bed is out of service")
public record BedMaintenanceRequest(
        @NotNull
        @Schema(example = "true") Boolean underMaintenance) {
}
