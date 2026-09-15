package app.lizmo.paymentchannel;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.DocumentType;
import app.lizmo.document.ImageNormaliser;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import java.io.IOException;
import java.time.Duration;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

/**
 * The QR on a payment channel: stored, replaced, served and removed.
 *
 * <p>One per channel, replaced in place, so "which code do I scan" has one
 * answer. Re-encoded like every other image: a screenshot of a QR carries
 * whatever the phone that took it put in the EXIF.
 *
 * <p>Shared by Lizmo's channels and landlords' channels, which differ only in
 * who owns them.
 */
@Component
public class ChannelQrCodes {

    public static final Duration URL_LIFETIME = Duration.ofMinutes(10);

    private static final long MAX_UPLOAD_BYTES = 10L * 1024 * 1024;

    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;

    public ChannelQrCodes(
            StoredDocumentRepository documents, DocumentStore store, ImageNormaliser normaliser) {
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
    }

    /** Sets the QR, or replaces the one there was. */
    public void attach(DocumentOwnerType owner, UUID channelId, MultipartFile file, UUID uploadedBy) {
        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "That image was empty.");
        }
        if (file.getSize() > MAX_UPLOAD_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file is larger than 10MB. Please upload a smaller image.");
        }
        byte[] original;
        try {
            original = file.getBytes();
        } catch (IOException e) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That upload did not arrive in one piece. Please try again.");
        }

        byte[] normalised = normaliser.normalise(original);
        String key = "%s/%s/%s.jpg".formatted(folderFor(owner), channelId, UUID.randomUUID());
        store.put(key, normalised, ImageNormaliser.OUTPUT_CONTENT_TYPE);

        Optional<StoredDocument> existing = of(owner, channelId);
        if (existing.isPresent()) {
            StoredDocument qr = existing.get();
            String previous = qr.getStorageKey();
            qr.replaceWith(key, ImageNormaliser.OUTPUT_CONTENT_TYPE, normalised.length, uploadedBy);
            documents.save(qr);
            store.delete(previous);
        } else {
            documents.save(new StoredDocument(
                    owner,
                    channelId,
                    uploadedBy,
                    DocumentType.OTHER,
                    key,
                    ImageNormaliser.OUTPUT_CONTENT_TYPE,
                    normalised.length));
        }
    }

    /** A short-lived link to the QR, or null when the channel has none. */
    public String url(DocumentOwnerType owner, UUID channelId) {
        return of(owner, channelId)
                .map(qr -> store.presignedUrl(qr.getStorageKey(), URL_LIFETIME))
                .orElse(null);
    }

    /** Gone from storage as well as the database. Nothing to remove is fine. */
    public void remove(DocumentOwnerType owner, UUID channelId) {
        of(owner, channelId).ifPresent(qr -> {
            documents.delete(qr);
            store.delete(qr.getStorageKey());
        });
    }

    private Optional<StoredDocument> of(DocumentOwnerType owner, UUID channelId) {
        return documents.findByOwnerTypeAndOwnerId(owner, channelId).stream().findFirst();
    }

    private static String folderFor(DocumentOwnerType owner) {
        return owner == DocumentOwnerType.LANDLORD_PAYMENT_CHANNEL
                ? "landlord-payment-channels"
                : "payment-channels";
    }
}
