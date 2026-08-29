package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * A whole unit that is free, as a prospective tenant sees it.
 *
 * @param monthlyUtilities what the unit's switched-on utilities add each month,
 *                         or null when none are. Null is not zero: "the
 *                         landlord has not set any" and "they cost nothing" are
 *                         different statements.
 * @param utilitiesIncluded whether that amount is folded into the rent or
 *                          charged on top. A tenant comparing two rooms is
 *                          really comparing what they will hand over each
 *                          month, and this is what decides it.
 */
@Schema(description = "A whole unit that is free")
public record VacantUnit(
        UUID unitId,
        String unitNumber,
        BigDecimal rent,
        BigDecimal sizeSqm,
        BigDecimal monthlyUtilities,
        boolean utilitiesIncluded) {
}
