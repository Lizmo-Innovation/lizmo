package app.lizmo.admin.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.UUID;

/**
 * One of a landlord's properties, on their page in the console.
 *
 * <p>Each carries its own status because each carries its own invoice. This is
 * where an admin locks and unlocks, so the thing being acted on and the thing
 * being billed are the same object on screen.
 */
@Schema(description = "A property, as the console lists them")
public record AdminPropertySummary(
        UUID id,
        String name,
        String address,
        String code,
        String accountStatus,
        int units,
        int occupiedUnits,
        int beds,
        int occupiedBeds) {
}
