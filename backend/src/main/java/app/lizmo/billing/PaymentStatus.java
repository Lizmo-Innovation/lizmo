package app.lizmo.billing;

/**
 * Whether a payment counts yet.
 *
 * <p>A tenant saying they paid and a landlord agreeing are different events,
 * and only the second moves a balance. A landlord recording money they
 * received themselves skips straight to CONFIRMED -- there is nobody for them
 * to disagree with.
 */
public enum PaymentStatus {
    PENDING_VERIFICATION,
    CONFIRMED,
    REJECTED
}
