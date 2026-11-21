package app.lizmo.document;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StoredDocumentRepository extends JpaRepository<StoredDocument, UUID> {

    Optional<StoredDocument> findByOwnerTypeAndOwnerIdAndDocType(
            DocumentOwnerType ownerType, UUID ownerId, DocumentType docType);

    List<StoredDocument> findByOwnerTypeAndOwnerId(DocumentOwnerType ownerType, UUID ownerId);

    /** Every document of one kind of owner, for the retention sweep. */
    List<StoredDocument> findByOwnerType(DocumentOwnerType ownerType);

    /** Everything a set of owners carries, in one query: a thread's messages. */
    List<StoredDocument> findByOwnerTypeAndOwnerIdIn(
            DocumentOwnerType ownerType, java.util.Collection<UUID> ownerIds);

    /** What one person uploaded of one kind, for closing their account. */
    List<StoredDocument> findByOwnerTypeAndUploadedBy(DocumentOwnerType ownerType, UUID uploadedBy);

    /** For the cap on how much paperwork one lease may carry. */
    long countByOwnerTypeAndOwnerId(DocumentOwnerType ownerType, UUID ownerId);
}
