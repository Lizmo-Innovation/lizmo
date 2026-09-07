package app.lizmo.jobs;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Who is allowed to run a background job.
 *
 * <p>An interface for the same reason DocumentStore and Mailer are: the real
 * implementation verifies a Google OIDC token against Google's public keys,
 * which no test should need the network for.
 *
 * <p>Being on /internal/ is not itself protection. The Cloud Run service is
 * reachable by anyone -- the apps call it -- so these paths are as public as
 * any other and have to be defended in the application.
 */
public interface JobAuthoriser {

    /**
     * @throws app.lizmo.common.ApiException if this is not the scheduler.
     *         404 rather than 403: an unauthenticated caller learns nothing
     *         about which internal paths exist.
     */
    void requireScheduler(HttpServletRequest request);
}
