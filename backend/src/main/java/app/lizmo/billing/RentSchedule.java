package app.lizmo.billing;

import app.lizmo.lease.Lease;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Working out which months a tenancy owes rent for.
 *
 * <p>Pure arithmetic on dates, deliberately separated from anything that
 * writes: every awkward case in rent collection is a calendar question, and
 * calendar questions are worth being able to test without a database.
 *
 * <p>Months run from the day the tenancy started, not from the first of the
 * month. Somebody who moved in on the 3rd owes for the 3rd to the 2nd, which
 * is how both sides already think about it and avoids inventing a part-month
 * nobody agreed to.
 */
public final class RentSchedule {

    private static final DateTimeFormatter LABEL =
            DateTimeFormatter.ofPattern("MMMM yyyy", Locale.ENGLISH);

    private RentSchedule() {
    }

    /**
     * Every month this tenancy has reached, oldest first.
     *
     * @param today the last day to generate up to. A period is created once its
     *              start has arrived and not before -- a tenant should not be
     *              looking at rent due in March while it is January.
     */
    public static List<Month> upTo(Lease lease, LocalDate today) {
        List<Month> months = new ArrayList<>();

        LocalDate start = lease.getStartDate();
        if (start == null || start.isAfter(today)) {
            // A tenancy starting next week owes nothing yet.
            return months;
        }

        // A tenancy that has ended stops billing on its last day, however long
        // ago that was. Without this, an ended lease would keep growing months
        // for as long as anybody kept opening the screen.
        LocalDate lastDay = lease.getEndDate() == null ? today
                : (lease.getEndDate().isBefore(today) ? lease.getEndDate() : today);

        for (int index = 0; ; index++) {
            LocalDate periodStart = start.plusMonths(index);
            if (periodStart.isAfter(lastDay)) {
                break;
            }
            months.add(new Month(
                    LABEL.format(periodStart),
                    periodStart,
                    start.plusMonths(index + 1L).minusDays(1),
                    dueDateFor(periodStart, lease.getDueDateDay()),
                    lease.getRentAmount()));

            // A tenancy cannot reasonably run past this, and an unbounded loop
            // over a corrupt start date would hang a request rather than fail.
            if (index > 600) {
                break;
            }
        }

        return months;
    }

    /**
     * The day rent falls due within a period.
     *
     * <p>Clamped to the length of the month, so a lease due on the 31st is due
     * on the 28th in February rather than on a date that does not exist. The
     * lease keeps the 31 it was given: clamping on write would quietly change
     * the agreement for every other month of the year.
     */
    static LocalDate dueDateFor(LocalDate periodStart, short dueDateDay) {
        YearMonth month = YearMonth.from(periodStart);
        int day = Math.min(Math.max(dueDateDay, 1), month.lengthOfMonth());
        LocalDate due = month.atDay(day);

        // A tenancy starting on the 20th with rent due on the 5th means the 5th
        // of the following month, not a date two weeks before they moved in.
        return due.isBefore(periodStart) ? due.plusMonths(1) : due;
    }

    /** One month of rent, before anything has been written down. */
    public record Month(
            String label,
            LocalDate start,
            LocalDate end,
            LocalDate due,
            java.math.BigDecimal amount) {
    }
}
