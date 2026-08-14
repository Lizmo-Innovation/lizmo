package app.lizmo.common;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.Map;

/**
 * The single error shape for every endpoint. One shape means both Flutter apps
 * parse errors in one place.
 *
 * @param code    machine-readable and stable; clients branch on this
 * @param message human-readable, safe to show but free to change
 * @param fields  per-field validation messages, empty unless code is VALIDATION_FAILED
 */
@Schema(description = "Standard error response")
public record ApiError(
        @Schema(example = "INVALID_CREDENTIALS") String code,
        @Schema(example = "Email or password is incorrect.") String message,
        Map<String, String> fields,
        Instant timestamp) {

    public static ApiError of(ErrorCode code, String message) {
        return new ApiError(code.name(), message, Map.of(), Instant.now());
    }

    public static ApiError validation(String message, Map<String, String> fields) {
        return new ApiError(ErrorCode.VALIDATION_FAILED.name(), message, fields, Instant.now());
    }
}
