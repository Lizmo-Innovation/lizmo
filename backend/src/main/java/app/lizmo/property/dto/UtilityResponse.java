package app.lizmo.property.dto;

import app.lizmo.property.UnitUtility;
import app.lizmo.property.UtilityKind;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;

/**
 * @param amount the figure last set, which survives the utility being switched
 *               off. Read it with {@code enabled}: an amount alone does not
 *               mean anything is being charged.
 */
@Schema(description = "A utility's fixed monthly charge on a unit")
public record UtilityResponse(UtilityKind kind, boolean enabled, BigDecimal amount) {

    public static UtilityResponse of(UnitUtility utility) {
        return new UtilityResponse(utility.getKind(), utility.isEnabled(), utility.getAmount());
    }

    /** A utility the landlord has never touched. */
    public static UtilityResponse unset(UtilityKind kind) {
        return new UtilityResponse(kind, false, null);
    }
}
