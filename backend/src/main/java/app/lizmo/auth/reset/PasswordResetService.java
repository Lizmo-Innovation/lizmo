package app.lizmo.auth.reset;

import app.lizmo.auth.PasswordPolicy;
import app.lizmo.auth.RefreshTokenRepository;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.mail.Mailer;
import app.lizmo.user.User;
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
 * Getting back into an account.
 *
 * <p>A forgotten password used to be permanent — nothing in the app could
 * change one, so the only way back was editing the hash by hand.
 *
 * <p>Shaped like email verification, with two differences that matter. The
 * code lives half as long, because somebody resetting a password is doing it
 * now rather than filling in a form. And this endpoint never says whether an
 * account exists.
 */
@Service
public class PasswordResetService {

    /** Half the sign-up code's life. A reset is done in the next minute or not at all. */
    static final Duration LIFETIME = Duration.ofMinutes(15);

    static final int DIGITS = 6;

    static final int MAX_ATTEMPTS = 5;

    static final Duration RESEND_COOLDOWN = Duration.ofSeconds(60);

    /** In a day, to the same address. Somebody else's inbox is not a toy. */
    static final int MAX_PER_DAY = 5;

    private final PasswordResetRepository resets;
    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final Mailer mailer;
    private final PasswordEncoder encoder;
    private final SecureRandom random = new SecureRandom();
    private final Clock clock;

    public PasswordResetService(
            PasswordResetRepository resets,
            UserRepository users,
            RefreshTokenRepository refreshTokens,
            Mailer mailer,
            PasswordEncoder encoder,
            Clock clock) {
        this.resets = resets;
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.mailer = mailer;
        this.encoder = encoder;
        this.clock = clock;
    }

    /**
     * Sends a code, or quietly does not.
     *
     * <p>The answer is the same either way. Sign-up says plainly that an
     * address is taken, which is Ariel's call and a reasonable one — a
     * returning user has usually just forgotten they have an account. This
     * endpoint cannot afford the same courtesy, because the thing it does on
     * success is <em>send mail to somebody else's inbox</em>. An honest "no
     * such account" here would turn Lizmo into a way to test a list of
     * addresses against its own membership, one request at a time.
     *
     * <p>So an unknown address consumes its rate limit, returns the same
     * cooldown, and sends nothing.
     *
     * @return seconds until another can be asked for, so the screen counts down
     */
    @Transactional
    public int start(String rawEmail) {
        String email = normalise(rawEmail);

        // Before the account lookup, so the limits apply to an address whether
        // or not it exists -- otherwise how fast the endpoint refuses is
        // itself the answer.
        requireNotTooSoon(email);
        requireNotTooMany(email);

        String code = generate();
        Instant now = clock.instant();

        resets.findByEmailAndConsumedAtIsNull(email).ifPresent(previous -> {
            previous.consume();
            resets.saveAndFlush(previous);
        });

        // Written even when nobody is behind the address. The row is what
        // makes the rate limit real, and skipping it for unknown addresses
        // would let a stranger hammer this endpoint freely -- which is the
        // enumeration this method exists to prevent, arriving by another door.
        resets.save(new PasswordReset(email, encoder.encode(code), now.plus(LIFETIME), now));

        users.findByEmail(email)
                .filter(PasswordResetService::isResettable)
                .ifPresent(user -> mailer.sendPasswordResetCode(
                        email, user.getName(), code, (int) LIFETIME.toMinutes()));

        return (int) RESEND_COOLDOWN.toSeconds();
    }

    /**
     * Checks a code and sets the new password.
     *
     * <p>Expiry before correctness, as in sign-up: both orders refuse a
     * correct-but-expired code, but checking correctness first tells a guesser
     * "right code, too late", which confirms a real value after it lapses.
     *
     * <p>noRollbackFor is load-bearing. Every failure here throws, and a plain
     * transaction would roll back the attempt counter along with it — leaving
     * a cap that counts to one forever and never bites.
     *
     * @return the user, now holding the new password
     */
    @Transactional(noRollbackFor = ApiException.class)
    public User complete(String rawEmail, String code, String newPassword) {
        String email = normalise(rawEmail);

        PasswordReset reset = resets.findByEmailAndConsumedAtIsNull(email)
                .orElseThrow(() -> new ApiException(ErrorCode.OTP_NOT_FOUND,
                        "Ask for a code first."));

        if (reset.hasExpired(clock.instant())) {
            reset.consume();
            resets.save(reset);
            throw new ApiException(ErrorCode.OTP_EXPIRED,
                    "That code has expired. Ask for a new one.");
        }

        if (!encoder.matches(code, reset.getCodeHash())) {
            reset.recordAttempt();

            if (reset.getAttempts() >= MAX_ATTEMPTS) {
                reset.consume();
                resets.save(reset);
                throw new ApiException(ErrorCode.OTP_ATTEMPTS_EXHAUSTED,
                        "Too many wrong tries. Ask for a new code.");
            }

            resets.save(reset);
            int left = MAX_ATTEMPTS - reset.getAttempts();
            throw new ApiException(ErrorCode.OTP_INCORRECT,
                    "That code is not right. %d %s left."
                            .formatted(left, left == 1 ? "try" : "tries"));
        }

        // The code was right. Everything from here is about the account, and a
        // code correct for an address nobody holds is still spent: leaving it
        // live would let the same digits be tried again against an account
        // created a minute later.
        reset.consume();
        resets.save(reset);

        User user = users.findByEmail(email)
                .filter(PasswordResetService::isResettable)
                // Reached only by holding a code that was emailed to this
                // address, so nothing is disclosed by being specific here --
                // and a code that verifies against no account is a fault worth
                // naming rather than a silent success.
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND,
                        "That account is no longer available."));

        PasswordPolicy.require(newPassword);
        user.changePassword(encoder.encode(newPassword));

        // They have just read mail at this address. Somebody who signed up
        // before verification existed, or never finished it, has now proved
        // the thing verification asks for.
        if (user.getEmailVerifiedAt() == null) {
            user.markEmailVerified(clock.instant());
        }

        users.save(user);

        // The reason somebody resets a password is often that a stranger knows
        // the old one. Leaving that stranger's sessions alive would make the
        // reset cosmetic: their refresh token outlives the password it was
        // issued against.
        refreshTokens.deleteByUserId(user.getId());

        return user;
    }

    /**
     * A closed account cannot be reopened through the door marked "forgot".
     *
     * <p>Account deletion scrambles the password and moves the address to
     * {@code @deleted.invalid}, so nothing here could match it anyway — this is
     * the second lock on the same door, and cheap.
     */
    private static boolean isResettable(User user) {
        return user.isActive();
    }

    private void requireNotTooSoon(String email) {
        Optional<PasswordReset> latest =
                resets.findFirstByEmailOrderByCreatedAtDesc(email);
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
        long today = resets.countByEmailAndCreatedAtAfter(
                email, clock.instant().minus(Duration.ofDays(1)));
        if (today >= MAX_PER_DAY) {
            throw new ApiException(ErrorCode.OTP_TOO_MANY,
                    "That is enough codes for today. Try again tomorrow.");
        }
    }

    /** Zero-padded, so 004821 is as likely as 904821. */
    private String generate() {
        int bound = (int) Math.pow(10, DIGITS);
        return String.format("%0" + DIGITS + "d", random.nextInt(bound));
    }

    static String normalise(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }
}
