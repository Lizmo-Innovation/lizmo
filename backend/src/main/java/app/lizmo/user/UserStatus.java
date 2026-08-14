package app.lizmo.user;

/**
 * Mirrors chk_users_status. Values are persisted as strings, so renaming a
 * constant is a breaking database change — add a migration if that is ever
 * needed.
 */
public enum UserStatus {
    ACTIVE,
    INACTIVE
}
