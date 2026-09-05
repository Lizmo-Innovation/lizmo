package app.lizmo.property;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PropertyRepository extends JpaRepository<Property, UUID> {

    /**
     * A landlord's own properties. Every listing goes through this rather than
     * findAll, so forgetting the scope is not possible by omission.
     */
    List<Property> findByLandlordIdOrderByNameAsc(UUID landlordId);

    /**
     * By the code a tenant typed or scanned. Not scoped to a landlord — this is
     * the one lookup that deliberately crosses the ownership boundary, because
     * a tenant finding a place has no relationship to its owner yet.
     */
    Optional<Property> findByCode(String code);

    /** Whether this landlord has any locked property — the create-property guard. */
    boolean existsByLandlordIdAndAccountStatus(UUID landlordId, PropertyAccountStatus status);

    long countByLandlordId(UUID landlordId);
}
