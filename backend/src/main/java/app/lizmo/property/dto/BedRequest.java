package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Bed details")
public record BedRequest(
        @NotBlank @Size(max = 50)
        @Schema(example = "Bed 1") String bedLabel) {
}
