package app.lizmo.billing;

/** How the money moved. Mirrors chk_payments_method. */
public enum PaymentMethod {
    CASH,
    GCASH,
    MAYA,
    BANK_TRANSFER,
    OTHER,

    /**
     * Rent handed over before moving in, which pays the first month.
     *
     * <p>Its own method rather than OTHER: "paid in advance at the door" and
     * "paid by some means we did not list" are different facts, and a landlord
     * looking back should not have to read a remark to tell them apart.
     */
    ADVANCE
}
