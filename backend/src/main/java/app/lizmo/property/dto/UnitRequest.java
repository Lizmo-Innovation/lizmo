package app.lizmo.property.dto;

import app.lizmo.property.RentalMode;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

/**
 * @param rentalMode ignored on update — a unit cannot change mode once created,
 *                   since that would orphan its beds or its lease
 * @param capacity   maximum occupants; only meaningful for BEDSPACE
 */
@Schema(description = "Unit details")
public record UnitRequest(
        @NotBlank @Size(max = 50)
        @Schema(example = "2B") String unitNumber,

        @Size(max = 20)
        @Schema(example = "2") String floor,

        @DecimalMin(value = "0.0", inclusive = false)
        @Schema(example = "24.5") BigDecimal sizeSqm,

        @NotNull
        @Schema(example = "BEDSPACE") RentalMode rentalMode,

        @Min(1)
        @Schema(example = "4", defaultValue = "1") Integer capacity) {

    /** Whole units hold one tenancy, so capacity is meaningless there. */
    public int effectiveCapacity() {
        if (rentalMode == RentalMode.WHOLE_UNIT) {
            return 1;
        }
        return capacity == null ? 1 : capacity;
    }
}
