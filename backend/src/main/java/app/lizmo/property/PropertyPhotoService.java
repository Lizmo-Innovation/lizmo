package app.lizmo.property;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.DocumentType;
import app.lizmo.document.ImageNormaliser;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.property.dto.PropertyPhoto;
import java.io.IOException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * Photographs of a place, as a landlord manages them and a stranger sees them.
 *
 * <p>Somebody holding a code used to get an address, a type, whatever the
 * landlord typed, and counts per floor. That is enough to rule a place out and
 * nowhere near enough to choose it, so anybody serious had to go and stand
 * outside three buildings. These are what let them shortlist first.
 *
 * <p>The only document type shown to somebody with no relationship to the
 * landlord. That is safe because the landlord chooses what goes in, and
 * because what is stored is re-encoded pixels: a phone photograph of a
 * boarding house carries the coordinates of somebody's home, and the
 * normaliser strips them on the way through.
 */
@Service
public class PropertyPhotoService {

    /**
     * Enough to show a place, few enough to scroll.
     *
     * <p>A landlord with thirty photographs has made a gallery nobody will
     * reach the end of, and every one of them is a presigned URL to mint on
     * every read of the vacancy screen.
     */
    public static final int MOST = 8;

    private static final long MAX_UPLOAD_BYTES = 10L * 1024 * 1024;

    /**
     * How long a photograph's URL lives.
     *
     * <p>Longer than an ID's: these are deliberately public, and a tenant
     * scrolling a list should not watch them expire underneath them.
     */
    private static final Duration URL_LIFE = Duration.ofHours(6);

    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;
    private final PropertyAccess access;

    public PropertyPhotoService(
            StoredDocumentRepository documents,
            DocumentStore store,
            ImageNormaliser normaliser,
            PropertyAccess access) {
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
        this.access = access;
    }

    @Transactional
    public PropertyPhoto add(UUID propertyId, UUID landlordId, MultipartFile file) {
        access.writable(propertyId, landlordId);

        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "No photo was uploaded.");
        }
        if (file.getSize() > MAX_UPLOAD_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file is larger than 10MB. Please upload a smaller photo.");
        }

        List<StoredDocument> already = ordered(propertyId);
        if (already.size() >= MOST) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A property can have %d photos. Remove one first.".formatted(MOST));
        }

        // Re-encoded to bare pixels before it is stored, so what lands in the
        // bucket has no EXIF, no GPS and no embedded thumbnail.
        byte[] normalised = normaliser.normalise(read(file));

        String key = "properties/%s/photos/%s.jpg".formatted(propertyId, UUID.randomUUID());
        store.put(key, normalised, ImageNormaliser.OUTPUT_CONTENT_TYPE);

        StoredDocument photo = new StoredDocument(
                DocumentOwnerType.PROPERTY,
                propertyId,
                landlordId,
                DocumentType.PROPERTY_PHOTO,
                key,
                ImageNormaliser.OUTPUT_CONTENT_TYPE,
                normalised.length);
        // Last in the row. The first photograph a landlord uploads becomes the
        // one that represents the place until they say otherwise.
        photo.movedTo(already.size());

        return describe(documents.save(photo));
    }

    /** The landlord's own view: every photograph, in order. */
    @Transactional(readOnly = true)
    public List<PropertyPhoto> listFor(UUID propertyId, UUID landlordId) {
        access.readable(propertyId, landlordId);
        return ordered(propertyId).stream().map(this::describe).toList();
    }

    /**
     * What a stranger with the code is shown.
     *
     * <p>Takes no landlord: this is read by whoever scanned the gate, and the
     * code is the only thing they hold. Permission is the code itself, as it
     * is for everything else on that screen.
     */
    @Transactional(readOnly = true)
    public List<String> urlsFor(UUID propertyId) {
        return ordered(propertyId).stream()
                .map(photo -> store.presignedUrl(photo.getStorageKey(), URL_LIFE))
                .toList();
    }

    @Transactional
    public void remove(UUID propertyId, UUID photoId, UUID landlordId) {
        // Reducible rather than writable: removing a photograph shrinks the
        // account, and a property behind on its Lizmo bill may still tidy up.
        access.reducible(propertyId, landlordId);

        StoredDocument photo = documents.findById(photoId)
                .filter(found -> found.getDocType() == DocumentType.PROPERTY_PHOTO)
                .filter(found -> found.getOwnerId().equals(propertyId))
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such photo."));

        documents.delete(photo);
        store.delete(photo.getStorageKey());

        // Closed up, so the order stays 0..n-1 and "the first one" keeps
        // meaning what it says.
        renumber(ordered(propertyId));
    }

    /**
     * Puts them in the given order, which is how the cover is chosen.
     *
     * <p>Every id, not a move: the phone knows the whole list it is showing,
     * and sending all of it makes two landlords reordering at once settle on
     * one answer rather than interleaving into nonsense.
     */
    @Transactional
    public List<PropertyPhoto> reorder(UUID propertyId, UUID landlordId, List<UUID> ids) {
        access.writable(propertyId, landlordId);

        List<StoredDocument> photos = ordered(propertyId);
        if (ids == null || ids.size() != photos.size()
                || !ids.stream().distinct().toList().equals(ids)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Send every photo once, in the order they should appear.");
        }

        List<StoredDocument> reordered = new ArrayList<>();
        for (UUID id : ids) {
            StoredDocument found = photos.stream()
                    .filter(photo -> photo.getId().equals(id))
                    .findFirst()
                    .orElseThrow(() -> new ApiException(
                            ErrorCode.VALIDATION_FAILED, "That photo is not on this property."));
            reordered.add(found);
        }

        renumber(reordered);
        return reordered.stream().map(this::describe).toList();
    }

    // ---- the parts -----------------------------------------------------------------

    private List<StoredDocument> ordered(UUID propertyId) {
        return documents
                .findByOwnerTypeAndOwnerId(DocumentOwnerType.PROPERTY, propertyId)
                .stream()
                .filter(photo -> photo.getDocType() == DocumentType.PROPERTY_PHOTO)
                // Uploaded order for anything written before an order existed.
                .sorted(Comparator
                        .comparing(StoredDocument::getSortOrder,
                                Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparing(StoredDocument::getUploadedAt))
                .toList();
    }

    private void renumber(List<StoredDocument> photos) {
        for (int position = 0; position < photos.size(); position++) {
            photos.get(position).movedTo(position);
            documents.save(photos.get(position));
        }
    }

    private PropertyPhoto describe(StoredDocument photo) {
        return new PropertyPhoto(
                photo.getId(),
                store.presignedUrl(photo.getStorageKey(), URL_LIFE),
                URL_LIFE.toSeconds(),
                photo.getSortOrder() == null ? 0 : photo.getSortOrder(),
                photo.getUploadedAt());
    }

    private static byte[] read(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException unreadable) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "That photo could not be read.");
        }
    }
}
