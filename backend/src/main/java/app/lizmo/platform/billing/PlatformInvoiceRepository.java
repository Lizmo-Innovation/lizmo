package app.lizmo.platform.billing;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlatformInvoiceRepository extends JpaRepository<PlatformInvoice, UUID> {

    boolean existsByPropertyIdAndBillingDate(UUID propertyId, LocalDate billingDate);

    /** A landlord's invoices, newest month first. */
    List<PlatformInvoice> findByPropertyIdInOrderByBillingDateDesc(Collection<UUID> propertyIds);

    /** Everything still owed, for enforcement. */
    List<PlatformInvoice> findByStatusNot(PlatformInvoiceStatus status);

    /** Whether some other unpaid invoice is still holding a property locked. */
    boolean existsByPropertyIdAndLockedAtIsNotNullAndStatusNotAndIdNot(
            UUID propertyId, PlatformInvoiceStatus status, UUID invoiceId);
}
