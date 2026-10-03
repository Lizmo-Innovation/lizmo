package app.lizmo.inquiry;

/** Where a conversation has got to. Mirrors chk_inquiries_status. */
public enum InquiryStatus {

    /** Live. Either side can write.	*/
    OPEN,

    /**
     * Over, from either end.
     *
     * <p>One state rather than "declined" and "withdrawn": which of the two it
     * was mattered to the database and to nobody else. Whoever closed it can
     * say why in the thread, which is a sentence a person wrote rather than a
     * status somebody has to interpret.
     */
    CLOSED,

    /** A tenancy came out of it, and the two carry on talking in it. */
    LEASED
}
