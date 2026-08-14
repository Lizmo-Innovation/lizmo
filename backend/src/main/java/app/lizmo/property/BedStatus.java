package app.lizmo.property;

/**
 * Mirrors chk_beds_status.
 *
 * <p>MAINTENANCE is independent of tenancy: a landlord can take a bed out of
 * service without ending anyone's lease, and it stops counting as rentable.
 */
public enum BedStatus {
    VACANT,
    OCCUPIED,
    MAINTENANCE
}
