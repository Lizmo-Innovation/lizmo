package app.lizmo.user;

import java.time.LocalDate;
import java.time.Period;

/**
 * How old somebody is, worked out on the server.
 *
 * <p>Here rather than in the app because a birthday is a date and an age is a
 * subtraction that goes wrong quietly — leap years, time zones, a phone whose
 * clock is a day out. The landlord reads the answer, not the sum, and two
 * screens showing the same person one year apart would be worse than either.
 */
public final class Age {

    private Age() {
    }

    /**
     * Years completed, not years begun. Null when no birthday was given.
     *
     * <p>Period rather than a subtraction of years: somebody born on the 30th
     * of December is not a year older on the 1st of January, and that is the
     * mistake the arithmetic version makes for two days out of every 365.
     */
    public static Integer on(LocalDate birthdate, LocalDate today) {
        if (birthdate == null || today == null || birthdate.isAfter(today)) {
            return null;
        }
        return Period.between(birthdate, today).getYears();
    }
}
