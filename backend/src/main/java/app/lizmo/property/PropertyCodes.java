package app.lizmo.property;

import java.security.SecureRandom;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;

/**
 * Mints and tidies the short code a tenant types or scans.
 *
 * <p>"PH" and then six characters from a 31-letter alphabet: about 900 million
 * codes, so exhausting them is not a concern even though none is ever reused.
 */
@Component
public class PropertyCodes {

    /** Says what these are at a glance, on a sign or in a group chat. */
    static final String PREFIX = "PH";

    /**
     * No 0/O, no 1/I/L. These codes are read aloud down a corridor, chalked on
     * a board by the gate, and typed by someone standing in the street with one
     * hand full — and those are the pairs people get wrong. Mirrors
     * chk_properties_code_shape.
     */
    static final String ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";

    static final int BODY_LENGTH = 6;

    /**
     * How many times to try before giving up. Only reachable if the ledger is
     * enormous or the generator is broken; failing loudly beats looping.
     */
    private static final int ATTEMPTS = 20;

    /**
     * SecureRandom rather than Random. A guessable code is a way to enumerate
     * other landlords' properties and their vacancies, so the sequence should
     * not be predictable from one code to the next.
     */
    private final SecureRandom random = new SecureRandom();

    private final IssuedPropertyCodeRepository issued;

    public PropertyCodes(IssuedPropertyCodeRepository issued) {
        this.issued = issued;
    }

    /**
     * A code no property has ever held, claimed in the ledger before it is
     * returned.
     *
     * <p>Claiming first is the point: the ledger, not the properties table, is
     * what makes a code spent for good. A code whose property is later deleted
     * stays claimed, so an old sticker on a gate can never come to mean
     * somebody else's building.
     */
    public String mint() {
        for (int attempt = 0; attempt < ATTEMPTS; attempt++) {
            String candidate = generate();
            if (issued.existsById(candidate)) {
                continue;
            }
            try {
                issued.saveAndFlush(new IssuedPropertyCode(candidate));
                return candidate;
            } catch (DataIntegrityViolationException raced) {
                // Two properties created in the same instant landed on the same
                // code. The primary key settled it; try again.
            }
        }
        throw new IllegalStateException(
                "Could not mint a free property code after " + ATTEMPTS + " attempts");
    }

    /**
     * What the tenant typed, made comparable: trimmed, upper-cased, and
     * stripped of the spaces and dashes people add when reading a code back.
     *
     * @return null if nothing usable is left, so callers can treat it the same
     *         as a code that matches nothing
     */
    public static String normalise(String typed) {
        if (typed == null) {
            return null;
        }
        String cleaned = typed.replaceAll("[\\s-]", "").toUpperCase();
        return cleaned.isEmpty() ? null : cleaned;
    }

    private String generate() {
        StringBuilder code = new StringBuilder(PREFIX);
        for (int i = 0; i < BODY_LENGTH; i++) {
            code.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        }
        return code.toString();
    }
}
