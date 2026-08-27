package app.lizmo.property.dto;

import app.lizmo.property.UtilityBilling;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

/**
 * A unit's utility settings, whole.
 *
 * <p>Returned as an object rather than a bare list because the charges are only
 * half the answer: how they reach the tenant belongs with them, and a client
 * showing a utilities screen needs both.
 */
@Schema(description = "A unit's utility settings")
public record UtilitiesResponse(UtilityBilling billing, List<UtilityResponse> utilities) {
}
