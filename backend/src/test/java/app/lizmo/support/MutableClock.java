package app.lizmo.support;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;

/**
 * A clock a test can push forward.
 *
 * <p>Sign-up is full of rules measured in time — ten minutes, sixty seconds,
 * five a day — and none of them can be checked by waiting. Moving the clock
 * tests the rule; sleeping tests the test runner's patience.
 *
 * <p>Starts at the real time so that anything not deliberately moved behaves
 * normally, and resets between tests.
 */
public class MutableClock extends Clock {

    private Instant now = Instant.now();

    @Override
    public ZoneId getZone() {
        return ZoneId.of("UTC");
    }

    @Override
    public Clock withZone(ZoneId zone) {
        return this;
    }

    @Override
    public Instant instant() {
        return now;
    }

    /** Moves time on, the way waiting would. */
    public void advanceSeconds(long seconds) {
        now = now.plusSeconds(seconds);
    }

    public void advanceMinutes(long minutes) {
        advanceSeconds(minutes * 60);
    }

    public void advanceDays(long days) {
        advanceSeconds(days * 24 * 60 * 60);
    }

    /** Back to real time, so one test never inherits another's future. */
    public void reset() {
        now = Instant.now();
    }
}
