package app.lizmo.rental;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.property.Bed;
import app.lizmo.property.BedRepository;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.rental.dto.RentalRequestForLandlord;
import app.lizmo.user.LeaseReadiness;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.TenantProfileRepository;
import app.lizmo.user.User;
import app.lizmo.user.UserRepository;
import java.util.ArrayList;
import java.time.Clock;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * What is waiting for a landlord to answer.
 *
 * <p>Only ever returns requests for somewhere the caller owns: one property
 * through PropertyAccess, or every property looked up by owner.
 */
@Service
public class RentalInboxService {

    private final RentalRequestRepository requests;
    private final PropertyAccess access;
    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;
    private final UserRepository users;
    private final TenantProfileRepository profiles;
    /** So a landlord is told what is still missing before they try to accept. */
    private final LeaseReadiness readiness;

    /** Injected so an age can be asserted against a date a test chooses. */
    private final Clock clock;

    public RentalInboxService(
            RentalRequestRepository requests,
            PropertyAccess access,
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            UserRepository users,
            TenantProfileRepository profiles,
            LeaseReadiness readiness,
            Clock clock) {
        this.requests = requests;
        this.access = access;
        this.properties = properties;
        this.units = units;
        this.beds = beds;
        this.users = users;
        this.profiles = profiles;
        this.readiness = readiness;
        this.clock = clock;
    }

    /**
     * Requests for one property.
     *
     * @param pendingOnly the usual case: what still needs an answer. The full
     *                    list is for looking back over who was turned away,
     *                    which is a different question asked far less often.
     */
    @Transactional(readOnly = true)
    public List<RentalRequestForLandlord> forProperty(
            UUID propertyId, UUID landlordId, boolean pendingOnly) {

        // Throws if this is not their property. Checked before anything is
        // read, so a wrong id never returns somebody else's queue.
        Property property = access.readable(propertyId, landlordId);

        List<RentalRequest> found = pendingOnly
                ? requests.findByPropertyIdAndStatusOrderByCreatedAtAsc(
                        propertyId, RentalRequestStatus.PENDING)
                : requests.findByPropertyIdOrderByCreatedAtDesc(propertyId);

        List<RentalRequestForLandlord> described = new ArrayList<>();
        for (RentalRequest request : found) {
            described.add(describe(request, property.getName()));
        }
        return described;
    }

    /**
     * Everybody waiting on this landlord, across every property they own.
     *
     * <p>The queue used to exist one property at a time, so a landlord with
     * three buildings had to open each to find out whether anybody was
     * asking. Oldest first across all of them, for the reason each queue is:
     * whoever has waited longest is answered first.
     *
     * <p>Ownership is by construction: only properties found by this owner
     * are asked about. An account with none -- a tenant -- gets an empty list.
     */
    @Transactional(readOnly = true)
    public List<RentalRequestForLandlord> waitingOn(UUID landlordId) {
        Map<UUID, String> names = new HashMap<>();
        for (Property property : properties.findByLandlordIdOrderByNameAsc(landlordId)) {
            names.put(property.getId(), property.getName());
        }
        if (names.isEmpty()) {
            return List.of();
        }

        List<RentalRequestForLandlord> described = new ArrayList<>();
        for (RentalRequest request : requests.findByPropertyIdInAndStatusOrderByCreatedAtAsc(
                names.keySet(), RentalRequestStatus.PENDING)) {
            described.add(describe(request, names.get(request.getPropertyId())));
        }
        return described;
    }

    /** One request, for the screen that shows a tenant in full. */
    @Transactional(readOnly = true)
    public RentalRequestForLandlord one(UUID requestId, UUID landlordId) {
        RentalRequest request = requests.findById(requestId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such request."));

        // The same check as the list. Without it, a request id from anywhere
        // would hand a stranger's details to whoever held it.
        Property property = access.readable(request.getPropertyId(), landlordId);

        return describe(request, property.getName());
    }

    private RentalRequestForLandlord describe(RentalRequest request, String propertyName) {
        User tenant = users.findById(request.getTenantId()).orElse(null);
        TenantProfile profile = profiles.findById(request.getTenantId()).orElse(null);

        Unit unit = units.findById(request.getUnitId()).orElse(null);
        Bed bed = request.getBedId() == null
                ? null
                : beds.findById(request.getBedId()).orElse(null);

        return RentalRequestForLandlord.of(
                request,
                propertyName,
                tenant,
                profile,
                unit == null ? null : unit.getUnitNumber(),
                bed == null ? null : bed.getBedLabel(),
                LocalDate.now(clock),
                // What the tenant was looking at, and what accepting will use
                // unless the landlord types something else. The bed's own
                // price wins over the unit's, exactly as the accept endpoint
                // decides it.
                bed != null && bed.getRent() != null
                        ? bed.getRent()
                        : (unit == null ? null : unit.getRent()),
                // Empty means the landlord can accept. Named rather than a
                // flag, so the screen can say which thing is missing instead
                // of "profile incomplete", which a landlord cannot act on.
                readiness.whatIsMissing(request.getTenantId()));
    }
}
