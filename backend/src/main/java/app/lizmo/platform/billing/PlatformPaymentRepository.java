package app.lizmo.platform.billing;

import app.lizmo.billing.PaymentStatus;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlatformPaymentRepository extends JpaRepository<PlatformPayment, UUID> {

    /** What has been sent against one invoice, oldest first. */
    List<PlatformPayment> findByInvoiceIdOrderByCreatedAtAsc(UUID invoiceId);

    /** The admin's queue, oldest first: whoever has waited longest is answered first. */
    List<PlatformPayment> findByStatusOrderByCreatedAtAsc(PaymentStatus status);
}
