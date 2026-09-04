package app.lizmo.common;

import org.springframework.http.HttpStatus;

/**
 * Every error the API can return, as a stable machine-readable code.
 *
 * <p>Clients switch on these, never on the human-readable message — messages
 * are free to change wording, codes are not. Adding a value is safe; renaming
 * one breaks released app versions that are already in users' hands.
 */
public enum ErrorCode {

    VALIDATION_FAILED(HttpStatus.BAD_REQUEST),

    /** Credentials did not match, or the account is inactive. */
    INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED),

    /** No token, or a malformed/expired one. The client should route to login. */
    UNAUTHENTICATED(HttpStatus.UNAUTHORIZED),

    /** Authenticated, but not permitted. The client should not route to login. */
    FORBIDDEN(HttpStatus.FORBIDDEN),

    REFRESH_TOKEN_INVALID(HttpStatus.UNAUTHORIZED),

    EMAIL_ALREADY_REGISTERED(HttpStatus.CONFLICT),

    /** Too many failed sign-in attempts. Carries Retry-After. */
    TOO_MANY_ATTEMPTS(HttpStatus.TOO_MANY_REQUESTS),

    NOT_FOUND(HttpStatus.NOT_FOUND),

    /**
     * The verification code has run out of time.
     *
     * <p>Separate from OTP_INCORRECT so the app can offer the right thing: a
     * button to send a new code, rather than an invitation to retype the old
     * one. Checked before correctness, so a guesser learns only that time
     * passed and never that a code was right but late.
     */
    OTP_EXPIRED(HttpStatus.BAD_REQUEST),

    /** Wrong digits. The message names how many tries remain. */
    OTP_INCORRECT(HttpStatus.BAD_REQUEST),

    /** Too many wrong guesses; that code is dead and a new one is needed. */
    OTP_ATTEMPTS_EXHAUSTED(HttpStatus.BAD_REQUEST),

    /**
     * The password does not meet the rule.
     *
     * <p>Its own code rather than VALIDATION_FAILED, so the app can put the
     * message under the password field rather than in a general error banner.
     */
    WEAK_PASSWORD(HttpStatus.BAD_REQUEST),

    /** A new code was asked for inside the cooldown. */
    OTP_TOO_SOON(HttpStatus.TOO_MANY_REQUESTS),

    /** That address has had its codes for today. */
    OTP_TOO_MANY(HttpStatus.TOO_MANY_REQUESTS),

    /**
     * A lease was asked for against a tenant whose profile is not complete.
     *
     * <p>409 rather than 400: nothing is wrong with the request, and the same
     * request will succeed once the tenant finishes their profile. The message
     * names what is missing so the landlord can tell them.
     */
    TENANT_PROFILE_INCOMPLETE(HttpStatus.CONFLICT),

    /**
     * The bed or unit asked for is not on offer — already let, out of service,
     * or not let that way.
     *
     * <p>409 rather than 400 or 404: the request is well formed and the slot
     * exists, it is simply no longer available. A tenant who saw it a minute
     * ago on the vacancy list did nothing wrong.
     */
    SLOT_UNAVAILABLE(HttpStatus.CONFLICT),

    /** The same tenant already has a request waiting on this exact slot. */
    ALREADY_REQUESTED(HttpStatus.CONFLICT),

    /**
     * The landlord's platform invoice is unpaid past the grace period. The
     * client routes to the outstanding billing cycle so they can pay and
     * unlock — see product spec §3.
     */
    ACCOUNT_LOCKED_UNPAID_INVOICE(HttpStatus.FORBIDDEN),

    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR);

    private final HttpStatus status;

    ErrorCode(HttpStatus status) {
        this.status = status;
    }

    public HttpStatus status() {
        return status;
    }
}
