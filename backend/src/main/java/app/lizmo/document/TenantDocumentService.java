package app.lizmo.document;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.dto.TenantDocumentResponse;
import java.io.IOException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * The photographs a tenant uploads about themselves.
 *
 * <p>Every method takes the caller's id and works only on their own documents.
 * There is deliberately no way to read someone else's here: a landlord sees a
 * tenant's ID through a live lease, and that permission belongs with leases.
 * Until leases exist, nobody but the tenant can see these at all — which is the
 * safe direction for the gap to point.
 */
@Service
public class TenantDocumentService {

    /**
     * What a tenant can upload about themselves. VALID_ID and TENANT_PHOTO
     * only: a tenant has no business writing a LEASE_CONTRACT or a RECEIPT into
     * their own folder, and taking the type from the request without checking
     * would let them.
     */
    private static final Set<DocumentType> TENANT_UPLOADABLE =
            Set.of(DocumentType.VALID_ID, DocumentType.TENANT_PHOTO);

    /**
     * Long enough to load an image on a slow connection, short enough that a
     * URL which escapes into a log or a screenshot is worthless by the time
     * anyone finds it.
     */
    private static final Duration URL_LIFETIME = Duration.ofMinutes(10);

    /**
     * Refused before anything is decoded. Held here as well as in the servlet
     * container's own limit, because that one returns a container error rather
     * than something a client can read.
     */
    private static final long MAX_UPLOAD_BYTES = 10L * 1024 * 1024;

    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;

    public TenantDocumentService(
            StoredDocumentRepository documents,
            DocumentStore store,
            ImageNormaliser normaliser) {
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
    }

    @Transactional
    public TenantDocumentResponse upload(UUID userId, DocumentType docType, MultipartFile file) {
        if (!TENANT_UPLOADABLE.contains(docType)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A tenant can upload a VALID_ID or a TENANT_PHOTO.");
        }
        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "No file was uploaded.");
        }
        if (file.getSize() > MAX_UPLOAD_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file is larger than 10MB. Please upload a smaller photo.");
        }

        byte[] original = read(file);
        // Re-encoded to bare pixels before it is stored, so what lands in the
        // bucket has no EXIF, no GPS and no embedded thumbnail.
        byte[] normalised = normaliser.normalise(original);

        Optional<StoredDocument> existing = documents.findByOwnerTypeAndOwnerIdAndDocType(
                DocumentOwnerType.TENANT, userId, docType);

        // A fresh key every time rather than overwriting one. Presigned URLs
        // already handed out keep pointing at the old object until they expire,
        // so a tenant who replaces a blurred photo does not break the screen
        // someone is looking at — and the old object is then removed.
        String key = "tenants/%s/%s/%s.jpg".formatted(
                userId, docType.name().toLowerCase(), UUID.randomUUID());
        store.put(key, normalised, ImageNormaliser.OUTPUT_CONTENT_TYPE);

        StoredDocument saved;
        if (existing.isPresent()) {
            StoredDocument document = existing.get();
            String previousKey = document.getStorageKey();
            document.replaceWith(
                    key, ImageNormaliser.OUTPUT_CONTENT_TYPE, normalised.length, userId);
            saved = documents.save(document);
            store.delete(previousKey);
        } else {
            saved = documents.save(new StoredDocument(
                    DocumentOwnerType.TENANT,
                    userId,
                    userId,
                    docType,
                    key,
                    ImageNormaliser.OUTPUT_CONTENT_TYPE,
                    normalised.length));
        }

        return describe(saved);
    }

    /** The caller's own documents, each with a URL that expires. */
    @Transactional(readOnly = true)
    public List<TenantDocumentResponse> listMine(UUID userId) {
        List<TenantDocumentResponse> described = new ArrayList<>();
        for (StoredDocument document
                : documents.findByOwnerTypeAndOwnerId(DocumentOwnerType.TENANT, userId)) {
            described.add(describe(document));
        }
        return described;
    }

    /** Whether both photographs a lease needs are uploaded. */
    @Transactional(readOnly = true)
    public boolean hasBothPhotographs(UUID userId) {
        return has(userId, DocumentType.VALID_ID) && has(userId, DocumentType.TENANT_PHOTO);
    }

    /**
     * Whether one particular photograph is uploaded. Asked per kind so that
     * whatever refuses a lease can say which one is missing: "not ready" sends
     * a landlord back to the tenant with nothing useful to pass on.
     */
    @Transactional(readOnly = true)
    public boolean has(UUID userId, DocumentType kind) {
        return documents.findByOwnerTypeAndOwnerIdAndDocType(
                DocumentOwnerType.TENANT, userId, kind).isPresent();
    }

    private TenantDocumentResponse describe(StoredDocument document) {
        return new TenantDocumentResponse(
                document.getDocType(),
                store.presignedUrl(document.getStorageKey(), URL_LIFETIME),
                URL_LIFETIME.toSeconds(),
                document.getByteSize(),
                document.getUploadedAt());
    }

    private static byte[] read(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException e) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That upload did not arrive in one piece. Please try again.");
        }
    }
}
