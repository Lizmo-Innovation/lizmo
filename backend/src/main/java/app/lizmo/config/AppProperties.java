package app.lizmo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Where Lizmo lives, as far as anything it sends out is concerned.
 *
 * @param inviteBaseUrl what an invitation link points at. There is no domain
 *                      yet, so this is configured rather than hard-coded: it
 *                      can be a LAN address while Ariel tests on two phones,
 *                      and a real host later, without touching code.
 *
 *                      <p>Until the apps register a deep link, tapping it will
 *                      open a browser rather than Lizmo. The email carries the
 *                      token in text as well for that reason, so it can be
 *                      pasted into the app in the meantime.
 */
@ConfigurationProperties(prefix = "lizmo.app")
public record AppProperties(String inviteBaseUrl) {

    /** The link that goes in the email. */
    public String inviteLink(String token) {
        String base = inviteBaseUrl == null ? "" : inviteBaseUrl;
        return base.endsWith("/") ? base + token : base + "/" + token;
    }
}
