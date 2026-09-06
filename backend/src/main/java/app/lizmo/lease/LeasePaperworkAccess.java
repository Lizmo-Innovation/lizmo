package app.lizmo.lease;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Who may handle the paperwork attached to a lease.
 *
 * <p>Deliberately <em>not</em> {@link LeaseHolderAccess}, which is the gate on
 * the tenant themselves and closes the day a tenancy ends. That rule is right
 * for somebody's ID: the reason a landlord was shown it was to let a room, and
 * the reason expires with the room.
 *
 * <p>It is exactly wrong for a signed contract. Disputes happen after a tenant
 * moves out, and that is precisely when the paperwork is wanted. A landlord who
 * lost their contracts the day each tenancy ended would not find out until the
 * worst possible moment.
 *
 * <p>So this asks only about ownership of the property, and keeps answering
 * for as long as the lease row exists. The tenant is separately allowed to see
 * the attachments marked as shared — a lease is an agreement between two
 * people, and one of them holding the only copy is not an agreement.
 */
@Service
public class LeasePaperworkAccess {

    private final LeaseRepository leases;
    private final UnitRepository units;
    private final PropertyAccess access;

    public LeasePaperworkAccess(
            LeaseRepository leases, UnitRepository units, PropertyAccess access) {
        this.leases = leases;
        this.units = units;
        this.access = access;
    }

    /**
     * The lease, if this landlord owns the property it sits on.
     *
     * <p>Ended or active, both. See the class note.
     *
     * @throws ApiException 404 if the lease is not theirs, so a lease id from
     *                      anywhere reveals nothing
     */
    @Transactional(readOnly = true)
    public Lease requireLandlord(UUID leaseId, UUID landlordId) {
        Lease lease = leases.findById(leaseId).orElseThrow(LeasePaperworkAccess::notFound);

        Unit unit = units.findById(lease.getUnitId())
                .orElseThrow(LeasePaperworkAccess::notFound);

        // Throws if the property is not theirs.
        access.readable(unit.getPropertyId(), landlordId);

        return lease;
    }

    /**
     * The lease, if this tenant is the one living under it.
     *
     * <p>Also past the end of the tenancy, for the same reason: somebody who
     * moved out last year may still need the contract they signed.
     */
    @Transactional(readOnly = true)
    public Lease requireTenant(UUID leaseId, UUID tenantId) {
        return leases.findById(leaseId)
                .filter(lease -> lease.getTenantId().equals(tenantId))
                .orElseThrow(LeasePaperworkAccess::notFound);
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No such lease.");
    }
}
