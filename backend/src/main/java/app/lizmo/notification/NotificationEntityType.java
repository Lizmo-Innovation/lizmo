package app.lizmo.notification;

/** Mirrors chk_notifications_entity_type: what a notification is about. */
public enum NotificationEntityType {
    RENTAL_REQUEST,

    /** A conversation about a property. */
    INQUIRY,
    LEASE,
    BILLING_PERIOD,
    PAYMENT,
    MAINTENANCE_REQUEST,
    NOTICE,
    STAFF_ASSIGNMENT,
    PLATFORM_INVOICE
}
