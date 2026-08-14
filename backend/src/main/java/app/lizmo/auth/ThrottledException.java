package app.lizmo.auth;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;

/**
 * Raised when sign-in attempts are being rate limited.
 *
 * <p>Carries the retry delay so the handler can set Retry-After, letting a
 * legitimate user who locked themselves out see how long the wait is.
 */
public class ThrottledException extends ApiException {

    private final long retryAfterSeconds;

    public ThrottledException(long retryAfterSeconds) {
        super(ErrorCode.TOO_MANY_ATTEMPTS,
                "Too many sign-in attempts. Please wait a few minutes and try again.");
        this.retryAfterSeconds = retryAfterSeconds;
    }

    public long getRetryAfterSeconds() {
        return retryAfterSeconds;
    }
}
