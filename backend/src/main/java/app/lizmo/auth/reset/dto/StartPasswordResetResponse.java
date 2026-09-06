package app.lizmo.auth.reset.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * Returned identically for an address with an account and one without.
 *
 * <p>Carries no confirmation that anything was sent, on purpose. Anything more
 * specific -- "sent", "no such account" -- would answer a question this
 * endpoint deliberately refuses to answer.
 *
 * @param resendAfterSeconds how long before another code can be asked for, so
 *                           the screen counts down instead of guessing.
 */
@Schema(description = "If that address has an account, a code is on its way")
public record StartPasswordResetResponse(int resendAfterSeconds) {
}
