package app.lizmo.platform.billing;

import app.lizmo.billing.PaymentStatus;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlatformPaymentRepository extends JpaRepository<PlatformPayment, UUID> {

    /** What has been sent against one statement, oldest first. */
    List<PlatformPayment> findByStatementIdOrderByCreatedAtAsc(UUID statementId);

    /** The same across several statements, for a list that shows them all. */
    List<PlatformPayment> findByStatementIdIn(Collection<UUID> statementIds);

    /** The admin's queue, oldest first: whoever has waited longest is answered first. */
    List<PlatformPayment> findByStatusOrderByCreatedAtAsc(PaymentStatus status);
}
