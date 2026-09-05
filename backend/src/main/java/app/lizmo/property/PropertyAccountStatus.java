package app.lizmo.property;

/**
 * Mirrors chk_properties_account_status.
 *
 * <p>LOCKED is set when this property's platform invoice is unpaid past the
 * grace period. It blocks anything that <em>grows</em> the property -- new
 * units, new beds, accepting a request -- and permits everything that shrinks
 * it or serves the people already living there.
 *
 * <p>That asymmetry is deliberate. Ending a lease is allowed while locked
 * because it reduces what the landlord owes, and blocking it would mean
 * billing for a bed they are not allowed to mark empty. Declining a request is
 * allowed because the tenant waiting on an answer is not Lizmo's debtor and
 * must not be trapped.
 */
public enum PropertyAccountStatus {
    ACTIVE,
    LOCKED
}
