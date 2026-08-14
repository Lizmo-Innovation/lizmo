package app.lizmo.property;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PropertyRepository extends JpaRepository<Property, UUID> {

    /**
     * A landlord's own properties. Every listing goes through this rather than
     * findAll, so forgetting the scope is not possible by omission.
     */
    List<Property> findByLandlordIdOrderByNameAsc(UUID landlordId);
}
