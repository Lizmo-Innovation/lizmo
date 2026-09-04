package app.lizmo.mail;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * @param from what appears in the recipient's inbox. Set per environment: a
 *             lizmo.local address is fine for a mail catcher and would be
 *             rejected outright by a real relay.
 */
@ConfigurationProperties(prefix = "lizmo.mail")
public record MailProperties(String from) {}
