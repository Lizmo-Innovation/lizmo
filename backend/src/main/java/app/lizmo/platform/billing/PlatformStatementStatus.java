package app.lizmo.platform.billing;

/**
 * How much of a statement has been paid.
 *
 * <p>Without OVERDUE, for the reason rent does without it: lateness is a
 * question about today, worked out when asked rather than stored and left to
 * go stale.
 */
public enum PlatformStatementStatus {
    UNPAID,
    PARTIALLY_PAID,
    PAID
}
