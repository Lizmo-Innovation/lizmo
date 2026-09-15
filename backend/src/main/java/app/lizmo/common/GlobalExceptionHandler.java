package app.lizmo.common;

import app.lizmo.auth.ThrottledException;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import com.fasterxml.jackson.databind.exc.InvalidFormatException;
import java.util.Arrays;
import java.util.stream.Collectors;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;
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
     * A body Jackson could not read at all.
     *
     * <p>Chiefly an unknown enum value: posting a rentalMode of "HOTEL" or a
     * utility kind of "GAS" fails before bean validation ever runs, so without
     * this the catch-all below turned every typo in an enum into a 500. The
     * caller sent something wrong and can fix it, which is a 400.
     *
     * <p>The exception's own message is not passed on: it carries the Java
     * type names and the parser's position, which mean nothing to a client and
     * leak the internal shape of the API.
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<ApiError> handleUnreadableBody(HttpMessageNotReadableException ex) {
        String message = "Some values are not ones this endpoint accepts.";

        // Name the field and the accepted values when Jackson knows them; that
        // is the difference between a usable error and a shrug.
        if (ex.getCause() instanceof InvalidFormatException invalid) {
            Class<?> target = invalid.getTargetType();
            if (target != null && target.isEnum()) {
                String field = invalid.getPath().isEmpty()
                        ? "value"
                        : invalid.getPath().get(invalid.getPath().size() - 1).getFieldName();
                message = "%s must be one of: %s.".formatted(
                        field,
                        Arrays.stream(target.getEnumConstants())
                                .map(String::valueOf)
                                .collect(Collectors.joining(", ")));
            }
        }

        return ResponseEntity.status(ErrorCode.VALIDATION_FAILED.status())
                .body(ApiError.of(ErrorCode.VALIDATION_FAILED, message));
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
     * A file larger than the container will accept.
     *
     * <p>Without this the upload dies inside the multipart parser and the
     * catch-all turns "your photo is too big" into "something went wrong on our
     * end" — the one message that tells a tenant nothing they can act on.
     */
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    ResponseEntity<ApiError> handleTooLarge(MaxUploadSizeExceededException ex) {
        return ResponseEntity.status(ErrorCode.VALIDATION_FAILED.status())
                .body(ApiError.of(ErrorCode.VALIDATION_FAILED,
                        "That file is larger than 10MB. Please upload a smaller photo."));
    }

    /**
     * A query parameter that will not convert — most often an enum spelled
     * wrong, which would otherwise be a 500 for the same reason an unreadable
     * body was: nothing maps it.
     *
     * <p>Names what is accepted, and deliberately not Spring's own message,
     * which carries Java type names.
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    ResponseEntity<ApiError> handleBadParameter(MethodArgumentTypeMismatchException ex) {
        Class<?> required = ex.getRequiredType();
        String message = required != null && required.isEnum()
                ? "%s must be one of: %s.".formatted(ex.getName(), String.join(", ",
                        java.util.Arrays.stream(required.getEnumConstants())
                                .map(Object::toString).toList()))
                : "%s is not valid.".formatted(ex.getName());
        return ResponseEntity.status(ErrorCode.VALIDATION_FAILED.status())
                .body(ApiError.of(ErrorCode.VALIDATION_FAILED, message));
    }

    /**
     * A form upload missing a field it needs.
     *
     * <p>Named, because "something went wrong" over a missing amount tells
     * nobody what to send. Also what an old app sending the retired single
     * JSON part now gets, instead of a 500.
     */
    @ExceptionHandler({MissingServletRequestPartException.class,
            MissingServletRequestParameterException.class})
    ResponseEntity<ApiError> handleMissingPart(Exception ex) {
        String name = ex instanceof MissingServletRequestPartException part
                ? part.getRequestPartName()
                : ((MissingServletRequestParameterException) ex).getParameterName();
        return ResponseEntity.status(ErrorCode.VALIDATION_FAILED.status())
                .body(ApiError.of(ErrorCode.VALIDATION_FAILED, name + " is required."));
    }

    /**
     * A body or part in a format the endpoint cannot read.
     *
     * <p>This was the tenant's "I have paid" failing: an unlabelled part where
     * JSON was expected, reported as a 500 and shown as an unknown error.
     */
    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    ResponseEntity<ApiError> handleUnsupportedMedia(HttpMediaTypeNotSupportedException ex) {
        return ResponseEntity.status(ErrorCode.UNSUPPORTED_MEDIA_TYPE.status())
                .body(ApiError.of(ErrorCode.UNSUPPORTED_MEDIA_TYPE,
                        "That request was sent in a format this endpoint does not accept."));
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
