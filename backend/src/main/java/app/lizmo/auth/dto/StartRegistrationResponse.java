package app.lizmo.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * @param resendAfterSeconds how long before another code can be asked for, so
 *                           the screen counts down instead of guessing — and so
 *                           the rule lives in one place rather than being
 *                           duplicated in every client.
 */
@Schema(description = "A code is on its way")
public record StartRegistrationResponse(int resendAfterSeconds) {
}
