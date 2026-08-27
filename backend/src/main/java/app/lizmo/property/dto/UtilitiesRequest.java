package app.lizmo.property.dto;

import app.lizmo.property.UtilityBilling;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

/**
 * A unit's utility settings.
 *
 * <p>An object wrapping the list rather than a bare array. Bean validation does
 * not cascade into the elements of a top-level {@code List} body, so a bad
 * amount slipped past the constraints and surfaced as a 500 from the database
 * instead of a 400 naming the field.
 *
 * @param billing how the charges reach the tenant. Omit to leave it as it is,
 *                so a client changing an amount need not restate it.
 */
@Schema(description = "Utility settings to apply to a unit")
public record UtilitiesRequest(
        @Schema(example = "COMBINED") UtilityBilling billing,

        @NotEmpty @Valid List<UtilityRequest> utilities) {
}
