package app.lizmo.property;

/**
 * Mirrors chk_units_status.
 *
 * <p>PARTIALLY_OCCUPIED only ever applies to BEDSPACE units, where some beds
 * are let and others are not.
 */
public enum UnitStatus {
    VACANT,
    PARTIALLY_OCCUPIED,
    OCCUPIED,
    MAINTENANCE
}
