package app.lizmo.property.dto;

import app.lizmo.property.Property;
import app.lizmo.property.PropertyType;
import app.lizmo.property.PropertyUsage;
import io.swagger.v3.oas.annotations.media.Schema;
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
 */
@Schema(description = "A property found by its code, as a prospective tenant sees it")
public record PropertyByCodeResponse(
        UUID id,
        String code,
        String name,
        String address,
        String description,
        PropertyType type,
        PropertyUsage usage) {

    public static PropertyByCodeResponse of(Property property) {
        return new PropertyByCodeResponse(
                property.getId(),
                property.getCode(),
                property.getName(),
                property.getAddress(),
                property.getDescription(),
                property.getType(),
                property.getUsage());
    }
}
