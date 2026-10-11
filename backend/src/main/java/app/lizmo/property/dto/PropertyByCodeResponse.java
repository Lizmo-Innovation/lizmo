package app.lizmo.property.dto;

import app.lizmo.property.Property;
import app.lizmo.property.PropertyType;
import app.lizmo.property.PropertyUsage;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import java.util.UUID;

/**
 * A property as a prospective tenant sees it, having typed or scanned its code.
 *
 * <p>Deliberately not PropertyResponse. That one carries potentialMonthlyRent
 * -- what the landlord's building earns -- along with counts of everything they
 * own. This is served to anyone holding a code, who has no relationship to the
 * landlord at all, so it carries only what someone deciding whether to go and
 * look at the place needs.
 *
 * <p>Prices belong on the vacancy list, where they are the asking rent for one
 * bed or unit, not a total.
 *
 * @param floors what is free, grouped by floor — the whole point of scanning
 *               the code. Empty when the place is full, which is a real answer
 *               and not an error.
 * @param vacantWholeUnits totals across every floor, so a screen can lead with
 *               "2 rooms free" without adding up the lists itself.
 * @param photos what the place looks like, in the landlord's order, the first
 *               being the one that represents it. Short-lived URLs, like every
 *               other object the app hands out. Empty until somebody uploads
 *               one, which is most properties today.
 */
@Schema(description = "A property found by its code, as a prospective tenant sees it")
public record PropertyByCodeResponse(
        UUID id,
        String code,
        String name,
        String address,
        String description,
        PropertyType type,
        PropertyUsage usage,
        int vacantWholeUnits,
        int vacantBeds,
        List<VacancyFloor> floors,
        List<String> photos) {

    public static PropertyByCodeResponse of(
            Property property, List<VacancyFloor> floors, List<String> photos) {
        int wholeUnits = floors.stream().mapToInt(VacancyFloor::wholeUnits).sum();
        int beds = floors.stream().mapToInt(VacancyFloor::beds).sum();
        return new PropertyByCodeResponse(
                property.getId(),
                property.getCode(),
                property.getName(),
                property.getAddress(),
                property.getDescription(),
                property.getType(),
                property.getUsage(),
                wholeUnits,
                beds,
                floors,
                photos);
    }
}
