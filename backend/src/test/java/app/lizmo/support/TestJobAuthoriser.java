package app.lizmo.support;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.jobs.JobAuthoriser;
import jakarta.servlet.http.HttpServletRequest;

/**
 * Stands in for the Google OIDC check.
 *
 * <p>Verifying a real token would need the network and a Google service
 * account, and what these tests are about is what a job does once it is
 * allowed to run -- plus that it refuses when it is not.
 */
public class TestJobAuthoriser implements JobAuthoriser {

    /** The word a test uses to say "this is the scheduler". */
    public static final String PASSWORD = "the-scheduler";

    @Override
    public void requireScheduler(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header == null || !header.equals("Bearer " + PASSWORD)) {
            // The same 404 the real one gives: an unauthenticated caller
            // learns nothing about which internal paths exist.
            throw new ApiException(ErrorCode.NOT_FOUND, "No such endpoint.");
        }
    }
}
