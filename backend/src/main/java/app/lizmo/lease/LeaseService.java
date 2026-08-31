package app.lizmo.lease;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.lease.dto.EndLeaseRequest;
import app.lizmo.lease.dto.LeaseResponse;
import app.lizmo.property.Bed;
import app.lizmo.property.BedRepository;
import app.lizmo.property.BedStatus;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.user.UserRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Leases as they are read and as they end.
 *
 * <p>Creating one lives with the request that produced it; this is everything
 * afterwards.
 */
@Service
public class LeaseService {

    private final LeaseRepository leases;
    private final PropertyAccess access;
    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;
    private final UserRepository users;

    public LeaseService(
            LeaseRepository leases,
            PropertyAccess access,
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            UserRepository users) {
        this.leases = leases;
        this.access = access;
        this.properties = properties;
        this.units = units;
        this.beds = beds;
        this.users = users;
    }

    /** The tenant's own leases, newest first. */
    @Transactional(readOnly = true)
    public List<LeaseResponse> mine(UUID tenantId) {
        List<LeaseResponse> described = new ArrayList<>();
        for (Lease lease : leases.findByTenantIdOrderByStartDateDesc(tenantId)) {
            described.add(describe(lease));
        }
        return described;
    }

    /** Every lease on one property, for the landlord who owns it. */
    @Transactional(readOnly = true)
    public List<LeaseResponse> forProperty(UUID propertyId, UUID landlordId) {
        access.readable(propertyId, landlordId);

        List<LeaseResponse> described = new ArrayList<>();
        for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(propertyId)) {
            for (Lease lease : leases.findByUnitIdAndStatus(unit.getId(), LeaseStatus.ACTIVE)) {
                described.add(describe(lease));
            }
        }
        return described;
    }

    /**
     * Ends a lease and gives the slot back.
     *
     * <p>ENDED or TERMINATED, which the landlord chooses: a tenancy that ran
     * its course and one stopped early are different things to look back on,
     * and flattening them would lose the only record of which happened.
     *
     * <p>The status change is what frees the slot. Both unique indexes are
     * partial on ACTIVE, so the bed becomes lettable again the moment this
     * commits — and a bed whose first tenant left must not stay poisoned.
     */
    @Transactional
    public LeaseResponse end(UUID leaseId, UUID landlordId, EndLeaseRequest command) {
        Lease lease = leases.findById(leaseId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such lease."));

        Unit unit = units.findById(lease.getUnitId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such unit."));

        // Writable, not readable: ending a tenancy is a change to who lives in
        // the property.
        access.writable(unit.getPropertyId(), landlordId);

        if (!lease.isActive()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That lease has already ended.");
        }

        LocalDate on = command == null || command.endDate() == null
                ? LocalDate.now()
                : command.endDate();
        if (on.isBefore(lease.getStartDate())) {
            // A lease that ended before it began is not a tenancy anybody can
            // reason about, least of all a billing period.
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A lease cannot end before it starts.");
        }

        boolean terminated = command != null && Boolean.TRUE.equals(command.terminated());
        lease.close(terminated ? LeaseStatus.TERMINATED : LeaseStatus.ENDED, on);
        leases.save(lease);

        freeTheSlot(unit, lease.getBedId());

        return describe(lease);
    }

    /**
     * Hands the bed or unit back to the vacancy list.
     *
     * <p>Recomputed from what is actually let rather than assumed: a room with
     * three beds loses one tenant and is still partly occupied, and only
     * counting tells you which.
     */
    private void freeTheSlot(Unit unit, UUID bedId) {
        if (bedId == null) {
            unit.reflectBedOccupancy(true, false);
            units.save(unit);
            return;
        }

        beds.findById(bedId).ifPresent(bed -> {
            bed.markVacated();
            beds.saveAndFlush(bed);
        });

        List<Bed> siblings = beds.findByUnitIdOrderByBedLabelAsc(unit.getId());
        boolean anyVacant = siblings.stream()
                .anyMatch(other -> other.getStatus() == BedStatus.VACANT);
        boolean anyOccupied = siblings.stream()
                .anyMatch(other -> other.getStatus() == BedStatus.OCCUPIED);
        unit.reflectBedOccupancy(anyVacant, anyOccupied);
        units.save(unit);
    }

    private LeaseResponse describe(Lease lease) {
        Unit unit = units.findById(lease.getUnitId()).orElse(null);
        Property property = unit == null
                ? null
                : properties.findById(unit.getPropertyId()).orElse(null);
        Bed bed = lease.getBedId() == null
                ? null
                : beds.findById(lease.getBedId()).orElse(null);

        return LeaseResponse.of(
                lease,
                users.findById(lease.getTenantId()).map(user -> user.getName()).orElse(null),
                unit == null ? null : unit.getPropertyId(),
                property == null ? null : property.getName(),
                unit == null ? null : unit.getUnitNumber(),
                bed == null ? null : bed.getBedLabel());
    }
}
