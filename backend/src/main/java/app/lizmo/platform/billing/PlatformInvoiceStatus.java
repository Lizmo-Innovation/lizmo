package app.lizmo.platform.billing;

/**
 * How much of an invoice has been paid.
 *
 * <p>Without OVERDUE, which chk_platform_billing_status still allows, for the
 * reason rent does without it: lateness is a question about today, and the
 * app works it out from the due date when asked.
 */
public enum PlatformInvoiceStatus {
    UNPAID,
    PARTIALLY_PAID,
    PAID
}
