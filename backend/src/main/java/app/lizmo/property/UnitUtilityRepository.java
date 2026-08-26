package app.lizmo.property;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UnitUtilityRepository extends JpaRepository<UnitUtility, UUID> {

    List<UnitUtility> findByUnitIdOrderByKindAsc(UUID unitId);

    Optional<UnitUtility> findByUnitIdAndKind(UUID unitId, UtilityKind kind);
}
