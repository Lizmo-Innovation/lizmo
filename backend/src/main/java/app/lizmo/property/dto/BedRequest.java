package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

/**
 * @param rent what this bed asks, when it differs from its unit's rent. Null
 *             means the unit's figure applies — not that the bed is free.
 */
@Schema(description = "Bed details")
public record BedRequest(
        @NotBlank @Size(max = 50)
        @Schema(example = "Bed 1") String bedLabel,

        @DecimalMin(value = "0.0", inclusive = false)
        @Schema(example = "2500.00",
                description = "Per-bed rent. Omit to charge whatever the unit asks.")
        BigDecimal rent) {
}
