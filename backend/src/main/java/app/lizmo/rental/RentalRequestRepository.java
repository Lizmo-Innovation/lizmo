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

    /** A live ask about the place itself, with no room named. */
    boolean existsByTenantIdAndPropertyIdAndUnitIdIsNullAndStatus(
            UUID tenantId, UUID propertyId, RentalRequestStatus status);

    boolean existsByTenantIdAndUnitIdAndBedIdIsNullAndStatus(
            UUID tenantId, UUID unitId, RentalRequestStatus status);

    /**
     * One property's queue, oldest first.
     *
     * <p>Oldest first, unlike the tenant's own list of what they have sent: a
     * queue of people waiting is answered in the order they joined it, and
     * putting the newest at the top would quietly reward whoever asked last.
     */
    List<RentalRequest> findByPropertyIdAndStatusOrderByCreatedAtAsc(
            UUID propertyId, RentalRequestStatus status);

    /**
     * Every property's queue at once, oldest first across all of them, for a
     * landlord who should not have to open each building to see who is asking.
     */
    List<RentalRequest> findByPropertyIdInAndStatusOrderByCreatedAtAsc(
            java.util.Collection<UUID> propertyIds, RentalRequestStatus status);

    /** Everything ever asked about one property, newest first. */
    List<RentalRequest> findByPropertyIdOrderByCreatedAtDesc(UUID propertyId);
}
