package app.lizmo.property.dto;

import app.lizmo.property.RentalMode;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * @param bedCount number of beds defined; always 0 for WHOLE_UNIT
 */
@Schema(description = "A unit within a property")
public record UnitResponse(
        UUID id,
        UUID propertyId,
        String unitNumber,
        String floor,
        BigDecimal sizeSqm,
        RentalMode rentalMode,
        int capacity,
        UnitStatus status,
        long bedCount) {

    public static UnitResponse of(Unit unit, long bedCount) {
        return new UnitResponse(
                unit.getId(),
                unit.getPropertyId(),
                unit.getUnitNumber(),
                unit.getFloor(),
                unit.getSizeSqm(),
                unit.getRentalMode(),
                unit.getCapacity(),
                unit.getStatus(),
                bedCount);
    }
}
