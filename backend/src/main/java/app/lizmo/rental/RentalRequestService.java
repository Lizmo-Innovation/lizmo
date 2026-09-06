package app.lizmo.rental;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.property.Bed;
import app.lizmo.property.BedRepository;
import app.lizmo.property.BedStatus;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.RentalMode;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.property.UnitStatus;
import app.lizmo.rental.dto.RentalRequestCreate;
import app.lizmo.rental.dto.RentalRequestResponse;
import app.lizmo.user.LeaseReadiness;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A tenant asking a landlord for somewhere to live.
 *
 * <p>The tenant drives this, not the landlord: they find the place by its code,
 * see what is free, and ask for one particular bed or unit. Nothing here
 * creates a lease — accepting does that, and acceptance is the landlord's.
 */
@Service
public class RentalRequestService {

    private final RentalRequestRepository requests;
    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;
    private final LeaseReadiness readiness;

    /** So a landlord finds out somebody asked without opening the inbox. */
    private final NotificationService notifications;

    public RentalRequestService(
            RentalRequestRepository requests,
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            LeaseReadiness readiness,
            NotificationService notifications) {
        this.requests = requests;
        this.properties = properties;
        this.units = units;
        this.beds = beds;
        this.readiness = readiness;
        this.notifications = notifications;
    }

    @Transactional
    public RentalRequestResponse create(UUID tenantId, RentalRequestCreate command) {
        // Before anything else. A landlord judging a request needs an emergency
        // contact and an ID to judge it on, and telling the tenant now — while
        // they are in the app, looking at the room they want — is the moment
        // they are most likely to go and finish their profile.
        readiness.require(tenantId);

        Unit unit = units.findById(command.unitId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such unit."));

        // Out of service takes its beds with it: the room is shut.
        if (unit.getStatus() == UnitStatus.MAINTENANCE) {
            throw unavailable("That room is not available at the moment.");
        }

        Bed bed = null;
        if (command.bedId() == null) {
            requireWholeUnitIsOnOffer(unit);
        } else {
            bed = requireBedIsOnOffer(unit, command.bedId());
        }

        requireNotAlreadyAsked(tenantId, unit, bed);

        RentalRequest request = new RentalRequest(
                tenantId, unit.getPropertyId(), unit.getId(), bed == null ? null : bed.getId());

        try {
            request = requests.saveAndFlush(request);
        } catch (DataIntegrityViolationException raced) {
            // Two taps of the same button, arriving together. The partial
            // unique index settled it; the tenant meant to ask once.
            throw new ApiException(ErrorCode.ALREADY_REQUESTED,
                    "You have already asked about this one. The landlord will reply.");
        }

        // No tenant name in the message. The landlord opens the request to see
        // who it is, and a notification is read in places -- a lock screen,
        // later a push -- where a name is more exposure than the tenant agreed
        // to when they asked.
        notifications.raise(
                landlordOf(unit),
                NotificationType.REQUEST_RECEIVED,
                "Somebody has asked about a room",
                "A tenant has asked about %s. Open your requests to see who, and accept or decline."
                        .formatted(slotWords(unit, bed)),
                NotificationEntityType.RENTAL_REQUEST,
                request.getId());

        return describe(request, unit, bed);
    }

    /** Everything this tenant has asked for, newest first. */
    @Transactional(readOnly = true)
    public List<RentalRequestResponse> listMine(UUID tenantId) {
        List<RentalRequestResponse> described = new ArrayList<>();
        for (RentalRequest request : requests.findByTenantIdOrderByCreatedAtDesc(tenantId)) {
            Unit unit = units.findById(request.getUnitId()).orElse(null);
            Bed bed = request.getBedId() == null
                    ? null
                    : beds.findById(request.getBedId()).orElse(null);
            described.add(describe(request, unit, bed));
        }
        return described;
    }

    /**
     * The tenant changing their mind.
     *
     * <p>Only their own, and only while it is still waiting: a request the
     * landlord has already answered is a record of what happened, not something
     * to edit.
     */
    @Transactional
    public RentalRequestResponse withdraw(UUID tenantId, UUID requestId) {
        RentalRequest request = requests.findByIdAndTenantId(requestId, tenantId)
                // Not "forbidden": somebody else's request should not be
                // distinguishable from one that does not exist.
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such request."));

        if (!request.isPending()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That request has already been answered.");
        }

        request.settle(RentalRequestStatus.WITHDRAWN);
        requests.save(request);

        Unit unit = units.findById(request.getUnitId()).orElse(null);
        Bed bed = request.getBedId() == null
                ? null
                : beds.findById(request.getBedId()).orElse(null);
        return describe(request, unit, bed);
    }

    private void requireWholeUnitIsOnOffer(Unit unit) {
        if (unit.getRentalMode() != RentalMode.WHOLE_UNIT) {
            // Asking for the whole of a room that is let bed by bed. The
            // landlord chose to let it that way; the tenant has to pick a bed.
            throw unavailable("That room is let bed by bed. Choose a bed instead.");
        }
        if (unit.getStatus() != UnitStatus.VACANT) {
            throw unavailable("That unit has been taken.");
        }
    }

    private Bed requireBedIsOnOffer(Unit unit, UUID bedId) {
        if (unit.getRentalMode() != RentalMode.BEDSPACE) {
            throw unavailable("That unit is let whole, not by the bed.");
        }

        Bed bed = beds.findById(bedId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such bed."));

        // A bed id from another unit entirely. Checked rather than trusted:
        // both ids come from the request.
        if (!bed.getUnitId().equals(unit.getId())) {
            throw new ApiException(ErrorCode.NOT_FOUND, "No such bed.");
        }
        if (bed.getStatus() != BedStatus.VACANT) {
            throw unavailable("That bed has been taken.");
        }
        return bed;
    }

    /**
     * Checked here as well as by the index, so the common case gets a sentence
     * a tenant can read rather than a constraint violation.
     */
    private void requireNotAlreadyAsked(UUID tenantId, Unit unit, Bed bed) {
        boolean already = bed == null
                ? requests.existsByTenantIdAndUnitIdAndBedIdIsNullAndStatus(
                        tenantId, unit.getId(), RentalRequestStatus.PENDING)
                : requests.existsByTenantIdAndBedIdAndStatus(
                        tenantId, bed.getId(), RentalRequestStatus.PENDING);

        if (already) {
            throw new ApiException(ErrorCode.ALREADY_REQUESTED,
                    "You have already asked about this one. The landlord will reply.");
        }
    }

    private RentalRequestResponse describe(RentalRequest request, Unit unit, Bed bed) {
        Property property = properties.findById(request.getPropertyId()).orElse(null);
        return RentalRequestResponse.of(
                request,
                property == null ? null : property.getName(),
                unit == null ? null : unit.getUnitNumber(),
                bed == null ? null : bed.getBedLabel());
    }

    /** The landlord to tell. Null if the property has gone, which cannot happen. */
    private UUID landlordOf(Unit unit) {
        return properties.findById(unit.getPropertyId())
                .map(Property::getLandlordId)
                .orElse(null);
    }

    /** "bed 1 in 2B", or "unit 101" -- how a person would say it. */
    private static String slotWords(Unit unit, Bed bed) {
        return bed == null
                ? "unit " + unit.getUnitNumber()
                : bed.getBedLabel() + " in " + unit.getUnitNumber();
    }

    private static ApiException unavailable(String message) {
        return new ApiException(ErrorCode.SLOT_UNAVAILABLE, message);
    }
}
