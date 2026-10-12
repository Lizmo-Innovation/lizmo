package app.lizmo.lease;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/** A lease's dates as somebody would say them: "31 August 2027". */
public final class LeaseDates {

    private static final DateTimeFormatter SPOKEN =
            DateTimeFormatter.ofPattern("d MMMM yyyy", Locale.ENGLISH);

    private LeaseDates() {
    }

    public static String spoken(LocalDate date) {
        return SPOKEN.format(date);
    }
}
