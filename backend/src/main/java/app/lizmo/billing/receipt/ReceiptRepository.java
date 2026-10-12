package app.lizmo.billing.receipt;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface ReceiptRepository extends JpaRepository<Receipt, UUID> {

    List<Receipt> findByLeaseIdOrderByIssuedAtDescSequenceDesc(UUID leaseId);

    Optional<Receipt> findByPaymentId(UUID paymentId);

    List<Receipt> findByPaymentIdIn(Collection<UUID> paymentIds);

    /** Somebody who closed their account stops being named on their receipts. */
    @Modifying
    @Query("UPDATE Receipt r SET r.receivedFrom = :name WHERE r.tenantId = :userId")
    int renameTenant(UUID userId, String name);

    @Modifying
    @Query("UPDATE Receipt r SET r.receivedBy = :name WHERE r.landlordId = :userId")
    int renameLandlord(UUID userId, String name);
}
