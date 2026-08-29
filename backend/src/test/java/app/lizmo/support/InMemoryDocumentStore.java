package app.lizmo.support;

import app.lizmo.document.DocumentStore;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A DocumentStore that keeps bytes in a map.
 *
 * <p>So that tests about upload rules -- what is accepted, what is stripped,
 * who may read -- do not each need an S3 to run against. It also lets a test
 * assert on the bytes that were actually stored, which is the only way to prove
 * the EXIF is really gone rather than merely not requested.
 */
public class InMemoryDocumentStore implements DocumentStore {

    public record Stored(byte[] bytes, String contentType) {}

    private final Map<String, Stored> objects = new ConcurrentHashMap<>();

    @Override
    public void put(String key, byte[] bytes, String contentType) {
        objects.put(key, new Stored(bytes, contentType));
    }

    @Override
    public String presignedUrl(String key, Duration validFor) {
        // Shaped like the real thing, including an expiry, so a test can tell a
        // signed URL from a bare key.
        return "https://example-bucket.test/" + key + "?X-Amz-Expires=" + validFor.toSeconds();
    }

    @Override
    public void delete(String key) {
        objects.remove(key);
    }

    public Stored get(String key) {
        return objects.get(key);
    }

    public Map<String, Stored> all() {
        return new LinkedHashMap<>(objects);
    }

    public int size() {
        return objects.size();
    }

    /**
     * The bean is a singleton in a context shared by every test class, so a
     * test that counts objects has to start from nothing.
     */
    public void clear() {
        objects.clear();
    }
}
