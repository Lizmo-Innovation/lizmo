package app.lizmo.property.dto;

import app.lizmo.property.Property;
import app.lizmo.property.PropertyType;
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
        long unitCount,
        Instant createdAt,
        Instant updatedAt) {

    public static PropertyResponse of(Property property, long unitCount) {
        return new PropertyResponse(
                property.getId(),
                property.getName(),
                property.getAddress(),
                property.getType(),
                unitCount,
                property.getCreatedAt(),
                property.getUpdatedAt());
    }
}
