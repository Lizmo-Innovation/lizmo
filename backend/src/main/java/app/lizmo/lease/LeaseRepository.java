package app.lizmo.lease;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LeaseRepository extends JpaRepository<Lease, UUID> {

    List<Lease> findByTenantIdOrderByStartDateDesc(UUID tenantId);

    List<Lease> findByUnitIdAndStatus(UUID unitId, LeaseStatus status);

    /** Tenancies across several units at once, for a whole property in one query. */
    List<Lease> findByUnitIdInAndStatus(Collection<UUID> unitIds, LeaseStatus status);

    /** Every lease a unit has ever held, ended ones included. */
    List<Lease> findByUnitId(UUID unitId);

    Optional<Lease> findByBedIdAndStatus(UUID bedId, LeaseStatus status);

    Optional<Lease> findByInquiryIdAndStatus(UUID inquiryId, LeaseStatus status);
}
