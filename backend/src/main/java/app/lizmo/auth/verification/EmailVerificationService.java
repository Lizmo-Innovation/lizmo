package app.lizmo.auth.verification;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.mail.Mailer;
import app.lizmo.user.UserRepository;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Issuing and checking the code that proves somebody owns an address.
 *
 * <p>Everything protective about sign-up lives here: how long a code lasts, how
 * many guesses it takes, how often a new one can be asked for, and the fact
 * that it works exactly once.
 */
@Service
public class EmailVerificationService {

    /** Long enough to switch apps and read an email, short enough to matter. */
    static final Duration LIFETIME = Duration.ofMinutes(10);

    /**
     * Six digits is a million codes. Guessed freely that falls in minutes,
     * which is why the cap below exists rather than as well as it.
     */
    static final int DIGITS = 6;

    static final int MAX_ATTEMPTS = 5;

    /** Between two sends to the same address. Stops a resend button becoming a tap-tap-tap. */
    static final Duration RESEND_COOLDOWN = Duration.ofSeconds(60);

    /** In a day, to the same address. Somebody else's inbox is not a toy. */
    static final int MAX_PER_DAY = 5;

    private final EmailVerificationRepository verifications;
    private final UserRepository users;
    private final Mailer mailer;

    /**
     * The same encoder that hashes passwords. A verification code is a
     * short-lived secret and deserves the same treatment: the row is readable
     * by anyone with a backup or a support query.
     */
    private final PasswordEncoder encoder;

    private final SecureRandom random = new SecureRandom();

    /**
     * Injected so ten minutes, sixty seconds and five a day can be tested
     * without waiting for any of them.
     */
    private final Clock clock;

    public EmailVerificationService(
            EmailVerificationRepository verifications,
            UserRepository users,
            Mailer mailer,
            PasswordEncoder encoder,
            Clock clock) {
        this.verifications = verifications;
        this.users = users;
        this.mailer = mailer;
        this.encoder = encoder;
        this.clock = clock;
    }

    /**
     * Sends a code to an address nobody has registered yet.
     *
     * @return how many seconds until another can be asked for, so the screen
     *         can count down rather than guess
     */
    @Transactional
    public int start(String rawEmail) {
        String email = normalise(rawEmail);

        // Said plainly, on Ariel's call. It does tell a stranger the address is
        // registered; the alternative wastes a returning user's time on a code
        // that was never going to work, and they have almost always simply
        // forgotten they have an account.
        if (users.findByEmail(email).isPresent()) {
            throw new ApiException(ErrorCode.EMAIL_ALREADY_REGISTERED,
                    "That address already has an account. Sign in instead.");
        }

        requireNotTooSoon(email);
        requireNotTooMany(email);

        // Any live code for this address stops working now. "Send a new code"
        // has to mean the old one is dead, or two codes are valid at once and
        // the attempt cap counts the wrong one.
        verifications.findByEmailAndConsumedAtIsNull(email)
                .ifPresent(previous -> {
                    previous.consume();
                    verifications.saveAndFlush(previous);
                });

        String code = generate();
        Instant now = clock.instant();
        verifications.save(new EmailVerification(
                email, encoder.encode(code), now.plus(LIFETIME), now));

        mailer.sendVerificationCode(email, null, code, (int) LIFETIME.toMinutes());

        return (int) RESEND_COOLDOWN.toSeconds();
    }

    /**
     * Checks a code and uses it up.
     *
     * <p>Expiry before correctness, deliberately. Both orders refuse a
     * correct-but-expired code, but checking correctness first tells a guesser
     * "right code, too late" — which confirms a real value after it lapses.
     * This order tells them only that time passed.
     *
     * <p>noRollbackFor is load-bearing, not tidiness. Every failure here throws,
     * and a plain @Transactional rolls back the write that went with it — the
     * attempt counter, and the burning of an expired or exhausted code. The cap
     * would have counted to one forever and never bitten, which is the entire
     * protection this method exists to provide.
     *
     * @return the verified address, ready for an account to be built on
     */
    @Transactional(noRollbackFor = ApiException.class)
    public String consume(String rawEmail, String code) {
        String email = normalise(rawEmail);

        EmailVerification verification = verifications
                .findByEmailAndConsumedAtIsNull(email)
                .orElseThrow(() -> new ApiException(ErrorCode.OTP_NOT_FOUND,
                        "Ask for a code first."));

        if (verification.hasExpired(clock.instant())) {
            // Burned rather than left lying about, so the next request is a
            // clean start and the expired row does not block the index.
            verification.consume();
            verifications.save(verification);
            throw new ApiException(ErrorCode.OTP_EXPIRED,
                    "That code has expired. Ask for a new one.");
        }

        if (!encoder.matches(code, verification.getCodeHash())) {
            verification.recordAttempt();

            if (verification.getAttempts() >= MAX_ATTEMPTS) {
                verification.consume();
                verifications.save(verification);
                throw new ApiException(ErrorCode.OTP_ATTEMPTS_EXHAUSTED,
                        "Too many wrong tries. Ask for a new code.");
            }

            verifications.save(verification);
            int left = MAX_ATTEMPTS - verification.getAttempts();
            throw new ApiException(ErrorCode.OTP_INCORRECT,
                    "That code is not right. %d %s left."
                            .formatted(left, left == 1 ? "try" : "tries"));
        }

        // Used up on success, so the same digits never work twice.
        verification.consume();
        verifications.save(verification);
        return email;
    }

    private void requireNotTooSoon(String email) {
        Optional<EmailVerification> latest =
                verifications.findFirstByEmailOrderByCreatedAtDesc(email);
        if (latest.isEmpty()) {
            return;
        }

        Instant nextAllowed = latest.get().getCreatedAt().plus(RESEND_COOLDOWN);
        Instant now = clock.instant();
        if (now.isBefore(nextAllowed)) {
            long wait = Duration.between(now, nextAllowed).toSeconds() + 1;
            throw new ApiException(ErrorCode.OTP_TOO_SOON,
                    "Wait %d seconds before asking for another code.".formatted(wait));
        }
    }

    private void requireNotTooMany(String email) {
        long today = verifications.countByEmailAndCreatedAtAfter(
                email, clock.instant().minus(Duration.ofDays(1)));
        if (today >= MAX_PER_DAY) {
            // An open resend loop is unlimited mail, at Lizmo's cost, to any
            // address somebody cares to type.
            throw new ApiException(ErrorCode.OTP_TOO_MANY,
                    "That is enough codes for today. Try again tomorrow.");
        }
    }

    /** Zero-padded, so 004821 is as likely as 904821. */
    private String generate() {
        int bound = (int) Math.pow(10, DIGITS);
        return String.format("%0" + DIGITS + "d", random.nextInt(bound));
    }

    /**
     * Lower-cased and trimmed. Addresses are compared as typed otherwise, and
     * Ana@ would be a different person from ana@ — including to the check for
     * an existing account.
     */
    static String normalise(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }
}
