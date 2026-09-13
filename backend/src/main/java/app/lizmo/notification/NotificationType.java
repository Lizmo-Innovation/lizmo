package app.lizmo.notification;

/**
 * Mirrors chk_notifications_type.
 *
 * <p>The first four are the exchange the app already runs. The rest were
 * anticipated by the schema and are not built: rent, payments, maintenance and
 * notices have no endpoints yet, and a type nothing raises is a promise rather
 * than a feature.
 */
public enum NotificationType {

    /** To the landlord: somebody is asking about a room. */
    REQUEST_RECEIVED,

    /** To the tenant, carrying the terms they are now on. */
    REQUEST_ACCEPTED,

    REQUEST_DECLINED,

    /**
     * To everybody else who wanted that bed.
     *
     * <p>The silence this whole feature exists for. A superseded request
     * changes state without anybody being told, which is worse than a decline
     * -- a decline at least happens to you.
     */
    REQUEST_SUPERSEDED,

    /**
     * The tenancy is over, said to the tenant.
     *
     * <p>Distinct from LEASE_EXPIRING, which warns that an end is coming. A
     * tenant reading "your lease is expiring" the day after they moved out
     * would not know which of the two was meant.
     */
    LEASE_ENDED,

    RENT_DUE_REMINDER,
    RENT_OVERDUE,
    /**
     * To the landlord: a tenant says they have paid, and it is waiting on them.
     *
     * <p>Distinct from PAYMENT_CONFIRMED, which is the landlord agreeing money
     * arrived. This was raised as that for a while: the words on the row were
     * right and the type said the opposite of what had happened.
     */
    PAYMENT_DECLARED,

    PAYMENT_CONFIRMED,
    PAYMENT_REJECTED,
    /** To the landlord: a tenant says something is broken. */
    MAINTENANCE_REPORTED,

    /** Everything after the report, to whichever side did not make the change. */
    MAINTENANCE_STATUS_CHANGED,

    /** To the landlord: this month's Lizmo invoice for a property. */
    PLATFORM_INVOICE_ISSUED,

    /** To the landlord, once: the invoice is past due, and when the property locks. */
    PLATFORM_INVOICE_OVERDUE,

    /** To the landlord: the invoice went unpaid long enough to lock the property. */
    PLATFORM_PROPERTY_LOCKED,

    /** To the landlord: an admin confirmed their payment. */
    PLATFORM_PAYMENT_CONFIRMED,

    /** To the landlord: an admin refused their payment, and why. */
    PLATFORM_PAYMENT_REJECTED,
    NEW_NOTICE_POSTED,
    LEASE_EXPIRING,
    STAFF_ASSIGNED
}
