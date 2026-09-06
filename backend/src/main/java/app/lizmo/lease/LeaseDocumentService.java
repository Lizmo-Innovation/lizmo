package app.lizmo.lease;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.DocumentType;
import app.lizmo.document.ImageNormaliser;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.lease.dto.LeaseDocumentResponse;
import java.io.IOException;
import java.time.Duration;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

/**
 * The paperwork a landlord keeps against a tenancy.
 *
 * <p>A signed contract, a deposit receipt, a clearance. Their records rather
 * than the tenant's — which is why they are attached to the lease and outlive
 * it, and why the landlord decides one at a time which of them the tenant may
 * also see.
 */
@Service
public class LeaseDocumentService {

    /** Long enough to open a PDF over a slow connection, short enough to be worthless if leaked. */
    private static final Duration URL_LIFETIME = Duration.ofMinutes(10);

    /**
     * Larger than a tenant's photograph allowance, because a scanned contract
     * is several pages and a phone photograph of paper is not small.
     */
    private static final long MAX_UPLOAD_BYTES = 20L * 1024 * 1024;

    /**
     * A cap on how much paperwork one tenancy can carry.
     *
     * <p>Not a storage worry at this size. It is there because an unbounded
     * list behind a single "add" button is how a screen becomes unusable and
     * how a bucket bill becomes a surprise.
     */
    static final int MAX_PER_LEASE = 20;

    /** What a landlord may file here. Not VALID_ID or TENANT_PHOTO: those are the tenant's own. */
    private static final Set<DocumentType> ALLOWED =
            Set.of(DocumentType.LEASE_CONTRACT, DocumentType.RECEIPT, DocumentType.OTHER);

    private static final String PDF_CONTENT_TYPE = "application/pdf";

    /** The first five bytes of every PDF ever written. */
    private static final byte[] PDF_MAGIC = {'%', 'P', 'D', 'F', '-'};

    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;
    private final LeasePaperworkAccess access;

    public LeaseDocumentService(
            StoredDocumentRepository documents,
            DocumentStore store,
            ImageNormaliser normaliser,
            LeasePaperworkAccess access) {
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
        this.access = access;
    }

    /**
     * Files a document against a lease.
     *
     * <p>Photographs are re-encoded to bare pixels, as everywhere else, so what
     * lands in the bucket carries no EXIF and no GPS. PDFs are stored as they
     * arrived: there is no equivalent scrub for them, and re-writing a signed
     * document to strip metadata would change the artefact somebody may later
     * have to rely on.
     */
    @Transactional
    public LeaseDocumentResponse upload(
            UUID leaseId,
            UUID landlordId,
            DocumentType docType,
            String label,
            boolean sharedWithTenant,
            MultipartFile file) {

        access.requireLandlord(leaseId, landlordId);

        if (!ALLOWED.contains(docType)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A lease can carry a LEASE_CONTRACT, a RECEIPT or OTHER. "
                            + "A tenant's ID and photograph belong to the tenant.");
        }
        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "No file was uploaded.");
        }
        if (file.getSize() > MAX_UPLOAD_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file is larger than 20MB. Please upload a smaller one.");
        }
        if (documents.countByOwnerTypeAndOwnerId(DocumentOwnerType.LEASE, leaseId)
                >= MAX_PER_LEASE) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This lease already has %d documents. Delete one before adding another."
                            .formatted(MAX_PER_LEASE));
        }

        byte[] original = read(file);

        // Sniffed rather than trusted. A browser's declared content type is
        // whatever the client felt like sending, and this decides whether the
        // bytes go through an image decoder.
        boolean isPdf = looksLikePdf(original);

        byte[] bytes;
        String contentType;
        String extension;
        if (isPdf) {
            bytes = original;
            contentType = PDF_CONTENT_TYPE;
            extension = "pdf";
        } else {
            bytes = normaliser.normalise(original);
            contentType = ImageNormaliser.OUTPUT_CONTENT_TYPE;
            extension = "jpg";
        }

        // A fresh key every time. Nothing here is replaced in place -- a lease
        // holds many documents and none of them is "the" anything.
        String key = "leases/%s/%s.%s".formatted(leaseId, UUID.randomUUID(), extension);
        store.put(key, bytes, contentType);

        StoredDocument document = new StoredDocument(
                DocumentOwnerType.LEASE,
                leaseId,
                landlordId,
                docType,
                key,
                contentType,
                bytes.length,
                sharedWithTenant);
        document.relabel(cleanLabel(label, docType));

        return describe(documents.save(document));
    }

    /** Everything filed against this lease, newest first. */
    @Transactional(readOnly = true)
    public List<LeaseDocumentResponse> forLandlord(UUID leaseId, UUID landlordId) {
        access.requireLandlord(leaseId, landlordId);
        return all(leaseId).stream().map(this::describe).toList();
    }

    /**
     * What the tenant is allowed to see, newest first.
     *
     * <p>Filtered here rather than by the caller. A rule about disclosure that
     * lives in a controller is a rule one new endpoint can forget.
     */
    @Transactional(readOnly = true)
    public List<LeaseDocumentResponse> forTenant(UUID leaseId, UUID tenantId) {
        access.requireTenant(leaseId, tenantId);
        return all(leaseId).stream()
                .filter(StoredDocument::isSharedWithTenant)
                .map(this::describe)
                .toList();
    }

    /** Changes the label, or who may see it. */
    @Transactional
    public LeaseDocumentResponse update(
            UUID leaseId,
            UUID documentId,
            UUID landlordId,
            String label,
            Boolean sharedWithTenant) {

        StoredDocument document = mine(leaseId, documentId, landlordId);

        if (StringUtils.hasText(label)) {
            document.relabel(label.trim());
        }
        if (sharedWithTenant != null) {
            document.shareWithTenant(sharedWithTenant);
        }

        return describe(documents.save(document));
    }

    /**
     * Removes it, bytes and row together.
     *
     * <p>The object goes first. A row without an object shows a broken link;
     * an object without a row is a file nobody can reach and nobody will ever
     * delete.
     */
    @Transactional
    public void delete(UUID leaseId, UUID documentId, UUID landlordId) {
        StoredDocument document = mine(leaseId, documentId, landlordId);
        store.delete(document.getStorageKey());
        documents.delete(document);
    }

    private StoredDocument mine(UUID leaseId, UUID documentId, UUID landlordId) {
        access.requireLandlord(leaseId, landlordId);

        return documents.findById(documentId)
                // Both checks matter: the second stops a document id from one
                // lease being used against another lease the caller happens to
                // own.
                .filter(candidate -> candidate.getOwnerType() == DocumentOwnerType.LEASE)
                .filter(candidate -> candidate.getOwnerId().equals(leaseId))
                .orElseThrow(() -> new ApiException(
                        ErrorCode.NOT_FOUND, "No such document."));
    }

    private List<StoredDocument> all(UUID leaseId) {
        return documents
                .findByOwnerTypeAndOwnerId(DocumentOwnerType.LEASE, leaseId).stream()
                .sorted(Comparator.comparing(
                        StoredDocument::getUploadedAt,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();
    }

    private LeaseDocumentResponse describe(StoredDocument document) {
        return LeaseDocumentResponse.of(
                document,
                store.presignedUrl(document.getStorageKey(), URL_LIFETIME),
                URL_LIFETIME.toSeconds());
    }

    /**
     * Something to show in a list.
     *
     * <p>A blank label would render as an empty row, so the kind stands in --
     * "Lease contract" is a worse name than one a person chose and a much
     * better one than nothing.
     */
    private static String cleanLabel(String label, DocumentType docType) {
        if (StringUtils.hasText(label)) {
            return label.trim();
        }
        return switch (docType) {
            case LEASE_CONTRACT -> "Lease contract";
            case RECEIPT -> "Receipt";
            default -> "Document";
        };
    }

    private static boolean looksLikePdf(byte[] bytes) {
        if (bytes.length < PDF_MAGIC.length) {
            return false;
        }
        for (int i = 0; i < PDF_MAGIC.length; i++) {
            if (bytes[i] != PDF_MAGIC[i]) {
                return false;
            }
        }
        return true;
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
