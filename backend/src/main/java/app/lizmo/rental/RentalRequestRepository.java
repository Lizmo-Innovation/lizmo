package app.lizmo.rental;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RentalRequestRepository extends JpaRepository<RentalRequest, UUID> {

    List<RentalRequest> findByTenantIdOrderByCreatedAtDesc(UUID tenantId);

    Optional<RentalRequest> findByIdAndTenantId(UUID id, UUID tenantId);

    boolean existsByTenantIdAndBedIdAndStatus(
            UUID tenantId, UUID bedId, RentalRequestStatus status);

    boolean existsByTenantIdAndUnitIdAndBedIdIsNullAndStatus(
            UUID tenantId, UUID unitId, RentalRequestStatus status);
}
