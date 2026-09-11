package app.lizmo.maintenance;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MaintenanceReportRepository extends JpaRepository<MaintenanceReport, UUID> {

    /** What a tenant has reported, newest first. */
    List<MaintenanceReport> findBySubmittedByOrderBySubmittedAtDesc(UUID tenantId);

    /** Every report on a landlord's units, newest first. */
    List<MaintenanceReport> findByUnitIdInOrderBySubmittedAtDesc(Collection<UUID> unitIds);
}
