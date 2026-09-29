package app.lizmo.rental.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.UUID;

/**
 * What a tenant is asking for.
 *
 * <p>Either a property — which is what scanning a code leads to, since the
 * rooms themselves are not shown to a stranger — or one named unit, and within
 * it one named bed when the unit is let bed by bed.
 *
 * <p>Both shapes are live. A request that names a room is answered as it
 * always was; one that names only a property has its room chosen by the
 * landlord when they accept.
 */
@Schema(description = "A request about a property, or for one room in it")
public record RentalRequestCreate(
        @Schema(description = "The property asked about. Omit when naming a unit")
        UUID propertyId,
        @Schema(description = "Omit to ask about the property as a whole")
        UUID unitId,
        @Schema(description = "Omit to ask for the whole unit") UUID bedId) {
}
