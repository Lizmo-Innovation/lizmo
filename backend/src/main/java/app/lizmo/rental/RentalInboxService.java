package app.lizmo.rental;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.property.Bed;
import app.lizmo.property.BedRepository;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.rental.dto.RentalRequestForLandlord;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.TenantProfileRepository;
import app.lizmo.user.User;
import app.lizmo.user.UserRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * What is waiting for a landlord to answer.
 *
 * <p>Scoped to one property at a time, through PropertyAccess, so reading an
 * inbox can only ever return requests for somewhere the caller owns.
 */
@Service
public class RentalInboxService {

    private final RentalRequestRepository requests;
    private final PropertyAccess access;
    private final UnitRepository units;
    private final BedRepository beds;
    private final UserRepository users;
    private final TenantProfileRepository profiles;

    public RentalInboxService(
            RentalRequestRepository requests,
            PropertyAccess access,
            UnitRepository units,
            BedRepository beds,
            UserRepository users,
            TenantProfileRepository profiles) {
        this.requests = requests;
        this.access = access;
        this.units = units;
        this.beds = beds;
        this.users = users;
        this.profiles = profiles;
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
        access.readable(propertyId, landlordId);

        List<RentalRequest> found = pendingOnly
                ? requests.findByPropertyIdAndStatusOrderByCreatedAtAsc(
                        propertyId, RentalRequestStatus.PENDING)
                : requests.findByPropertyIdOrderByCreatedAtDesc(propertyId);

        List<RentalRequestForLandlord> described = new ArrayList<>();
        for (RentalRequest request : found) {
            described.add(describe(request));
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
        access.readable(request.getPropertyId(), landlordId);

        return describe(request);
    }

    private RentalRequestForLandlord describe(RentalRequest request) {
        User tenant = users.findById(request.getTenantId()).orElse(null);
        TenantProfile profile = profiles.findById(request.getTenantId()).orElse(null);

        Unit unit = units.findById(request.getUnitId()).orElse(null);
        Bed bed = request.getBedId() == null
                ? null
                : beds.findById(request.getBedId()).orElse(null);

        return RentalRequestForLandlord.of(
                request,
                tenant,
                profile,
                unit == null ? null : unit.getUnitNumber(),
                bed == null ? null : bed.getBedLabel());
    }
}
