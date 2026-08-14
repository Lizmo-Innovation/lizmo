package app.lizmo.property;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UnitRepository extends JpaRepository<Unit, UUID> {

    List<Unit> findByPropertyIdOrderByUnitNumberAsc(UUID propertyId);

    boolean existsByPropertyIdAndUnitNumberIgnoreCase(UUID propertyId, String unitNumber);

    long countByPropertyId(UUID propertyId);
}
