package app.lizmo.property.dto;

import app.lizmo.property.Bed;
import app.lizmo.property.BedStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * @param rent this bed's own asking rent, or null when it is let at the unit's
 *             rate. Null is not free — read the unit's rent instead.
 */
@Schema(description = "A bed within a bedspace unit")
public record BedResponse(
        UUID id, UUID unitId, String bedLabel, BedStatus status, BigDecimal rent) {

    public static BedResponse of(Bed bed) {
        return new BedResponse(
                bed.getId(), bed.getUnitId(), bed.getBedLabel(), bed.getStatus(), bed.getRent());
    }
}
