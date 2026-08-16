package app.lizmo.property.dto;

import app.lizmo.property.Property;
import app.lizmo.property.PropertyType;
import app.lizmo.property.PropertyUsage;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

/**
 * @param unitCount how many units the property holds, so a list screen can show
 *                  it without a request per row
 */
@Schema(description = "A property owned by the signed-in landlord")
public record PropertyResponse(
        UUID id,
        String name,
        String address,
        PropertyType type,
        PropertyUsage usage,
        long unitCount,
        Instant createdAt,
        Instant updatedAt) {

    public static PropertyResponse of(Property property, long unitCount) {
        return new PropertyResponse(
                property.getId(),
                property.getName(),
                property.getAddress(),
                property.getType(),
                property.getUsage(),
                unitCount,
                property.getCreatedAt(),
                property.getUpdatedAt());
    }
}
