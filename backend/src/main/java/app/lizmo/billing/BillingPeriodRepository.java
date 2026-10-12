package app.lizmo.billing;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BillingPeriodRepository extends JpaRepository<BillingPeriod, UUID> {

    /** Every month of one tenancy, oldest first. */
    List<BillingPeriod> findByLeaseIdOrderByPeriodStartAsc(UUID leaseId);

    /**
     * As above, with the deposit before the first month: both start on
     * move-in day, and the order of a list shown to people should not be left
     * to the database.
     */
    List<BillingPeriod> findByLeaseIdOrderByPeriodStartAscKindAsc(UUID leaseId);

    List<BillingPeriod> findByLeaseIdIn(List<UUID> leaseIds);
}
