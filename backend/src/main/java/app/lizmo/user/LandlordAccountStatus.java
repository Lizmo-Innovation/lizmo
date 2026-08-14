package app.lizmo.user;

/**
 * Mirrors chk_landlord_account_status.
 *
 * <p>LOCKED is set by the billing enforcement job once a platform invoice is
 * unpaid 7 days past due. It blocks landlord-side management actions but never
 * affects that landlord's tenants.
 */
public enum LandlordAccountStatus {
    ACTIVE,
    LOCKED
}
