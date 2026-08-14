package app.lizmo.auth;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.stereotype.Component;

/**
 * Rate limits failed sign-in attempts.
 *
 * <p>Without this, a public login endpoint accepts unlimited password guesses:
 * an attacker with a leaked credential list can try every one of them against
 * every account at whatever rate they like.
 *
 * <p>Two independent buckets, because they stop different attacks:
 * <ul>
 *   <li><b>Per identifier</b> — someone hammering one account from many
 *       addresses. Locks that account's sign-in briefly.
 *   <li><b>Per client address</b> — someone spraying one common password across
 *       many accounts, which never trips a per-account limit.
 * </ul>
 *
 * <p>Only <em>failures</em> count. A successful sign-in clears the identifier's
 * bucket, so a person who mistypes twice and then succeeds is unaffected.
 *
 * <p>In-memory and per-instance, which is honest about its limits: with several
 * Cloud Run instances an attacker gets one bucket per instance. That still cuts
 * the attack rate by orders of magnitude, and the state is deliberately not in
 * Postgres — writing a row per failed guess is its own denial-of-service.
 * Moving to a shared store is worth doing when there is a reason to run more
 * than a couple of instances.
 */
@Component
public class LoginThrottle {

    /** Failures allowed against one identifier before it is locked out. */
    static final int MAX_PER_IDENTIFIER = 5;

    /** Failures allowed from one address before it is locked out. */
    static final int MAX_PER_ADDRESS = 20;

    static final Duration WINDOW = Duration.ofMinutes(15);

    private final Map<String, Attempts> byIdentifier = new ConcurrentHashMap<>();
    private final Map<String, Attempts> byAddress = new ConcurrentHashMap<>();

    /** True when this caller should be refused before the password is checked. */
    public boolean isThrottled(String identifier, String address) {
        return exceeded(byIdentifier, key(identifier), MAX_PER_IDENTIFIER)
                || exceeded(byAddress, key(address), MAX_PER_ADDRESS);
    }

    public void recordFailure(String identifier, String address) {
        record(byIdentifier, key(identifier));
        record(byAddress, key(address));
    }

    /**
     * Clears the identifier's bucket. The address bucket is left alone: one
     * valid credential should not wipe the evidence of nineteen failures
     * against other accounts from the same source.
     */
    public void recordSuccess(String identifier) {
        byIdentifier.remove(key(identifier));
    }

    /** Seconds until this caller may try again, for the Retry-After header. */
    public long retryAfterSeconds(String identifier, String address) {
        long identifierWait = waitFor(byIdentifier, key(identifier), MAX_PER_IDENTIFIER);
        long addressWait = waitFor(byAddress, key(address), MAX_PER_ADDRESS);
        return Math.max(Math.max(identifierWait, addressWait), 1);
    }

    private static String key(String raw) {
        return raw == null ? "" : raw.trim().toLowerCase();
    }

    private boolean exceeded(Map<String, Attempts> buckets, String key, int max) {
        Attempts attempts = buckets.get(key);
        if (attempts == null) {
            return false;
        }
        if (attempts.isExpired()) {
            buckets.remove(key);
            return false;
        }
        return attempts.count.get() >= max;
    }

    private void record(Map<String, Attempts> buckets, String key) {
        buckets.compute(key, (k, existing) ->
                (existing == null || existing.isExpired()) ? new Attempts() : existing.increment());
    }

    private long waitFor(Map<String, Attempts> buckets, String key, int max) {
        Attempts attempts = buckets.get(key);
        if (attempts == null || attempts.isExpired() || attempts.count.get() < max) {
            return 0;
        }
        return Duration.between(Instant.now(), attempts.firstSeen.plus(WINDOW)).toSeconds();
    }

    /**
     * A fixed window rather than a sliding one: simpler, and the worst case is
     * an attacker getting two windows' worth of attempts across a boundary,
     * which does not meaningfully change the economics.
     */
    private static final class Attempts {
        private final Instant firstSeen = Instant.now();
        private final AtomicInteger count = new AtomicInteger(1);

        Attempts increment() {
            count.incrementAndGet();
            return this;
        }

        boolean isExpired() {
            return Instant.now().isAfter(firstSeen.plus(WINDOW));
        }
    }
}
