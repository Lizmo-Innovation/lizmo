package app.lizmo.jobs;

import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.util.StringUtils;

/**
 * Verifying Google's signature on a scheduler token.
 *
 * <p>The JWKS URI rather than a pinned key: Google rotates its signing keys,
 * and a pinned one works until the morning it does not. Nimbus fetches and
 * caches them.
 */
@Configuration
public class JobSecurityConfig {

    private static final org.slf4j.Logger log =
            org.slf4j.LoggerFactory.getLogger(JobSecurityConfig.class);

    private static final String GOOGLE_KEYS = "https://www.googleapis.com/oauth2/v3/certs";

    @Bean
    JwtDecoder googleJobTokenDecoder(JobProperties properties) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(GOOGLE_KEYS).build();

        List<OAuth2TokenValidator<org.springframework.security.oauth2.jwt.Jwt>> checks =
                new java.util.ArrayList<>(List.of(
                        new JwtTimestampValidator(),
                        JwtValidators.createDefaultWithIssuer("https://accounts.google.com")));

        // Audience when it is configured, and not otherwise.
        //
        // A service cannot read its own Cloud Run URL while it is being
        // created, so this is filled in on a second apply. Skipping it is a
        // weaker position, not an open door: the gate that matters is the
        // service account email, which only we control. This stops a token
        // minted for some other Google-fronted service being replayed here.
        if (StringUtils.hasText(properties.audience())) {
            checks.add(new JwtClaimValidator<List<String>>(JwtClaimNames.AUD,
                    audiences -> audiences != null
                            && audiences.contains(properties.audience())));
        } else {
            log.warn("No OIDC audience configured for job endpoints. The scheduler's "
                    + "service account is still checked. Set LIZMO_JOBS_AUDIENCE to "
                    + "the API's own URL to add the second check.");
        }

        decoder.setJwtValidator(
                new org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator<>(checks));

        return decoder;
    }
}
