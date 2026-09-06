package app.lizmo.document;

import app.lizmo.document.dto.TenantDocumentResponse;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseHolderAccess;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A landlord looking at the ID of somebody living in their room.
 *
 * <p>The rule about when that is allowed lives in {@link LeaseHolderAccess},
 * which the tenant's written details ask as well. This class is only the
 * photographs half of the answer.
 */
@Service
public class TenantDocumentAccess {

    private final LeaseHolderAccess access;
    private final TenantDocumentService documents;

    public TenantDocumentAccess(
            LeaseHolderAccess access, TenantDocumentService documents) {
        this.access = access;
        this.documents = documents;
    }

    /** The photographs of whoever holds this lease. */
    @Transactional(readOnly = true)
    public List<TenantDocumentResponse> forLease(UUID leaseId, UUID landlordId) {
        Lease lease = access.requireLive(leaseId, landlordId);
        return documents.listFor(lease.getTenantId());
    }
}
