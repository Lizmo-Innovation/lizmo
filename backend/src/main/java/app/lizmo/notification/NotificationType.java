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

    RENT_DUE_REMINDER,
    RENT_OVERDUE,
    PAYMENT_CONFIRMED,
    PAYMENT_REJECTED,
    MAINTENANCE_STATUS_CHANGED,
    NEW_NOTICE_POSTED,
    LEASE_EXPIRING,
    STAFF_ASSIGNED
}
