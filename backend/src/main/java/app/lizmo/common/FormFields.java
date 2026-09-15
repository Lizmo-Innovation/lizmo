package app.lizmo.common;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Arrays;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Plain text fields from a form upload, turned into the values they stand for.
 *
 * <p>An upload with a photo sends each field as its own part. They arrive as
 * text, often with no content type at all -- which is how the generated app
 * client sends them, and why they are read as strings and converted here
 * rather than handed to a JSON converter that refuses anything unlabelled.
 *
 * <p>Every failure names the field, so a bad value is a 400 somebody can act
 * on rather than a 500.
 */
public final class FormFields {

    private FormFields() {
    }

    public static UUID id(String value, String field) {
        String text = required(value, field);
        try {
            return UUID.fromString(text);
        } catch (IllegalArgumentException e) {
            throw invalid(field + " is not valid.");
        }
    }

    public static UUID optionalId(String value, String field) {
        return blank(value) ? null : id(value, field);
    }

    public static BigDecimal amount(String value, String field) {
        String text = required(value, field);
        try {
            return new BigDecimal(text);
        } catch (NumberFormatException e) {
            throw invalid(field + " must be a number, such as 2500.");
        }
    }

    /**
     * A calendar date as YYYY-MM-DD, or null when not sent.
     *
     * <p>A date, never a timestamp: a Philippine midnight converted to UTC is
     * the previous day, so accepting and trimming timestamps would quietly
     * record the wrong day.
     */
    public static LocalDate date(String value, String field) {
        if (blank(value)) {
            return null;
        }
        try {
            return LocalDate.parse(value.trim());
        } catch (DateTimeParseException e) {
            throw invalid(field + " must be a date written as YYYY-MM-DD.");
        }
    }

    /** One of an enum's names, or null when not sent. */
    public static <E extends Enum<E>> E choice(String value, Class<E> type, String field) {
        if (blank(value)) {
            return null;
        }
        try {
            return Enum.valueOf(type, value.trim());
        } catch (IllegalArgumentException e) {
            throw invalid("%s must be one of: %s.".formatted(field,
                    Arrays.stream(type.getEnumConstants())
                            .map(Enum::name)
                            .collect(Collectors.joining(", "))));
        }
    }

    /** Trimmed, null when blank, and no longer than {@code max}. */
    public static String text(String value, int max, String field) {
        if (blank(value)) {
            return null;
        }
        String text = value.trim();
        if (text.length() > max) {
            throw invalid("%s must be %d characters or fewer.".formatted(field, max));
        }
        return text;
    }

    private static String required(String value, String field) {
        if (blank(value)) {
            throw invalid(field + " is required.");
        }
        return value.trim();
    }

    private static boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private static ApiException invalid(String message) {
        return new ApiException(ErrorCode.VALIDATION_FAILED, message);
    }
}
