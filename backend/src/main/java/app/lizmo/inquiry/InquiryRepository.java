package app.lizmo.inquiry;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InquiryRepository extends JpaRepository<Inquiry, UUID> {

    Optional<Inquiry> findByTenantIdAndPropertyId(UUID tenantId, UUID propertyId);

    /** A tenant's own threads, most recently active first. */
    List<Inquiry> findByTenantIdOrderByLastMessageAtDescCreatedAtDesc(UUID tenantId);

    /** Every thread on the properties a landlord owns. */
    List<Inquiry> findByPropertyIdInOrderByLastMessageAtDescCreatedAtDesc(
            Collection<UUID> propertyIds);
}
