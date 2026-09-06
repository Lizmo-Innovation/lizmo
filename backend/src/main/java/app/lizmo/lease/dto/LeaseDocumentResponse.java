package app.lizmo.lease.dto;

import app.lizmo.document.DocumentType;
import app.lizmo.document.StoredDocument;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

/**
 * One piece of paperwork attached to a lease.
 *
 * <p>Unlike a tenant's photographs, these have ids and labels: a lease may
 * carry several, they are not one-per-kind, and "the contract" and "the
 * barangay clearance" are told apart by what somebody called them.
 *
 * @param url a presigned link, valid for {@code urlExpiresInSeconds}. Not a
 *            stable address: signed per request, never to be cached or shared.
 *            Ask again and get another.
 * @param sharedWithTenant whether the tenant can see this one. Always true in
 *                         what a tenant is served -- they are only ever sent
 *                         the shared ones -- and meaningful to the landlord,
 *                         who chose it.
 * @param contentType what was uploaded. A photograph is stored as JPEG; a PDF
 *                    is stored as it arrived, so the app knows which to render
 *                    as an image and which to hand to a PDF viewer.
 */
@Schema(description = "A document attached to a lease")
public record LeaseDocumentResponse(
        UUID id,
        @Schema(example = "LEASE_CONTRACT") DocumentType docType,
        String label,
        String url,
        long urlExpiresInSeconds,
        String contentType,
        Long byteSize,
        boolean sharedWithTenant,
        Instant uploadedAt) {

    public static LeaseDocumentResponse of(
            StoredDocument document, String url, long urlExpiresInSeconds) {
        return new LeaseDocumentResponse(
                document.getId(),
                document.getDocType(),
                document.getLabel(),
                url,
                urlExpiresInSeconds,
                document.getContentType(),
                document.getByteSize(),
                document.isSharedWithTenant(),
                document.getUploadedAt());
    }
}
