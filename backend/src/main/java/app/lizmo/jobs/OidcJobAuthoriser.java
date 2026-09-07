package app.lizmo.jobs;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * The real gate: a Google-signed OIDC token from Cloud Scheduler.
 *
 * <p>Fails closed. With no service account configured this refuses everything,
 * because a job endpoint that defaults to open is worse than one that never
 * runs -- the second gets noticed.
 */
@Component
public class OidcJobAuthoriser implements JobAuthoriser {

    private static final Logger log = LoggerFactory.getLogger(OidcJobAuthoriser.class);

    private final JwtDecoder decoder;
    private final JobProperties properties;

    public OidcJobAuthoriser(JwtDecoder decoder, JobProperties properties) {
        this.decoder = decoder;
        this.properties = properties;
    }

    @Override
    public void requireScheduler(HttpServletRequest request) {
        if (!StringUtils.hasText(properties.serviceAccount())) {
            log.error("A job endpoint was called with no scheduler service account "
                    + "configured. Refusing.");
            throw notFound();
        }

        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            throw notFound();
        }

        try {
            Jwt token = decoder.decode(header.substring(7));

            // The signature only says Google issued it. Anybody with a Google
            // account can get one of those; the email is what says it was our
            // scheduler.
            String email = token.getClaimAsString("email");
            if (!properties.serviceAccount().equalsIgnoreCase(email)) {
                log.warn("A job endpoint was called by {}, which is not the scheduler.",
                        email);
                throw notFound();
            }
        } catch (ApiException already) {
            throw already;
        } catch (RuntimeException invalid) {
            // Audience and expiry are checked by the decoder, configured in
            // JobSecurityConfig.
            log.warn("A job endpoint was called with a token that did not verify.");
            throw notFound();
        }
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No such endpoint.");
    }
}
