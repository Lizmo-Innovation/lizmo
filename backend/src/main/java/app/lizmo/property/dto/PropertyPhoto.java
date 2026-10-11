package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

/**
 * One photograph of a place.
 *
 * @param url            short-lived, like every other object URL the app hands
 *                       out. These are deliberately public, but a URL that
 *                       works forever is one that can be forwarded, logged and
 *                       cached long after the landlord took the photograph
 *                       down.
 * @param urlExpiresInSeconds so the phone can tell a stale URL from a missing
 *                       photograph rather than showing a broken image.
 * @param position       where it sits. Zero is the one that represents the
 *                       place.
 */
@Schema(description = "A photograph of a property")
public record PropertyPhoto(
        UUID id,
        String url,
        long urlExpiresInSeconds,
        int position,
        Instant uploadedAt) {
}
