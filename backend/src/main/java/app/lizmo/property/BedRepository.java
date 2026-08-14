package app.lizmo.property;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BedRepository extends JpaRepository<Bed, UUID> {

    List<Bed> findByUnitIdOrderByBedLabelAsc(UUID unitId);

    boolean existsByUnitIdAndBedLabelIgnoreCase(UUID unitId, String bedLabel);

    long countByUnitId(UUID unitId);
}
