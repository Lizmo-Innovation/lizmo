package app.lizmo.maintenance;

/**
 * Where a report has got to.
 *
 * <p>Mirrors chk_maintenance_status. The order of the happy path is
 * SUBMITTED, IN_PROGRESS, RESOLVED, CLOSED -- and the last step is the
 * tenant's, not the landlord's: a landlord saying something is fixed and it
 * being fixed are different, and only the person living with it can say the
 * second.
 */
public enum MaintenanceStatus {

    /** Reported, and nobody has started on it. Also where a reopened report goes. */
    SUBMITTED,

    /** The landlord is dealing with it. */
    IN_PROGRESS,

    /** The landlord says it is fixed; waiting for the tenant to agree. */
    RESOLVED,

    /** The tenant agrees it is fixed. */
    CLOSED,

    /** The tenant took it back before anybody had started on it. */
    WITHDRAWN
}
