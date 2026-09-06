package app.lizmo.rental;

import app.lizmo.common.ApiException;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.common.ErrorCode;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.lease.dto.AcceptRequest;
import app.lizmo.lease.dto.LeaseResponse;
import app.lizmo.property.Bed;
import app.lizmo.property.BedRepository;
import app.lizmo.property.BedStatus;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.RentalMode;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.property.UnitStatus;
import app.lizmo.rental.dto.RentalRequestForLandlord;
import app.lizmo.user.UserRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The landlord answering: yes, and a lease exists; or no, and it does not.
 *
 * <p>Accepting is the only thing in the system that creates a lease, and it is
 * the point where several people asking about one bed collapses into one person
 * holding it. Everything here is one transaction for that reason.
 */
@Service
public class RentalDecisionService {

    private final RentalRequestRepository requests;
    private final RentalInboxService inbox;
    private final LeaseRepository leases;
    private final PropertyAccess access;
    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;
    private final UserRepository users;

    /** Nobody was told anything before this. See NotificationService. */
    private final NotificationService notifications;

    public RentalDecisionService(
            RentalRequestRepository requests,
            RentalInboxService inbox,
            LeaseRepository leases,
            PropertyAccess access,
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            UserRepository users,
            NotificationService notifications) {
        this.requests = requests;
        this.inbox = inbox;
        this.leases = leases;
        this.access = access;
        this.properties = properties;
        this.units = units;
        this.beds = beds;
        this.users = users;
        this.notifications = notifications;
    }

    @Transactional
    public LeaseResponse accept(UUID requestId, UUID landlordId, AcceptRequest terms) {
        RentalRequest request = pendingRequestToAccept(requestId, landlordId);

        Unit unit = units.findById(request.getUnitId()).orElseThrow(
                () -> new ApiException(ErrorCode.NOT_FOUND, "No such unit."));
        if (unit.getStatus() == UnitStatus.MAINTENANCE) {
            throw unavailable("That room is out of service.");
        }

        Bed bed = request.getBedId() == null
                ? null
                : beds.findById(request.getBedId()).orElseThrow(
                        () -> new ApiException(ErrorCode.NOT_FOUND, "No such bed."));

        requireStillFree(unit, bed);

        BigDecimal rent = rentFor(terms, unit, bed);
        LocalDate start = terms == null || terms.startDate() == null
                ? LocalDate.now()
                : terms.startDate();
        short dueDay = dueDayFor(terms, start);

        Lease lease = new Lease(
                request.getTenantId(),
                unit.getId(),
                bed == null ? null : bed.getId(),
                rent,
                dueDay,
                start,
                request.getId(),
                terms == null ? null : terms.depositAmount(),
                terms == null ? null : terms.advanceAmount());

        try {
            lease = leases.saveAndFlush(lease);
        } catch (DataIntegrityViolationException raced) {
            // Two landlords -- or two taps -- accepting different requests for
            // the same slot at once. The partial unique index settled it, and
            // the loser is told the truth rather than shown a 500.
            throw unavailable("Somebody else was accepted for this one.");
        }

        request.settle(RentalRequestStatus.ACCEPTED);
        requests.save(request);

        supersedeRivals(request);
        markOccupied(unit, bed);

        // The terms are in the message on purpose: this is the first moment
        // the tenant sees what was agreed, and the rent may not be the one
        // they were looking at when they asked.
        notifications.raise(
                request.getTenantId(),
                NotificationType.REQUEST_ACCEPTED,
                "Your request was accepted",
                "You have %s. Rent is P%s a month, due on the %s, from %s."
                        .formatted(
                                slotWords(unit, bed),
                                rent.stripTrailingZeros().toPlainString(),
                                ordinal(dueDay),
                                start),
                NotificationEntityType.LEASE,
                lease.getId());

        return describe(lease, unit, bed);
    }

    @Transactional
    public RentalRequestForLandlord decline(UUID requestId, UUID landlordId) {
        RentalRequest request = pendingRequestToDecline(requestId, landlordId);
        request.settle(RentalRequestStatus.DECLINED);
        requests.save(request);

        // No reason given, because the landlord was not asked for one. Better
        // a plain no than an invented explanation.
        notifications.raise(
                request.getTenantId(),
                NotificationType.REQUEST_DECLINED,
                "Your request was declined",
                "The landlord has said no to your request. You can look for "
                        + "somewhere else in Lizmo.",
                NotificationEntityType.RENTAL_REQUEST,
                request.getId());

        return inbox.one(requestId, landlordId);
    }

    /**
     * Everyone else still waiting on the same slot.
     *
     * <p>SUPERSEDED rather than DECLINED: the landlord judged one person and
     * chose them, and did not judge these. Telling somebody they were turned
     * down when they were simply not first is both untrue and worse to read.
     */
    private void supersedeRivals(RentalRequest accepted) {
        List<RentalRequest> waiting = requests.findByPropertyIdAndStatusOrderByCreatedAtAsc(
                accepted.getPropertyId(), RentalRequestStatus.PENDING);

        for (RentalRequest rival : waiting) {
            if (rival.getId().equals(accepted.getId())) {
                continue;
            }
            if (!sameSlot(rival, accepted)) {
                continue;
            }
            rival.settle(RentalRequestStatus.SUPERSEDED);
            requests.save(rival);

            // The whole reason for this feature. Their request changed state
            // because of something a third party did, and until now nobody
            // told them -- which is worse than a decline, because a decline at
            // least happens to you.
            notifications.raise(
                    rival.getTenantId(),
                    NotificationType.REQUEST_SUPERSEDED,
                    "That one has gone",
                    "Somebody else was accepted for the room you asked about. "
                            + "Your request has closed -- have a look for "
                            + "another one.",
                    NotificationEntityType.RENTAL_REQUEST,
                    rival.getId());
        }
    }

    /**
     * The same bed, or the same whole unit.
     *
     * <p>Compared on the bed when there is one: two requests for different beds
     * in the same room are not rivals, and superseding by unit would clear a
     * queue the landlord still wants.
     */
    private static boolean sameSlot(RentalRequest one, RentalRequest other) {
        if (one.getBedId() != null || other.getBedId() != null) {
            return one.getBedId() != null && one.getBedId().equals(other.getBedId());
        }
        return one.getUnitId().equals(other.getUnitId());
    }

    /**
     * Checked again at the moment of acceptance, not only when the request was
     * sent. A queue can be days old, and the room may have gone in the meantime.
     */
    private void requireStillFree(Unit unit, Bed bed) {
        if (bed == null) {
            if (unit.getRentalMode() != RentalMode.WHOLE_UNIT) {
                throw unavailable("That room is let bed by bed.");
            }
            if (unit.getStatus() != UnitStatus.VACANT) {
                throw unavailable("That unit is already let.");
            }
            // A room let entire cannot also have beds let inside it.
            if (!leases.findByUnitIdAndStatus(unit.getId(), LeaseStatus.ACTIVE).isEmpty()) {
                throw unavailable("That unit is already let.");
            }
            return;
        }

        if (bed.getStatus() != BedStatus.VACANT) {
            throw unavailable("That bed is already let.");
        }
        if (leases.findByBedIdAndStatus(bed.getId(), LeaseStatus.ACTIVE).isPresent()) {
            throw unavailable("That bed is already let.");
        }
    }

    /**
     * The asking price unless the landlord names another.
     *
     * <p>A bed with no price of its own falls back to the unit's, the same rule
     * the vacancy list resolves by -- so what the tenant was shown is what they
     * are held to.
     */
    private static BigDecimal rentFor(AcceptRequest terms, Unit unit, Bed bed) {
        if (terms != null && terms.rentAmount() != null) {
            return terms.rentAmount();
        }
        BigDecimal asking = bed != null && bed.getRent() != null
                ? bed.getRent()
                : unit.getRent();
        if (asking == null) {
            // Nothing priced. Refusing beats inventing a rent, or writing a
            // zero that would read as free for the life of the lease.
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Set a rent for this one before accepting.");
        }
        return asking;
    }

    private static short dueDayFor(AcceptRequest terms, LocalDate start) {
        if (terms != null && terms.dueDateDay() != null) {
            return terms.dueDateDay().shortValue();
        }
        return (short) start.getDayOfMonth();
    }

    /**
     * A bedspace room is occupied when its last free bed goes, and partly
     * occupied before that. A whole unit is simply occupied.
     */
    private void markOccupied(Unit unit, Bed bed) {
        if (bed == null) {
            unit.markLetEntire();
            units.save(unit);
            return;
        }

        bed.markOccupied();
        beds.saveAndFlush(bed);

        // Recomputed from every bed rather than reasoned about: the unit's
        // status has to agree with what is actually let, and counting is the
        // only way that stays true as beds are added and removed.
        List<Bed> siblings = beds.findByUnitIdOrderByBedLabelAsc(unit.getId());
        boolean anyVacant = siblings.stream()
                .anyMatch(other -> other.getStatus() == BedStatus.VACANT);
        boolean anyOccupied = siblings.stream()
                .anyMatch(other -> other.getStatus() == BedStatus.OCCUPIED);
        unit.reflectBedOccupancy(anyVacant, anyOccupied);
        units.save(unit);
    }

    /**
     * Saying yes takes on a tenant, so a locked property may not.
     */
    /** "Bed 1 in 2B", or "unit 101" — how a person would say it. */
    private static String slotWords(Unit unit, Bed bed) {
        return bed == null
                ? "unit " + unit.getUnitNumber()
                : bed.getBedLabel() + " in " + unit.getUnitNumber();
    }

    /** "5th", not "5". A due date read as "the 5" looks like a bug. */
    private static String ordinal(int day) {
        if (day >= 11 && day <= 13) {
            return day + "th";
        }
        return switch (day % 10) {
            case 1 -> day + "st";
            case 2 -> day + "nd";
            case 3 -> day + "rd";
            default -> day + "th";
        };
    }

    private RentalRequest pendingRequestToAccept(UUID requestId, UUID landlordId) {
        RentalRequest request = pendingRequest(requestId);
        access.writable(request.getPropertyId(), landlordId);
        return request;
    }

    /**
     * Saying no is allowed even while locked.
     *
     * <p>The tenant waiting for an answer is not the one who owes Lizmo money.
     * Blocking this would leave their request PENDING for ever, on a room they
     * could be looking for elsewhere -- punishing the only person here who has
     * done nothing and can do nothing.
     */
    private RentalRequest pendingRequestToDecline(UUID requestId, UUID landlordId) {
        RentalRequest request = pendingRequest(requestId);
        access.reducible(request.getPropertyId(), landlordId);
        return request;
    }

    private RentalRequest pendingRequest(UUID requestId) {
        RentalRequest request = requests.findById(requestId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such request."));

        if (!request.isPending()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That request has already been answered.");
        }
        return request;
    }

    private LeaseResponse describe(Lease lease, Unit unit, Bed bed) {
        Property property = properties.findById(unit.getPropertyId()).orElse(null);
        String tenantName = users.findById(lease.getTenantId())
                .map(user -> user.getName())
                .orElse(null);

        return LeaseResponse.of(
                lease,
                tenantName,
                unit.getPropertyId(),
                property == null ? null : property.getName(),
                unit.getUnitNumber(),
                bed == null ? null : bed.getBedLabel());
    }

    private static ApiException unavailable(String message) {
        return new ApiException(ErrorCode.SLOT_UNAVAILABLE, message);
    }
}
