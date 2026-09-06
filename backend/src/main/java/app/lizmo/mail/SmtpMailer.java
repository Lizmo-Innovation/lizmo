package app.lizmo.mail;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

/**
 * The real thing: plain SMTP, whoever is on the other end.
 *
 * <p>Mailpit in development, a relay in production. Nothing here knows which,
 * which is the point -- changing provider is configuration.
 */
@Component
public class SmtpMailer implements Mailer {

    private static final Logger log = LoggerFactory.getLogger(SmtpMailer.class);

    private final JavaMailSender sender;
    private final MailProperties properties;

    public SmtpMailer(JavaMailSender sender, MailProperties properties) {
        this.sender = sender;
        this.properties = properties;
    }

    @Override
    public void sendVerificationCode(String to, String name, String code, int validMinutes) {
        String greeting = name == null || name.isBlank() ? "Hello," : "Hello " + name + ",";

        // Plain text. An HTML template is one more thing to keep in step with
        // the wording, and a six-digit code needs no layout -- it needs to be
        // readable in a notification preview, which is where most people will
        // read it.
        String body = """
                %s

                Your Lizmo code is %s

                It works for %d minutes, and only once. If you did not ask for
                it, somebody typed your address by mistake and you can ignore
                this -- nothing has been created.
                """.formatted(greeting, code, validMinutes);

        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, "UTF-8");
            helper.setFrom(properties.from());
            helper.setTo(to);
            // The code is in the subject as well: on a locked phone that line
            // is often all somebody has to see.
            helper.setSubject(code + " is your Lizmo code");
            helper.setText(body);
            sender.send(message);
        } catch (MailException | jakarta.mail.MessagingException e) {
            // Logged with the address but never the code, and the caller is
            // told something they can act on rather than an SMTP error.
            log.error("Could not send a verification code to {}", to, e);
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "We could not send the email just now. Please try again.");
        }
    }

    @Override
    public void sendPasswordResetCode(
            String to, String name, String code, int validMinutes) {
        String greeting = name == null || name.isBlank() ? "Hello," : "Hello " + name + ",";

        String body = """
                %s

                Your Lizmo password reset code is %s

                Enter it in the app to choose a new password. It works for %d
                minutes, and only once.

                If you did not ask to reset your password, somebody has your
                email address and is trying to get into your account. Your
                password has not changed and this code does nothing on its own
                -- but it is worth signing in to check nothing else has.
                """.formatted(greeting, code, validMinutes);

        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, "UTF-8");
            helper.setFrom(properties.from());
            helper.setTo(to);
            helper.setSubject(code + " is your Lizmo password reset code");
            helper.setText(body);
            sender.send(message);
        } catch (MailException | jakarta.mail.MessagingException e) {
            log.error("Could not send a password reset code to {}", to, e);
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "We could not send the email just now. Please try again.");
        }
    }

    @Override
    public void sendLandlordInvitation(
            String to, String name, String link, String token, int validDays) {
        String greeting = name == null || name.isBlank() ? "Hello," : "Hello " + name + ",";

        String body = """
                %s

                Lizmo has invited you to manage your rentals with us.

                Open this link to set up your landlord account:

                %s

                If the link does not open Lizmo, start the app and enter this
                invitation code instead:

                %s

                It works for %d days and only once. If you were not expecting
                this, you can ignore it -- nothing has been created.
                """.formatted(greeting, link, token, validDays);

        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, "UTF-8");
            helper.setFrom(properties.from());
            helper.setTo(to);
            helper.setSubject("You are invited to Lizmo as a landlord");
            helper.setText(body);
            sender.send(message);
        } catch (MailException | jakarta.mail.MessagingException e) {
            // The address is logged; the token never is. A log line is not a
            // place to leave a working key to a landlord account.
            log.error("Could not send a landlord invitation to {}", to, e);
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "We could not send the email just now. Please try again.");
        }
    }
}
