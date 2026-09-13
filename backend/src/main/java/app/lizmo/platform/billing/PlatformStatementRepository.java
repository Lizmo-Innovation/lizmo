package app.lizmo.platform.billing;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface PlatformStatementRepository extends JpaRepository<PlatformStatement, UUID> {

    boolean existsByLandlordIdAndBillingDate(UUID landlordId, LocalDate billingDate);

    /** A landlord's own, newest month first. */
    List<PlatformStatement> findByLandlordIdOrderByBillingDateDesc(UUID landlordId);

    /** Everything still owed, for enforcement. */
    List<PlatformStatement> findByStatusNot(PlatformStatementStatus status);

    /**
     * The next invoice number, from the sequence.
     *
     * <p>A sequence rather than counting rows: two statements settled in the
     * same second would otherwise be handed the same number, and an invoice
     * number that is not unique is worse than none.
     */
    @Query(value = "SELECT nextval('platform_invoice_number_seq')", nativeQuery = true)
    long nextInvoiceNumber();
}
