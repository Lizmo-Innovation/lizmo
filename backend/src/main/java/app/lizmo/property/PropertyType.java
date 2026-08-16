package app.lizmo.property;

/**
 * The building form. Mirrors chk_properties_type.
 *
 * <p>Which of these a property may claim depends on its {@link PropertyUsage} —
 * the sets live there, not here, so that a type can belong to more than one
 * usage later without this enum needing to know.
 */
public enum PropertyType {
    // Residential
    APARTMENT,
    BOARDING_HOUSE,
    CONDO,
    SINGLE_HOUSE,

    // Commercial
    OFFICE,
    RETAIL_SPACE,
    WAREHOUSE,
    STALL
}
