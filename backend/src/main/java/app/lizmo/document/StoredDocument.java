package app.lizmo.document;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * A file held in object storage, and the row that knows what it is.
 *
 * <p>Named StoredDocument rather than Document because java.sql and the XML
 * APIs both ship a Document, and an import collision in a persistence class is
 * a bad place to spend attention.
 *
 * <p>What is stored is the storage key, never a URL. Objects are private and
 * reached through presigned URLs valid for minutes; anything durable enough to
 * put in a column would be durable enough to leak.
 */
@Entity
@Table(name = "documents")
public class StoredDocument {

    @Id
    @GeneratedValue
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "owner_type", nullable = false)
    private DocumentOwnerType ownerType;

    @Column(name = "owner_id", nullable = false)
    private UUID ownerId;

    @Column(name = "uploaded_by", nullable = false)
    private UUID uploadedBy;

    @Enumerated(EnumType.STRING)
    @Column(name = "doc_type", nullable = false)
    private DocumentType docType;

    @Column(name = "storage_key", nullable = false)
    private String storageKey;

    private String label;

    @Column(name = "content_type")
    private String contentType;

    @Column(name = "byte_size")
    private Long byteSize;

    @Column(name = "uploaded_at", nullable = false)
    private Instant uploadedAt;

    protected StoredDocument() {
    }

    public StoredDocument(
            DocumentOwnerType ownerType,
            UUID ownerId,
            UUID uploadedBy,
            DocumentType docType,
            String storageKey,
            String contentType,
            long byteSize) {
        this.ownerType = ownerType;
        this.ownerId = ownerId;
        this.uploadedBy = uploadedBy;
        this.docType = docType;
        this.storageKey = storageKey;
        this.contentType = contentType;
        this.byteSize = byteSize;
    }

    /**
     * Points this row at a new object.
     *
     * <p>Replacing in place rather than inserting a second row: one current ID
     * and one current photograph per tenant is a rule the database enforces,
     * and two rows would make "the tenant's ID" a question with two answers.
     */
    public void replaceWith(String storageKey, String contentType, long byteSize, UUID uploadedBy) {
        this.storageKey = storageKey;
        this.contentType = contentType;
        this.byteSize = byteSize;
        this.uploadedBy = uploadedBy;
        this.uploadedAt = Instant.now();
    }

    @PrePersist
    void stampUploadedAt() {
        if (uploadedAt == null) {
            uploadedAt = Instant.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public DocumentOwnerType getOwnerType() {
        return ownerType;
    }

    public UUID getOwnerId() {
        return ownerId;
    }

    public UUID getUploadedBy() {
        return uploadedBy;
    }

    public DocumentType getDocType() {
        return docType;
    }

    public String getStorageKey() {
        return storageKey;
    }

    public String getContentType() {
        return contentType;
    }

    public Long getByteSize() {
        return byteSize;
    }

    public Instant getUploadedAt() {
        return uploadedAt;
    }
}
