package app.lizmo.billing;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaymentRepository extends JpaRepository<Payment, UUID> {

    List<Payment> findByBillingPeriodIdOrderByCreatedAtAsc(UUID billingPeriodId);

    List<Payment> findByLeaseIdOrderByPaymentDateDesc(UUID leaseId);
}
