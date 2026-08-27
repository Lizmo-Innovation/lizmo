package app.lizmo.property;

/**
 * How a unit's utility charges reach the tenant. Mirrors
 * chk_units_utility_billing.
 *
 * <p>A presentation choice, not an arithmetic one: the amounts are the same
 * either way. What changes is whether the tenant sees one figure or two, and
 * whether they can settle them separately.
 */
public enum UtilityBilling {

    /** Folded into the rent billing period — one amount, one payment. */
    COMBINED,

    /**
     * Issued as a charge of its own.
     *
     * <p>What a landlord wants when rent and utilities are settled at different
     * times, or paid by different means — rent by bank transfer, utilities in
     * cash on collection day.
     */
    SEPARATE
}
