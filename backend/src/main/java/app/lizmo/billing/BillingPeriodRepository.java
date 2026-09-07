package app.lizmo.billing;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BillingPeriodRepository extends JpaRepository<BillingPeriod, UUID> {

    /** Every month of one tenancy, oldest first. */
    List<BillingPeriod> findByLeaseIdOrderByPeriodStartAsc(UUID leaseId);

    List<BillingPeriod> findByLeaseIdIn(List<UUID> leaseIds);
}
