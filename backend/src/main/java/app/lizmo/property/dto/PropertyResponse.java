package app.lizmo.property.dto;

import app.lizmo.property.Property;
import app.lizmo.property.PropertyType;
import app.lizmo.property.PropertyUsage;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * @param unitCount how many units the property holds, so a list screen can show
 *                  it without a request per row
 * @param potentialMonthlyRent what the whole property brings in per month with
 *                  everything let. Null when nothing in it is priced — not the
 *                  same as free. The property list is the first place a
 *                  landlord looks, and it is the figure they look for.
 */
@Schema(description = "A property owned by the signed-in landlord")
public record PropertyResponse(
        UUID id,
        String name,
        String address,
        String description,
        PropertyType type,
        PropertyUsage usage,
        long unitCount,
        BigDecimal potentialMonthlyRent,
        Instant createdAt,
        Instant updatedAt) {

    public static PropertyResponse of(
            Property property, long unitCount, BigDecimal potentialMonthlyRent) {
        return new PropertyResponse(
                property.getId(),
                property.getName(),
                property.getAddress(),
                property.getDescription(),
                property.getType(),
                property.getUsage(),
                unitCount,
                potentialMonthlyRent,
                property.getCreatedAt(),
                property.getUpdatedAt());
    }
}
