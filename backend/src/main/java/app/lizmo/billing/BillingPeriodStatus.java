package app.lizmo.billing;

/**
 * How much of a month's rent has come in.
 *
 * <p>Deliberately without OVERDUE, which the database constraint still allows.
 * Whether rent is late is a question about today, and a stored answer is wrong
 * from the moment it is written until something runs to correct it. The app
 * works lateness out from the due date when it is asked.
 */
public enum BillingPeriodStatus {
    UNPAID,
    PARTIALLY_PAID,
    PAID
}
