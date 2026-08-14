package app.lizmo.security;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
 * Resolves who is making the current request.
 *
 * <p>The JWT filter puts the user id in the security context as the principal
 * name. Reading it in one place keeps every service from re-deriving it, and
 * makes it obvious where the identity comes from.
 */
@Component
public class CurrentUser {

    /**
     * @throws ApiException if the request is unauthenticated. Endpoints reaching
     *                      here should already be behind the security filter, so
     *                      this is a guard against a route being permitted by
     *                      mistake rather than an expected path.
     */
    public UUID requireId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth.getName() == null) {
            throw new ApiException(ErrorCode.UNAUTHENTICATED, "Please sign in.");
        }
        try {
            return UUID.fromString(auth.getName());
        } catch (IllegalArgumentException e) {
            // A token whose subject is not a UUID did not come from us.
            throw new ApiException(ErrorCode.UNAUTHENTICATED, "Please sign in.");
        }
    }
}
