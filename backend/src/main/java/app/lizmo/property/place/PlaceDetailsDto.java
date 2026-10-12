package app.lizmo.property.place;

import app.lizmo.property.place.PlaceDetails.Visitors;
import app.lizmo.property.place.PlaceDetails.WhoCanRent;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * A place's details, both as a landlord sets them and as anybody reads them.
 * Every field is optional; null is "not said".
 */
@Schema(description = "What a tenant wants to know before asking. Every field is "
        + "optional; null means not said, which is not the same as no.")
public record PlaceDetailsDto(
        @Schema(description = "Who the place lets to") WhoCanRent whoCanRent,

        @Pattern(regexp = "^([01][0-9]|2[0-3]):[0-5][0-9]$",
                message = "Give the curfew as a time, like 22:00.")
        @Schema(example = "22:00", description = "Null for no curfew said")
        String curfew,

        Visitors visitors,
        Boolean cooking,
        Boolean pets,
        Boolean smoking,

        @Size(max = 1000)
        @Schema(example = "Lights out in the common room at 11. Shoes off inside.")
        String otherRules,

        @Min(0) @Max(6)
        @Schema(example = "2", description = "The deposit, in months of the room's rent")
        Integer depositMonths,

        @Min(0) @Max(6)
        @Schema(example = "1", description = "Rent paid ahead, in months")
        Integer advanceMonths,

        List<Amenity> amenities) {

    static PlaceDetailsDto of(PlaceDetails details) {
        if (details == null) {
            return empty();
        }
        return new PlaceDetailsDto(
                details.getWhoCanRent(),
                details.getCurfew(),
                details.getVisitors(),
                details.getCooking(),
                details.getPets(),
                details.getSmoking(),
                details.getOtherRules(),
                details.getDepositMonths() == null ? null : details.getDepositMonths().intValue(),
                details.getAdvanceMonths() == null ? null : details.getAdvanceMonths().intValue(),
                List.copyOf(details.getAmenities()));
    }

    static PlaceDetailsDto empty() {
        return new PlaceDetailsDto(null, null, null, null, null, null, null, null, null, List.of());
    }
}
