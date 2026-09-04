package app.lizmo.auth;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import java.util.ArrayList;
import java.util.List;

/**
 * What Lizmo will accept as a password.
 *
 * <p>Ariel's rule: at least eight characters, with an uppercase letter, a
 * lowercase letter, a digit and a symbol. Familiar from Philippine banking
 * apps, which is where most people will have met it.
 *
 * <p>Its own class, and not a regex. A single pattern would refuse everything
 * with one message — "password is invalid" — leaving somebody to guess which
 * of five rules they broke. Checked one at a time, each failure can say the
 * thing that is actually missing.
 */
public final class PasswordPolicy {

    static final int MIN_LENGTH = 8;

    /**
     * Anything that is not a letter or a digit counts.
     *
     * <p>Deliberately not a fixed list of punctuation: a password picked with a
     * currency sign, an accented character or an emoji is a good password, and
     * refusing it teaches people to pick a worse one.
     */
    private static boolean isSymbol(char c) {
        return !Character.isLetterOrDigit(c) && !Character.isWhitespace(c);
    }

    private PasswordPolicy() {
    }

    /**
     * @throws ApiException naming every rule the password misses, not just the
     *                      first. Somebody fixing one problem at a time, told
     *                      one problem at a time, tries four times.
     */
    public static void require(String password) {
        List<String> missing = whatIsMissing(password);
        if (missing.isEmpty()) {
            return;
        }
        throw new ApiException(ErrorCode.WEAK_PASSWORD,
                "Your password needs " + asAList(missing) + ".");
    }

    /** Empty when the password is acceptable. */
    public static List<String> whatIsMissing(String password) {
        String value = password == null ? "" : password;
        List<String> missing = new ArrayList<>();

        if (value.length() < MIN_LENGTH) {
            missing.add("at least %d characters".formatted(MIN_LENGTH));
        }
        if (value.chars().noneMatch(Character::isUpperCase)) {
            missing.add("a capital letter");
        }
        if (value.chars().noneMatch(Character::isLowerCase)) {
            missing.add("a small letter");
        }
        if (value.chars().noneMatch(Character::isDigit)) {
            missing.add("a number");
        }
        if (value.chars().noneMatch(c -> isSymbol((char) c))) {
            missing.add("a symbol like ! or @");
        }
        return List.copyOf(missing);
    }

    /** "a and b", "a, b and c" — a comma before "and" reads as another item. */
    private static String asAList(List<String> items) {
        if (items.size() == 1) {
            return items.get(0);
        }
        return String.join(", ", items.subList(0, items.size() - 1))
                + " and " + items.get(items.size() - 1);
    }
}
