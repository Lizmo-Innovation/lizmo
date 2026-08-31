package app.lizmo.lease;

/**
 * Mirrors chk_leases_status.
 */
public enum LeaseStatus {

    ACTIVE,

    /** Ran its course. */
    ENDED,

    /** Stopped early, by either side. */
    TERMINATED
}
