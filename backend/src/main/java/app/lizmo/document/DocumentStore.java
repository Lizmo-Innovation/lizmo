package app.lizmo.document;

import java.time.Duration;

/**
 * Where document bytes actually live.
 *
 * <p>An interface so that the tests that care about upload rules -- what is
 * accepted, what is stripped, who may read -- do not each need an S3 to run
 * against. One test exercises the real implementation; the rest use an
 * in-memory one and stay fast.
 */
public interface DocumentStore {

    /** Writes the bytes and returns nothing: the caller already knows the key. */
    void put(String key, byte[] bytes, String contentType);

    /**
     * A URL that will serve the object for {@code validFor} and then stop.
     *
     * <p>Short-lived on purpose. A tenant's ID is the most sensitive thing the
     * app holds, and a URL that works forever is one that can be forwarded,
     * logged, cached by a CDN, or pasted into a chat.
     */
    String presignedUrl(String key, Duration validFor);

    /** Removes the object. Missing is not an error: deleting twice is fine. */
    void delete(String key);
}
