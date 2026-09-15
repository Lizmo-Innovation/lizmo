package app.lizmo.property;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BedRepository extends JpaRepository<Bed, UUID> {

    List<Bed> findByUnitIdOrderByBedLabelAsc(UUID unitId);

    /** Every bed across several units at once, for a whole property in one query. */
    List<Bed> findByUnitIdInOrderByBedLabelAsc(Collection<UUID> unitIds);

    boolean existsByUnitIdAndBedLabelIgnoreCase(UUID unitId, String bedLabel);

    long countByUnitId(UUID unitId);

    long countByUnitIdAndStatus(UUID unitId, BedStatus status);
}
