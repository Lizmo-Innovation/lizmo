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

    /**
     * Whether the tenant may see this. Meaningful only for lease attachments.
     *
     * <p>A tenant's own photographs are theirs already, so the flag says
     * nothing about them and is left false. On a lease attachment it is the
     * difference between the signed contract -- which is as much the tenant's
     * as the landlord's -- and a clearance the landlord chased down for their
     * own file.
     */
    @Column(name = "shared_with_tenant", nullable = false)
    private boolean sharedWithTenant;

    /**
     * Where this sits among the others, for the kinds of attachment that have
     * an order. Null for paperwork, which has none.
     *
     * <p>Photographs have one because the first is the one that represents the
     * place, and a landlord should be able to choose it.
     */
    @Column(name = "sort_order")
    private Integer sortOrder;

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
        this(ownerType, ownerId, uploadedBy, docType, storageKey, contentType,
                byteSize, false);
    }

    public StoredDocument(
            DocumentOwnerType ownerType,
            UUID ownerId,
            UUID uploadedBy,
            DocumentType docType,
            String storageKey,
            String contentType,
            long byteSize,
            boolean sharedWithTenant) {
        this.sharedWithTenant = sharedWithTenant;
        this.ownerType = ownerType;
        this.ownerId = ownerId;
        this.uploadedBy = uploadedBy;
        this.docType = docType;
        this.storageKey = storageKey;
        this.contentType = contentType;
        this.byteSize = byteSize;
    }

    public void movedTo(int position) {
        this.sortOrder = position;
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

    public Integer getSortOrder() {
        return sortOrder;
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

    public boolean isSharedWithTenant() {
        return sharedWithTenant;
    }

    /**
     * Changes who may see it.
     *
     * <p>Named rather than a setter because it is a disclosure decision, not a
     * field: turning it on shows a document to somebody who could not see it a
     * moment ago.
     */
    public void shareWithTenant(boolean shared) {
        this.sharedWithTenant = shared;
    }

    /** Renames it. The label is what a person recognises the file by. */
    public void relabel(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
