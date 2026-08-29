package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * A bed that is free, as a prospective tenant sees it.
 *
 * @param rent what this bed asks. Already resolved — a bed with no price of its
 *             own reports its unit's, because null here would read as free to
 *             anyone who did not know the fallback rule.
 * @param monthlyUtilities the unit's switched-on utilities. Charged per unit
 *                         rather than per bed, so bedmates share whatever this
 *                         says.
 */
@Schema(description = "A bed that is free")
public record VacantBed(
        UUID unitId,
        String unitNumber,
        UUID bedId,
        String bedLabel,
        BigDecimal rent,
        BigDecimal monthlyUtilities,
        boolean utilitiesIncluded) {
}
