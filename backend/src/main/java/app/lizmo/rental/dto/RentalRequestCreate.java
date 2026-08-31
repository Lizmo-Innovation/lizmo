package app.lizmo.rental.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * What a tenant is asking for.
 *
 * <p>The unit is always named. The bed is named only when the unit is let bed
 * by bed — leaving it out is how a tenant asks for the whole place.
 */
@Schema(description = "A request for a bed or a whole unit")
public record RentalRequestCreate(
        @NotNull UUID unitId,
        @Schema(description = "Omit to ask for the whole unit") UUID bedId) {
}
