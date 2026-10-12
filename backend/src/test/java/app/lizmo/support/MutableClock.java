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
 *
 * <p>Reads in UTC, like the clock the application runs on. Asked for another
 * zone it gives one -- the same instant, moving when this one moves. It used
 * to hand back itself, still in UTC, so code asking for the server's local
 * date got the UTC one under test: between midnight and eight in Manila the
 * two are different days, and a test comparing against the local date failed
 * every night.
 */
public class MutableClock extends Clock {

    private Instant now = Instant.now();

    @Override
    public ZoneId getZone() {
        return ZoneId.of("UTC");
    }

    @Override
    public Clock withZone(ZoneId zone) {
        return new Zoned(this, zone);
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

    /** A particular moment, for a test about one. */
    public void setTo(Instant instant) {
        now = instant;
    }

    /** Back to real time, so one test never inherits another's future. */
    public void reset() {
        now = Instant.now();
    }

    /** This clock read in another zone. Holds no time of its own. */
    private static final class Zoned extends Clock {

        private final MutableClock source;
        private final ZoneId zone;

        private Zoned(MutableClock source, ZoneId zone) {
            this.source = source;
            this.zone = zone;
        }

        @Override
        public ZoneId getZone() {
            return zone;
        }

        @Override
        public Clock withZone(ZoneId other) {
            return source.withZone(other);
        }

        @Override
        public Instant instant() {
            return source.instant();
        }
    }
}
