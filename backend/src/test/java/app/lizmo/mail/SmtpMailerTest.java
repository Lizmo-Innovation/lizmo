package app.lizmo.mail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.lizmo.common.ApiException;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import java.util.Properties;
import org.junit.jupiter.api.Test;
import org.springframework.mail.MailSendException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;

/**
 * What the verification email actually says.
 *
 * <p>No SMTP server anywhere near this. The message is built, captured, and
 * read — which is the part that can be wrong. Whether a socket opens is the
 * network's business and is proven by opening Mailpit, not by a unit test.
 */
class SmtpMailerTest {

    private final MailProperties properties = new MailProperties("Lizmo <hello@lizmo.local>");

    /** Captures the message instead of sending it. */
    private static final class CapturingSender extends JavaMailSenderImpl {
        MimeMessage captured;
        RuntimeException failWith;

        @Override
        public MimeMessage createMimeMessage() {
            return new MimeMessage(Session.getInstance(new Properties()));
        }

        @Override
        public void send(MimeMessage message) {
            if (failWith != null) {
                throw failWith;
            }
            captured = message;
        }
    }

    @Test
    void the_code_is_in_the_subject_and_the_body() throws Exception {
        CapturingSender sender = new CapturingSender();
        new SmtpMailer(sender, properties)
                .sendVerificationCode("ana@example.com", "Ana", "483920", 10);

        MimeMessage sent = sender.captured;
        // In the subject because on a locked phone that line is often all
        // somebody sees before they type it.
        assertThat(sent.getSubject()).isEqualTo("483920 is your Lizmo code");
        assertThat(body(sent)).contains("483920");
        assertThat(sent.getAllRecipients()[0].toString()).isEqualTo("ana@example.com");
    }

    @Test
    void it_says_how_long_the_code_lasts() throws Exception {
        CapturingSender sender = new CapturingSender();
        new SmtpMailer(sender, properties)
                .sendVerificationCode("ana@example.com", "Ana", "483920", 10);

        // Somebody who reads the email an hour later should know why it failed
        // before they try it.
        assertThat(body(sender.captured)).contains("10 minutes");
    }

    @Test
    void it_greets_somebody_whose_name_is_not_known_yet() throws Exception {
        CapturingSender sender = new CapturingSender();
        // At sign-up the address arrives before the name does.
        new SmtpMailer(sender, properties)
                .sendVerificationCode("ana@example.com", null, "483920", 10);

        assertThat(body(sender.captured)).contains("Hello,");
        assertThat(body(sender.captured)).doesNotContain("Hello null");
    }

    @Test
    void it_tells_a_stranger_that_nothing_has_happened() throws Exception {
        CapturingSender sender = new CapturingSender();
        new SmtpMailer(sender, properties)
                .sendVerificationCode("ana@example.com", "Ana", "483920", 10);

        // Most people who receive one of these unexpectedly are somebody else's
        // typo. They should be able to close it and forget it.
        assertThat(body(sender.captured)).contains("nothing has been created");
    }

    @Test
    void a_dead_relay_becomes_something_a_person_can_read() {
        CapturingSender sender = new CapturingSender();
        sender.failWith = new MailSendException("Connection refused");

        // Not a stack trace, and not an SMTP code. The person can try again.
        assertThatThrownBy(() -> new SmtpMailer(sender, properties)
                        .sendVerificationCode("ana@example.com", "Ana", "483920", 10))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("could not send the email");
    }

    private static String body(MimeMessage message) throws Exception {
        return message.getContent().toString();
    }
}
