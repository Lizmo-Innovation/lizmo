package app.lizmo.mail;

/**
 * Sends the handful of emails Lizmo needs.
 *
 * <p>An interface so that nothing in a test reaches an SMTP server: the tests
 * that matter here are about what the message says and who it goes to, and a
 * real send proves neither.
 *
 * <p>Deliberately narrow. One method per thing Lizmo actually sends, rather
 * than a generic send(subject, body) that lets any caller invent a new email
 * without anybody noticing the wording.
 */
public interface Mailer {

    /**
     * The code somebody types to prove they own an address.
     *
     * @param name what to call them, or null when nobody has asked yet -- at
     *             sign-up the address arrives before the name does.
     */
    void sendVerificationCode(String to, String name, String code, int validMinutes);

    /**
     * Lizmo asking somebody to be a landlord.
     *
     * @param name  what to call them, or null when the admin did not say
     * @param link  where they go to accept
     * @param token the same thing the link ends in, carried separately because
     *              nothing registers a deep link yet -- until something does,
     *              tapping the link opens a browser and this is what can be
     *              pasted into the app instead
     */
    void sendLandlordInvitation(String to, String name, String link, String token, int validDays);
}
