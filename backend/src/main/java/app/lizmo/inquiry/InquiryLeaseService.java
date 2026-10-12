package app.lizmo.inquiry;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.lease.dto.AcceptRequest;
import app.lizmo.lease.dto.LeaseResponse;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.property.Bed;
import app.lizmo.property.BedRepository;
import app.lizmo.property.BedStatus;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyAccess;
import app.lizmo.property.RentalMode;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.property.UnitStatus;
import app.lizmo.user.LeaseReadiness;
import app.lizmo.user.UserRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Writing the tenancy the two of them have agreed on.
 *
 * <p>The landlord does this from inside the conversation, which is the only
 * place either of them has been talking. It is still the one thing in the
 * system that creates a lease, and still one transaction: the room is checked
 * free, the lease is written, and the room is marked taken together or not at
 * all.
 *
 * <p>Nothing is superseded. A thread is about a building rather than a room,
 * so somebody else asking about the same place has not lost anything by this
 * -- the landlord may well have another room for them, and closing their
 * conversation would say otherwise.
 */
@Service
public class InquiryLeaseService {

    private final InquiryRepository inquiries;
    private final LeaseRepository leases;
    private final PropertyAccess access;
    private final UnitRepository units;
    private final BedRepository beds;
    private final UserRepository users;
    /** What a tenant must have on file before a tenancy may be written. */
    private final LeaseReadiness readiness;
    private final NotificationService notifications;
    private final Clock clock;

    public InquiryLeaseService(
            InquiryRepository inquiries,
            LeaseRepository leases,
            PropertyAccess access,
            UnitRepository units,
            BedRepository beds,
            UserRepository users,
            LeaseReadiness readiness,
            NotificationService notifications,
            Clock clock) {
        this.inquiries = inquiries;
        this.leases = leases;
        this.access = access;
        this.units = units;
        this.beds = beds;
        this.users = users;
        this.readiness = readiness;
        this.notifications = notifications;
        this.clock = clock;
    }

    @Transactional
    public LeaseResponse start(UUID inquiryId, UUID landlordId, AcceptRequest terms) {
        Inquiry inquiry = inquiries.findById(inquiryId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.NOT_FOUND, "No such conversation."));

        // Theirs, and not locked: taking on a tenant grows the account, and a
        // property behind on its Lizmo bill may not grow.
        Property property = access.writable(inquiry.getPropertyId(), landlordId);

        // A thread may produce several tenancies over the years -- a tenant
        // who left and came back is the same two people talking about the
        // same building -- but never two at once.
        if (leases.findByInquiryIdAndStatus(inquiryId, LeaseStatus.ACTIVE).isPresent()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "There is already a tenancy from this conversation.");
        }
        if (inquiry.getStatus() == InquiryStatus.CLOSED) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This conversation is closed.");
        }

        // The tenant never saw the rooms -- the floors show counts and prices,
        // not which room is which -- so the landlord names it here.
        Unit unit = chosenUnit(terms, property.getId());
        Bed bed = chosenBed(terms, unit);
        requireStillFree(unit, bed);

        // Here rather than when they asked: asking is a question, and this is
        // a tenancy. By now the landlord has spoken to them.
        readiness.require(inquiry.getTenantId());

        BigDecimal rent = rentFor(terms, unit, bed);
        LocalDate start = terms == null || terms.startDate() == null
                ? LocalDate.now(clock.withZone(ZoneId.systemDefault()))
                : terms.startDate();
        short dueDay = dueDayFor(terms, start);

        Lease lease = new Lease(
                inquiry.getTenantId(),
                unit.getId(),
                bed == null ? null : bed.getId(),
                rent,
                dueDay,
                start,
                inquiry.getId(),
                terms == null ? null : terms.depositAmount(),
                terms == null ? null : terms.advanceAmount());

        // Owed, paid and confirmed like rent, rather than assumed taken.
        lease.chargeAtMoveIn();
        requireWholeMonths(lease.getAdvanceAmount(), rent);

        try {
            lease = leases.saveAndFlush(lease);
        } catch (DataIntegrityViolationException raced) {
            // Two taps, or two rooms being given away at once. The partial
            // unique index settled it; the loser is told the truth rather
            // than shown a 500.
            throw unavailable("Somebody else was given this one.");
        }

        inquiry.leased(clock.instant());
        inquiries.save(inquiry);

        markOccupied(unit, bed);

        // The terms are in the message on purpose: this is the first moment
        // the tenant sees what was written down, and the rent may not be the
        // one they were looking at when they asked.
        notifications.raise(
                inquiry.getTenantId(),
                NotificationType.REQUEST_ACCEPTED,
                "You have somewhere to live",
                "You have %s. Rent is P%s a month, due on the %s, from %s."
                        .formatted(
                                slotWords(unit, bed),
                                rent.stripTrailingZeros().toPlainString(),
                                ordinal(dueDay),
                                start),
                NotificationEntityType.LEASE,
                lease.getId());

        return describe(lease, property, unit, bed);
    }

    // ---- the room ------------------------------------------------------------------

    private Unit chosenUnit(AcceptRequest terms, UUID propertyId) {
        UUID unitId = terms == null ? null : terms.unitId();
        if (unitId == null) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Choose which room to give them.");
        }

        Unit unit = units.findById(unitId).orElseThrow(
                () -> new ApiException(ErrorCode.NOT_FOUND, "No such unit."));
        // Somebody else's room, reached with an id from anywhere: not found,
        // as it reads everywhere else.
        if (!unit.getPropertyId().equals(propertyId)) {
            throw new ApiException(ErrorCode.NOT_FOUND, "No such unit.");
        }
        if (unit.getStatus() == UnitStatus.MAINTENANCE) {
            throw unavailable("That room is out of service.");
        }
        return unit;
    }

    private Bed chosenBed(AcceptRequest terms, Unit unit) {
        UUID bedId = terms == null ? null : terms.bedId();

        Bed bed = bedId == null
                ? null
                : beds.findById(bedId).orElseThrow(
                        () -> new ApiException(ErrorCode.NOT_FOUND, "No such bed."));
        if (bed != null && !bed.getUnitId().equals(unit.getId())) {
            throw new ApiException(ErrorCode.NOT_FOUND, "No such bed.");
        }
        // A shared room is let bed by bed: giving the whole of it to one
        // tenant would take beds off the market nobody agreed to.
        if (bed == null && unit.getRentalMode() == RentalMode.BEDSPACE) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That room is let bed by bed. Choose which bed to give them.");
        }
        return bed;
    }

    /**
     * Checked at the moment the tenancy is written, not when the conversation
     * started. A thread can be a fortnight old, and the room may have gone.
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
                    "Set a rent for this one before writing the lease.");
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

    private LeaseResponse describe(Lease lease, Property property, Unit unit, Bed bed) {
        return LeaseResponse.of(
                lease,
                users.findById(lease.getTenantId()).map(user -> user.getName()).orElse(null),
                property.getId(),
                property.getName(),
                unit.getUnitNumber(),
                bed == null ? null : bed.getBedLabel());
    }

    /** "Bed 1 in 2B", or "unit 101" -- how a person would say it. */
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

    /**
     * An advance pays for whole months: "P5000 covers August and September".
     *
     * <p>Refused otherwise, rather than rounded. P3000 on P2500 rent would
     * pay one month and leave P500 the app has nowhere to put -- money taken
     * and recorded nowhere.
     */
    private static void requireWholeMonths(BigDecimal advance, BigDecimal rent) {
        if (advance == null || advance.signum() <= 0 || rent == null || rent.signum() <= 0) {
            return;
        }
        if (advance.remainder(rent).signum() != 0) {
            BigDecimal one = rent.stripTrailingZeros();
            BigDecimal two = rent.multiply(BigDecimal.valueOf(2)).stripTrailingZeros();
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "An advance pays for whole months of rent: P%s or P%s, not P%s."
                            .formatted(one.toPlainString(), two.toPlainString(),
                                    advance.stripTrailingZeros().toPlainString()));
        }
    }

    private static ApiException unavailable(String message) {
        return new ApiException(ErrorCode.SLOT_UNAVAILABLE, message);
    }
}
