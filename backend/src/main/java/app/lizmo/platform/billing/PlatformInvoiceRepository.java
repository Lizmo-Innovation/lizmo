package app.lizmo.platform.billing;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlatformInvoiceRepository extends JpaRepository<PlatformInvoice, UUID> {

    /** One statement's lines. */
    List<PlatformInvoice> findByStatementId(UUID statementId);

    /** Every line across several statements, for a list that shows them all. */
    List<PlatformInvoice> findByStatementIdIn(Collection<UUID> statementIds);
}
