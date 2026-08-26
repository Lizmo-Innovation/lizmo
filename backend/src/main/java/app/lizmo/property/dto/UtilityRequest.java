package app.lizmo.property.dto;

import app.lizmo.property.UtilityKind;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * One utility's setting on a unit.
 *
 * @param amount the fixed monthly charge. May be omitted when switching a
 *               utility off, which keeps whatever figure was there; it is
 *               required when switching one on, since a charge with no amount
 *               is not a charge.
 */
@Schema(description = "A utility's fixed monthly charge on a unit")
public record UtilityRequest(
        @NotNull
        @Schema(example = "WIFI") UtilityKind kind,

        @NotNull
        @Schema(example = "true") Boolean enabled,

        @DecimalMin(value = "0.0", inclusive = false)
        @Schema(example = "500.00") BigDecimal amount) {
}
