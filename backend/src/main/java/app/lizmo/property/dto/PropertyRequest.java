package app.lizmo.property.dto;

import app.lizmo.property.PropertyType;
import app.lizmo.property.PropertyUsage;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Schema(description = "Property details")
public record PropertyRequest(
        @NotBlank @Size(max = 255)
        @Schema(example = "Sunrise Apartments") String name,

        @NotBlank
        @Schema(example = "12 Mabini St, Quezon City") String address,

        @NotNull
        @Schema(example = "BOARDING_HOUSE") PropertyType type,

        @NotNull
        @Schema(
                example = "RESIDENTIAL",
                description = "Constrains type: residential properties take "
                        + "APARTMENT, BOARDING_HOUSE, CONDO or SINGLE_HOUSE; "
                        + "commercial ones take OFFICE, RETAIL_SPACE, WAREHOUSE "
                        + "or STALL.")
        PropertyUsage usage) {
}
