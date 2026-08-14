package app.lizmo.auth;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class LoginThrottleTest {

    private LoginThrottle throttle;

    @BeforeEach
    void setUp() {
        throttle = new LoginThrottle();
    }

    @Test
    void allows_attempts_up_to_the_identifier_limit() {
        for (int i = 0; i < LoginThrottle.MAX_PER_IDENTIFIER - 1; i++) {
            throttle.recordFailure("ana@example.com", "1.1.1.1");
            assertThat(throttle.isThrottled("ana@example.com", "1.1.1.1"))
                    .as("attempt %d should still be allowed", i + 1)
                    .isFalse();
        }
    }

    @Test
    void blocks_once_the_identifier_limit_is_reached() {
        for (int i = 0; i < LoginThrottle.MAX_PER_IDENTIFIER; i++) {
            throttle.recordFailure("ana@example.com", "1.1.1.1");
        }

        assertThat(throttle.isThrottled("ana@example.com", "1.1.1.1")).isTrue();
        assertThat(throttle.retryAfterSeconds("ana@example.com", "1.1.1.1")).isPositive();
    }

    @Test
    void one_account_being_locked_does_not_lock_another() {
        for (int i = 0; i < LoginThrottle.MAX_PER_IDENTIFIER; i++) {
            throttle.recordFailure("victim@example.com", "1.1.1.1");
        }

        // Otherwise anyone could lock a neighbour out of their own account.
        assertThat(throttle.isThrottled("someone-else@example.com", "2.2.2.2")).isFalse();
    }

    @Test
    void success_clears_the_identifier_bucket() {
        for (int i = 0; i < LoginThrottle.MAX_PER_IDENTIFIER - 1; i++) {
            throttle.recordFailure("ana@example.com", "1.1.1.1");
        }
        throttle.recordSuccess("ana@example.com");

        // Mistyping a few times then getting it right must not leave a penalty.
        for (int i = 0; i < LoginThrottle.MAX_PER_IDENTIFIER - 1; i++) {
            throttle.recordFailure("ana@example.com", "1.1.1.1");
        }
        assertThat(throttle.isThrottled("ana@example.com", "1.1.1.1")).isFalse();
    }

    @Test
    void password_spraying_across_accounts_trips_the_address_limit() {
        // Each account sees only one failure, so no per-identifier limit fires.
        for (int i = 0; i < LoginThrottle.MAX_PER_ADDRESS; i++) {
            throttle.recordFailure("victim" + i + "@example.com", "9.9.9.9");
        }

        assertThat(throttle.isThrottled("fresh-account@example.com", "9.9.9.9"))
                .as("the address should be blocked even for an untouched account")
                .isTrue();
    }

    @Test
    void success_does_not_clear_the_address_bucket() {
        for (int i = 0; i < LoginThrottle.MAX_PER_ADDRESS; i++) {
            throttle.recordFailure("victim" + i + "@example.com", "9.9.9.9");
        }
        throttle.recordSuccess("victim0@example.com");

        // One valid credential must not wipe the evidence of a spray.
        assertThat(throttle.isThrottled("another@example.com", "9.9.9.9")).isTrue();
    }

    @Test
    void identifiers_are_matched_case_insensitively() {
        for (int i = 0; i < LoginThrottle.MAX_PER_IDENTIFIER; i++) {
            throttle.recordFailure("Ana@Example.com", "1.1.1.1");
        }

        // Otherwise changing capitalisation would reset the counter.
        assertThat(throttle.isThrottled("ana@example.com", "1.1.1.1")).isTrue();
    }
}
