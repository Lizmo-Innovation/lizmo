package app.lizmo.support;

import app.lizmo.mail.Mailer;
import java.util.ArrayList;
import java.util.List;

/**
 * A Mailer that keeps what it was asked to send instead of sending it.
 *
 * <p>So that no test reaches an SMTP server. What matters about an email here
 * is who it went to and what it said, and a real send proves neither — it only
 * proves the network works.
 */
public class RecordingMailer implements Mailer {

    public record Sent(String to, String name, String code, int validMinutes) {}

    private final List<Sent> sent = new ArrayList<>();

    /** Set to make the next send fail, the way a dead relay would. */
    public RuntimeException failWith;

    @Override
    public void sendVerificationCode(String to, String name, String code, int validMinutes) {
        if (failWith != null) {
            throw failWith;
        }
        sent.add(new Sent(to, name, code, validMinutes));
    }

    public List<Sent> all() {
        return List.copyOf(sent);
    }

    public Sent last() {
        if (sent.isEmpty()) {
            throw new AssertionError("No email was sent");
        }
        return sent.get(sent.size() - 1);
    }

    /** The code from the most recent email, which is what a person would type. */
    public String lastCode() {
        return last().code();
    }

    public int count() {
        return sent.size();
    }

    public void clear() {
        sent.clear();
        failWith = null;
    }
}
