package app.lizmo.property.dto;

import app.lizmo.property.RentalMode;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * @param bedCount number of beds defined; always 0 for WHOLE_UNIT
 * @param bedsUnderMaintenance how many of those are out of service, and so not
 *                 rentable. Subtract from bedCount for the rentable figure.
 * @param rent     asking rent. For BEDSPACE this is the default each bed is
 *                 let at unless it carries its own. Null when the landlord has
 *                 not set one — never 0, which would read as free.
 * @param potentialMonthlyRent what the unit brings in per month when every
 *                 rentable space is let: the unit's own rent for a whole unit,
 *                 and the sum of its beds' effective rents for a bedspace.
 *                 Beds out of service are left out — they cannot be let, so
 *                 counting them would overstate what the unit can earn.
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
        long bedCount,
        long bedsUnderMaintenance,
        BigDecimal rent,
        BigDecimal potentialMonthlyRent) {

    public static UnitResponse of(
            Unit unit, long bedCount, long bedsUnderMaintenance, BigDecimal potentialMonthlyRent) {
        return new UnitResponse(
                unit.getId(),
                unit.getPropertyId(),
                unit.getUnitNumber(),
                unit.getFloor(),
                unit.getSizeSqm(),
                unit.getRentalMode(),
                unit.getCapacity(),
                unit.getStatus(),
                bedCount,
                bedsUnderMaintenance,
                unit.getRent(),
                potentialMonthlyRent);
    }
}
