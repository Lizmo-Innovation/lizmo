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
}
