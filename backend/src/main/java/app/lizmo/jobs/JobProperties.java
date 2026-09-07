package app.lizmo.jobs;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Who may run background jobs, and what token they must present.
 *
 * @param serviceAccount the scheduler's service account email. Blank refuses
 *                       every job, which is the safe default: an endpoint that
 *                       defaults to open is worse than one that never runs.
 * @param audience what the OIDC token must be addressed to -- the Cloud Run
 *                 service URL. Without this a token minted for any other
 *                 service would pass.
 */
@ConfigurationProperties(prefix = "lizmo.jobs")
public record JobProperties(String serviceAccount, String audience) {
}
