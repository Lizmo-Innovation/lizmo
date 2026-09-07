package app.lizmo.billing;

import static org.assertj.core.api.Assertions.assertThat;

import app.lizmo.lease.Lease;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * The calendar arithmetic behind rent, on its own.
 *
 * <p>Every awkward case in collecting rent is a date question — short months,
 * leap years, a tenancy that ended, a due day that does not exist in February
 * — and none of them need a database to get wrong. Kept as a plain unit test
 * so they can be asked quickly and all at once.
 */
class RentScheduleTest {

    private static Lease lease(String start, int dueDay, String end) {
        Lease lease = new Lease(
                UUID.randomUUID(),
                UUID.randomUUID(),
                null,
                new BigDecimal("2500.00"),
                (short) dueDay,
                LocalDate.parse(start),
                UUID.randomUUID());
        if (end != null) {
            lease.close(app.lizmo.lease.LeaseStatus.ENDED, LocalDate.parse(end));
        }
        return lease;
    }

    @Test
    void a_tenancy_owes_for_the_month_it_started() {
        List<RentSchedule.Month> months =
                RentSchedule.upTo(lease("2026-10-03", 3, null), LocalDate.parse("2026-10-10"));

        assertThat(months).hasSize(1);
        assertThat(months.get(0).label()).isEqualTo("October 2026");
        assertThat(months.get(0).start()).isEqualTo(LocalDate.parse("2026-10-03"));
        // The 3rd to the 2nd, not the 1st to the 31st. Both sides already think
        // of it that way, and a calendar month would invent a part month
        // nobody agreed to.
        assertThat(months.get(0).end()).isEqualTo(LocalDate.parse("2026-11-02"));
    }

    @Test
    void months_accumulate_as_they_begin() {
        assertThat(RentSchedule.upTo(
                lease("2026-10-03", 3, null), LocalDate.parse("2026-12-03")))
                .hasSize(3);
    }

    /** A tenant should not be looking at rent due in March while it is January. */
    @Test
    void a_month_that_has_not_started_is_not_owed() {
        List<RentSchedule.Month> months =
                RentSchedule.upTo(lease("2026-10-03", 3, null), LocalDate.parse("2026-11-02"));

        assertThat(months).hasSize(1);
    }

    @Test
    void a_tenancy_starting_later_owes_nothing_yet() {
        assertThat(RentSchedule.upTo(
                lease("2026-12-01", 1, null), LocalDate.parse("2026-10-10")))
                .isEmpty();
    }

    /**
     * Without this an ended tenancy would keep growing months for as long as
     * anybody kept opening the screen — a former tenant accruing rent for a
     * room they left.
     */
    @Test
    void an_ended_tenancy_stops_billing() {
        List<RentSchedule.Month> months = RentSchedule.upTo(
                lease("2026-10-03", 3, "2026-12-15"), LocalDate.parse("2027-06-01"));

        assertThat(months).hasSize(3);
        assertThat(months.get(2).start()).isEqualTo(LocalDate.parse("2026-12-03"));
    }

    // ---- when it falls due -------------------------------------------------

    @Test
    void rent_is_due_on_the_day_agreed() {
        assertThat(RentSchedule.dueDateFor(LocalDate.parse("2026-10-03"), (short) 5))
                .isEqualTo(LocalDate.parse("2026-10-05"));
    }

    /**
     * A lease due on the 31st is due on the 28th in February rather than on a
     * date that does not exist. The lease keeps the 31 it was given: clamping
     * on write would quietly change the agreement for every other month.
     */
    @Test
    void a_due_day_that_the_month_does_not_have_is_clamped() {
        assertThat(RentSchedule.dueDateFor(LocalDate.parse("2027-02-01"), (short) 31))
                .isEqualTo(LocalDate.parse("2027-02-28"));
    }

    @Test
    void february_in_a_leap_year_has_its_extra_day() {
        assertThat(RentSchedule.dueDateFor(LocalDate.parse("2028-02-01"), (short) 31))
                .isEqualTo(LocalDate.parse("2028-02-29"));
    }

    /**
     * Somebody moving in on the 20th with rent due on the 5th owes on the 5th
     * of the following month, not on a date two weeks before they arrived.
     */
    @Test
    void a_due_day_before_the_move_in_means_next_month() {
        assertThat(RentSchedule.dueDateFor(LocalDate.parse("2026-10-20"), (short) 5))
                .isEqualTo(LocalDate.parse("2026-11-05"));
    }

    @Test
    void the_last_day_of_a_long_month_still_works() {
        assertThat(RentSchedule.dueDateFor(LocalDate.parse("2026-01-31"), (short) 31))
                .isEqualTo(LocalDate.parse("2026-01-31"));
    }

    /**
     * A tenancy that started on the 31st. plusMonths lands on the 30th, the
     * 28th and back, which is the behaviour wanted -- and worth pinning,
     * because the alternative is a schedule that drifts a day earlier every
     * short month.
     */
    @Test
    void a_tenancy_starting_on_the_31st_does_not_drift() {
        List<RentSchedule.Month> months = RentSchedule.upTo(
                lease("2026-01-31", 31, null), LocalDate.parse("2026-04-30"));

        assertThat(months).extracting(RentSchedule.Month::start).containsExactly(
                LocalDate.parse("2026-01-31"),
                LocalDate.parse("2026-02-28"),
                // March is the 31st, not the 28th. Each month is computed from
                // the original start rather than from the month before, so a
                // short February does not pull every later month back with it.
                LocalDate.parse("2026-03-31"),
                LocalDate.parse("2026-04-30"));
    }
}
