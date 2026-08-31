package app.lizmo.rental;

/**
 * Where a request has got to. Mirrors chk_rental_requests_status.
 */
public enum RentalRequestStatus {

    /** Waiting on the landlord. The only state a tenant can withdraw from. */
    PENDING,

    /** The landlord said yes, and a lease exists because of it. */
    ACCEPTED,

    DECLINED,

    /** The tenant changed their mind, or took a room elsewhere. */
    WITHDRAWN,

    /**
     * The slot went to somebody else.
     *
     * <p>Kept apart from DECLINED on purpose: nobody judged this tenant, they
     * were simply not first, and the app should be able to say so.
     */
    SUPERSEDED
}
