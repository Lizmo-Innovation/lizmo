package app.lizmo.property;

/**
 * How a unit is let.
 *
 * <p>The distinction runs through the whole product: WHOLE_UNIT has one lease
 * and one rent, BEDSPACE has a lease per bed. It is fixed at unit creation
 * because changing it would orphan either the beds or the unit's lease.
 */
public enum RentalMode {
    WHOLE_UNIT,
    BEDSPACE
}
