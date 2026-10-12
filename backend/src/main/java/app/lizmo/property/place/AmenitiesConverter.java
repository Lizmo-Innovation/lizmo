package app.lizmo.property.place;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * A place's amenities as one comma-separated column: "WIFI,AIRCON".
 *
 * <p>A handful of fixed words read and written together, never queried one
 * by one -- a join table would be ceremony for a checklist. Words this build
 * does not know are dropped rather than failing the whole row.
 */
@Converter
public class AmenitiesConverter implements AttributeConverter<Set<Amenity>, String> {

    @Override
    public String convertToDatabaseColumn(Set<Amenity> amenities) {
        if (amenities == null || amenities.isEmpty()) {
            return "";
        }
        return amenities.stream()
                .sorted()
                .map(Amenity::name)
                .collect(Collectors.joining(","));
    }

    @Override
    public Set<Amenity> convertToEntityAttribute(String column) {
        Set<Amenity> amenities = EnumSet.noneOf(Amenity.class);
        if (column == null || column.isBlank()) {
            return amenities;
        }
        Arrays.stream(column.split(","))
                .map(String::trim)
                .forEach(word -> {
                    try {
                        amenities.add(Amenity.valueOf(word));
                    } catch (IllegalArgumentException unknown) {
                        // Written by a newer build; not ours to fail on.
                    }
                });
        return amenities;
    }
}
