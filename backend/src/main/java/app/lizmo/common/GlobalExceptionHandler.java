package app.lizmo.common;

import app.lizmo.auth.ThrottledException;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/** Turns every exception into the one {@link ApiError} shape. */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    ResponseEntity<ApiError> handleApi(ApiException ex) {
        // Throttling carries a retry delay, so a locked-out user can be told how
        // long to wait rather than guessing.
        if (ex instanceof ThrottledException throttled) {
            return ResponseEntity.status(ex.getCode().status())
                    .header(HttpHeaders.RETRY_AFTER, String.valueOf(throttled.getRetryAfterSeconds()))
                    .body(ApiError.of(ex.getCode(), ex.getMessage()));
        }

        return ResponseEntity.status(ex.getCode().status())
                .body(ApiError.of(ex.getCode(), ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fields = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(e ->
                fields.putIfAbsent(e.getField(), e.getDefaultMessage()));

        return ResponseEntity.status(ErrorCode.VALIDATION_FAILED.status())
                .body(ApiError.validation("Some fields need attention.", fields));
    }

    /**
     * Unmatched paths.
     *
     * <p>Both types are handled because Spring 6.1 routes unmatched requests to
     * NoResourceFoundException via the static-resource handler, while
     * NoHandlerFoundException only appears with throwExceptionIfNoHandlerFound.
     * Without the former, the catch-all below turns every typo'd URL into a 500.
     */
    @ExceptionHandler({NoHandlerFoundException.class, NoResourceFoundException.class})
    ResponseEntity<ApiError> handleNotFound(Exception ex) {
        return ResponseEntity.status(ErrorCode.NOT_FOUND.status())
                .body(ApiError.of(ErrorCode.NOT_FOUND, "No such endpoint."));
    }

    /**
     * Last resort. The cause is logged but never returned — stack traces and
     * SQL fragments in a response body are an information leak.
     */
    @ExceptionHandler(Exception.class)
    ResponseEntity<ApiError> handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(ErrorCode.INTERNAL_ERROR.status())
                .body(ApiError.of(ErrorCode.INTERNAL_ERROR, "Something went wrong on our end."));
    }
}
