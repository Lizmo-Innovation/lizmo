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
}
