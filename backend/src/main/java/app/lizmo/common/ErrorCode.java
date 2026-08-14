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
    PHONE_ALREADY_REGISTERED(HttpStatus.CONFLICT),

    /** Neither email nor phone was supplied — chk_contact requires one. */
    CONTACT_REQUIRED(HttpStatus.BAD_REQUEST),

    NOT_FOUND(HttpStatus.NOT_FOUND),

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
