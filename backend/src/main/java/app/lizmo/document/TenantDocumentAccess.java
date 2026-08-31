package app.lizmo.document;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.dto.TenantDocumentResponse;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * When a landlord may look at a tenant's ID.
 *
 * <p>Only through a live lease, which is why this is addressed by lease rather
 * than by tenant. There is deliberately no way to ask "show me this person's
 * documents" — the question the API answers is "show me the documents of the
 * person living in my room", and the moment they stop living there the question
 * stops having an answer.
 *
 * <p>That is stricter than it looks. A landlord who housed somebody for two
 * years loses access the day the lease ends, and cannot go back for a copy.
 * Deliberate: the reason they were shown an ID was to let a room, and that
 * reason expires with the tenancy.
 */
@Service
public class TenantDocumentAccess {

    private final LeaseRepository leases;
    private final UnitRepository units;
    private final PropertyAccess access;
    private final TenantDocumentService documents;

    public TenantDocumentAccess(
            LeaseRepository leases,
            UnitRepository units,
            PropertyAccess access,
            TenantDocumentService documents) {
        this.leases = leases;
        this.units = units;
        this.access = access;
        this.documents = documents;
    }

    /**
     * The photographs of whoever holds this lease.
     *
     * @throws ApiException 404 if the lease is not on the caller's property, so
     *                      a lease id from anywhere reveals nothing; and 404 if
     *                      the lease has ended, which is the same answer a
     *                      stranger gets, because by then it is the same thing.
     */
    @Transactional(readOnly = true)
    public List<TenantDocumentResponse> forLease(UUID leaseId, UUID landlordId) {
        Lease lease = leases.findById(leaseId)
                .orElseThrow(() -> notFound());

        Unit unit = units.findById(lease.getUnitId()).orElseThrow(() -> notFound());

        // Throws if the property is not theirs.
        access.readable(unit.getPropertyId(), landlordId);

        if (!lease.isActive()) {
            throw notFound();
        }

        return documents.listFor(lease.getTenantId());
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No such lease.");
    }
}
