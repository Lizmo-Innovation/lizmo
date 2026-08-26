package app.lizmo.property;

/**
 * The utilities a landlord can charge a fixed monthly amount for.
 *
 * <p>Mirrors chk_unit_utilities_kind. Deliberately a short, closed list: these
 * are the three a Philippine boarding house almost always bills, and a landlord
 * choosing from three is faster than one filling in a free-text field.
 */
public enum UtilityKind {
    WIFI,
    ELECTRICITY,
    WATER
}
