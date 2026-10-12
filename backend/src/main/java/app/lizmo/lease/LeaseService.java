package app.lizmo.lease;

import app.lizmo.common.ApiException;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.billing.BillingPeriod;
import app.lizmo.billing.BillingPeriodRepository;
import app.lizmo.common.ErrorCode;
import app.lizmo.inquiry.InquiryService;
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
import java.math.BigDecimal;
import java.time.Clock;
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

    /** So a tenant is told their tenancy ended rather than discovering it. */
    private final NotificationService notifications;

    /** So the conversation stops calling them a tenant once they are not. */
    private final InquiryService conversations;

    /** The deposit charge, to check a refund against what was received. */
    private final BillingPeriodRepository periods;

    private final Clock clock;

    public LeaseService(
            LeaseRepository leases,
            PropertyAccess access,
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            UserRepository users,
            NotificationService notifications,
            InquiryService conversations,
            BillingPeriodRepository periods,
            Clock clock) {
        this.leases = leases;
        this.access = access;
        this.properties = properties;
        this.units = units;
        this.beds = beds;
        this.users = users;
        this.notifications = notifications;
        this.conversations = conversations;
        this.periods = periods;
        this.clock = clock;
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
     * Everyone renting from this landlord, across all their properties.
     *
     * <p>Here rather than in the app, which would otherwise have to fetch the
     * properties and then ask each one in turn -- a request count that grows
     * with the portfolio, on a screen that is the first thing a landlord opens.
     *
     * <p>Active only, like {@link #forProperty}: this answers "who is living in
     * my buildings", and somebody who moved out last year is not.
     */
    @Transactional(readOnly = true)
    public List<LeaseResponse> forLandlord(UUID landlordId) {
        List<LeaseResponse> described = new ArrayList<>();
        for (Property property : properties.findByLandlordIdOrderByNameAsc(landlordId)) {
            for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(property.getId())) {
                for (Lease lease :
                        leases.findByUnitIdAndStatus(unit.getId(), LeaseStatus.ACTIVE)) {
                    described.add(describe(lease));
                }
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

        // Reducible, not writable: ending a tenancy is allowed even when the
        // property is locked for an unpaid invoice. It is the write that
        // *lowers* what the landlord owes, and blocking it would mean billing
        // for a bed they are not allowed to mark empty -- while the tenant who
        // moved out keeps seeing an active lease.
        access.reducible(unit.getPropertyId(), landlordId);

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

        BigDecimal received = depositReceived(lease);
        if (command != null && command.depositReturned() != null
                && received != null
                && command.depositReturned().compareTo(received) > 0) {
            // Giving back more than was taken is a typo, not a generosity the
            // ledger should record silently. Measured against what actually
            // came in, now that a deposit is paid and confirmed: a tenant who
            // handed over P2000 of P5000 cannot be given P5000 back.
            boolean partly = lease.getDepositAmount() != null
                    && received.compareTo(lease.getDepositAmount()) < 0;
            throw new ApiException(ErrorCode.VALIDATION_FAILED, partly
                    ? "You received P%s of the deposit, so you cannot return more than that."
                            .formatted(received.stripTrailingZeros().toPlainString())
                    : "You cannot return more than the deposit that was taken.");
        }

        boolean terminated = command != null && Boolean.TRUE.equals(command.terminated());
        lease.close(terminated ? LeaseStatus.TERMINATED : LeaseStatus.ENDED, on);

        if (command != null) {
            lease.settleDeposit(command.depositReturned(), command.depositSettlement());
            lease.recordEndReason(command.reason());
        }

        leases.save(lease);

        freeTheSlot(unit, lease.getBedId());

        // After the save, so the lease just ended no longer counts as one the
        // tenant still holds in this building.
        conversations.tenancyEnded(lease.getTenantId(), unit.getPropertyId());

        // Carrying the settlement, because "you got P4,500 of your P5,000
        // back, and here is why" is the whole of what a tenant wants to know
        // on the day they move out.
        notifications.raise(
                lease.getTenantId(),
                NotificationType.LEASE_ENDED,
                "Your tenancy has ended",
                endedMessage(lease, on),
                NotificationEntityType.LEASE,
                lease.getId());

        return describe(lease);
    }

    /**
     * Sets, moves or takes away the date a lease is meant to end.
     *
     * <p>Allowed while the property is locked: an end date bills nothing, and
     * a landlord extending a tenant who is staying is answering for a tenancy
     * that already exists.
     *
     * <p>The tenant is told, because a lease that changed under them is
     * exactly what they would want to know -- and an extension is usually
     * the answer to something they asked.
     */
    @Transactional
    public LeaseResponse changeTerm(UUID leaseId, UUID landlordId, LocalDate endsOn) {
        Lease lease = leases.findById(leaseId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such lease."));
        Unit unit = units.findById(lease.getUnitId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such unit."));
        access.reducible(unit.getPropertyId(), landlordId);

        if (!lease.isActive()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That lease has already ended.");
        }
        if (endsOn != null && endsOn.isBefore(LocalDate.now(clock))) {
            // A date already gone is not a plan. If they have moved out, that
            // is ending the tenancy, which frees the room; this would not.
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Pick a date from today on. If they have already left, end the tenancy.");
        }
        if (endsOn != null && !endsOn.isAfter(lease.getStartDate())) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "The lease has to end after it starts.");
        }

        LocalDate was = lease.getTermEndsOn();
        if (java.util.Objects.equals(was, endsOn)) {
            return describe(lease);
        }
        lease.endTermOn(endsOn);
        leases.save(lease);

        notifications.raise(
                lease.getTenantId(),
                NotificationType.LEASE_EXPIRING,
                termChangedTitle(was, endsOn),
                endsOn == null
                        ? "It carries on month to month, as long as you both want."
                        : "Your lease now runs until %s.".formatted(LeaseDates.spoken(endsOn)),
                NotificationEntityType.LEASE,
                lease.getId());

        return describe(lease);
    }

    private static String termChangedTitle(LocalDate was, LocalDate now) {
        if (now == null) {
            return "Your lease no longer has an end date";
        }
        if (was != null && now.isAfter(was)) {
            return "Your lease was extended";
        }
        return "Your lease has an end date";
    }

    /**
     * What the tenant is told, which depends on whether money changed hands.
     *
     * <p>Three sentences at most. A landlord who settled the deposit has said
     * something worth passing on verbatim; one who has not should not have
     * words invented on their behalf.
     */
    private static String endedMessage(Lease lease, java.time.LocalDate on) {
        StringBuilder message = new StringBuilder(
                "Your tenancy ended on %s.".formatted(on));

        if (lease.getDepositReturned() != null) {
            message.append(" Deposit returned: P%s."
                    .formatted(lease.getDepositReturned()
                            .stripTrailingZeros().toPlainString()));
        }
        if (org.springframework.util.StringUtils.hasText(lease.getDepositSettlement())) {
            message.append(' ').append(lease.getDepositSettlement().trim());
        }
        return message.toString();
    }

    /**
     * Hands the bed or unit back to the vacancy list.
     *
     * <p>Recomputed from what is actually let rather than assumed: a room with
     * three beds loses one tenant and is still partly occupied, and only
     * counting tells you which.
     */
    /**
     * The deposit actually received: what was confirmed against its charge.
     *
     * <p>A lease charged at move-in whose charge was never written -- nobody
     * opened its billing before it ended -- has had nothing confirmed, because
     * nothing can be paid against a charge that does not exist. Only a lease
     * from before deposits were charged, with no charge recorded, falls back to
     * the figure on the lease.
     */
    private BigDecimal depositReceived(Lease lease) {
        for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(lease.getId())) {
            if (period.isDeposit()) {
                return period.getAmountPaid();
            }
        }
        if (lease.isChargedAtMoveIn() && lease.getDepositAmount() != null) {
            return BigDecimal.ZERO;
        }
        return lease.getDepositAmount();
    }

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
