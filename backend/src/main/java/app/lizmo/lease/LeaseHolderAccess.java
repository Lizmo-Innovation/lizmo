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
 * When a landlord may look at the person living in their room.
 *
 * <p>Two things unlock on acceptance and lock again when the tenancy ends: the
 * tenant's ID photographs, and the private half of their profile — the ID
 * number and the emergency contact. Both are governed by exactly the same
 * question, so both ask it here rather than each keeping its own copy. A
 * privacy boundary written down twice is a privacy boundary that drifts.
 *
 * <p>Addressed by lease, never by tenant. There is deliberately no endpoint
 * that takes a person and returns their details: the only question this API
 * answers is "who is living in my room", and a tenant id is therefore not a key
 * to anything.
 *
 * <p>Stricter than it looks. A landlord who housed somebody for two years loses
 * access the day the lease ends and cannot go back for a copy. Deliberate: the
 * reason they were shown any of it was to let a room, and that reason expires
 * with the tenancy.
 */
@Service
public class LeaseHolderAccess {

    private final LeaseRepository leases;
    private final UnitRepository units;
    private final PropertyAccess access;

    public LeaseHolderAccess(
            LeaseRepository leases, UnitRepository units, PropertyAccess access) {
        this.leases = leases;
        this.units = units;
        this.access = access;
    }

    /**
     * The lease, if this landlord is entitled to look through it right now.
     *
     * @throws ApiException 404 if the lease is not on the caller's property, so
     *                      a lease id from anywhere reveals nothing; and 404 if
     *                      the tenancy has ended, which is the same answer a
     *                      stranger gets, because by then it is the same thing.
     */
    @Transactional(readOnly = true)
    public Lease requireLive(UUID leaseId, UUID landlordId) {
        Lease lease = leases.findById(leaseId).orElseThrow(LeaseHolderAccess::notFound);

        Unit unit = units.findById(lease.getUnitId())
                .orElseThrow(LeaseHolderAccess::notFound);

        // Throws if the property is not theirs.
        access.readable(unit.getPropertyId(), landlordId);

        if (!lease.isActive()) {
            throw notFound();
        }

        return lease;
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No such lease.");
    }
}
