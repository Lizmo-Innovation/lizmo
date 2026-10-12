package app.lizmo.lease;

/**
 * How far along the warnings about a lease's end date have got.
 *
 * <p>In order: a later one is never followed by an earlier one, and the job
 * goes straight to whichever is due -- a date set five days out gets the
 * week's warning, never a stale "a month left".
 */
public enum TermWarning {

    /** About a month out, to both of them. */
    MONTH,

    /** The last week, to both of them. */
    WEEK,

    /** The date has gone by and nobody has done anything: the landlord only. */
    PASSED
}
