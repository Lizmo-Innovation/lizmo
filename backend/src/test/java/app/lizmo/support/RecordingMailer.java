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

    /** What an invited landlord received. The token is what they would paste. */
    public record Invitation(
            String to, String name, String link, String token, int validDays) {}

    private final List<Sent> sent = new ArrayList<>();
    private final List<Invitation> invitations = new ArrayList<>();

    /** Set to make the next send fail, the way a dead relay would. */
    public RuntimeException failWith;

    @Override
    public void sendVerificationCode(String to, String name, String code, int validMinutes) {
        if (failWith != null) {
            throw failWith;
        }
        sent.add(new Sent(to, name, code, validMinutes));
    }

    @Override
    public void sendLandlordInvitation(
            String to, String name, String link, String token, int validDays) {
        if (failWith != null) {
            throw failWith;
        }
        invitations.add(new Invitation(to, name, link, token, validDays));
    }

    public List<Invitation> allInvitations() {
        return List.copyOf(invitations);
    }

    public Invitation lastInvitation() {
        if (invitations.isEmpty()) {
            throw new AssertionError("No invitation was sent");
        }
        return invitations.get(invitations.size() - 1);
    }

    /** The token from the most recent invitation, which is what a person would use. */
    public String lastInvitationToken() {
        return lastInvitation().token();
    }

    public int invitationCount() {
        return invitations.size();
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
        invitations.clear();
        failWith = null;
    }
}
