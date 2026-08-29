package app.lizmo.document.dto;

import app.lizmo.document.DocumentType;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

/**
 * One of a tenant's photographs, with a URL that stops working.
 *
 * @param url          a presigned link, valid for {@code urlExpiresInSeconds}.
 *                     Not a stable address: it is signed per request and must
 *                     never be cached, stored, or shared. Ask again and get
 *                     another.
 * @param byteSize     of the stored JPEG, not of what was uploaded. The
 *                     original is re-encoded and usually much smaller.
 */
@Schema(description = "A photograph a tenant has uploaded about themselves")
public record TenantDocumentResponse(
        @Schema(example = "VALID_ID") DocumentType docType,
        String url,
        long urlExpiresInSeconds,
        Long byteSize,
        Instant uploadedAt) {
}
