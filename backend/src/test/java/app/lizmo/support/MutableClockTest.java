package app.lizmo.support;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

/**
 * The test clock, read in a zone other than its own.
 *
 * <p>Pinned to an evening in UTC that is already the next morning in Manila,
 * so this fails at any time of day if the zone is ignored -- not only
 * between midnight and eight, which is when the integration test that found
 * it used to.
 */
class MutableClockTest {

    private static final ZoneId MANILA = ZoneId.of("Asia/Manila");

    /** 16:30 on the 11th in UTC; half past midnight on the 12th in Manila. */
    private static final Instant LATE_IN_UTC = Instant.parse("2026-10-11T16:30:00Z");

    @Test
    void reads_in_utc_like_the_application_clock() {
        MutableClock clock = new MutableClock();
        clock.setTo(LATE_IN_UTC);

        assertThat(clock.getZone()).isEqualTo(ZoneId.of("UTC"));
        assertThat(LocalDate.now(clock)).isEqualTo(LocalDate.of(2026, 10, 11));
    }

    @Test
    void asked_for_a_zone_it_gives_that_zone() {
        MutableClock clock = new MutableClock();
        clock.setTo(LATE_IN_UTC);

        Clock manila = clock.withZone(MANILA);

        assertThat(manila.getZone()).isEqualTo(MANILA);
        assertThat(manila.instant()).isEqualTo(LATE_IN_UTC);
        assertThat(LocalDate.now(manila)).isEqualTo(LocalDate.of(2026, 10, 12));
    }

    /** A test that moves time must move it for code holding the zoned clock too. */
    @Test
    void the_zoned_clock_moves_with_it() {
        MutableClock clock = new MutableClock();
        clock.setTo(LATE_IN_UTC);
        Clock manila = clock.withZone(MANILA);

        clock.advanceDays(1);

        assertThat(manila.instant()).isEqualTo(LATE_IN_UTC.plusSeconds(24 * 60 * 60));
        assertThat(LocalDate.now(manila)).isEqualTo(LocalDate.of(2026, 10, 13));
    }

    @Test
    void reset_reaches_the_zoned_clock_as_well() {
        MutableClock clock = new MutableClock();
        clock.setTo(LATE_IN_UTC);
        Clock manila = clock.withZone(MANILA);

        clock.reset();

        assertThat(manila.instant()).isAfter(LATE_IN_UTC);
    }
}
