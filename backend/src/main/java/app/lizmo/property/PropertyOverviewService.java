package app.lizmo.property;

import app.lizmo.billing.BillingPeriod;
import app.lizmo.billing.BillingPeriodRepository;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.security.CurrentUser;
import app.lizmo.user.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * One building at a glance, for its landlord: how full it is, what is owed
 * late, and each unit's beds, let or vacant.
 *
 * <p>Read as it stands. Months not yet written for a tenancy nobody has opened
 * are not written here: this is a screen somebody scrolls, not the dashboard
 * that brings the ledger up to date.
 */
@Service
public class PropertyOverviewService {

    private static final ZoneId PHILIPPINES = ZoneId.of("Asia/Manila");

    private final PropertyAccess access;
    private final UnitRepository units;
    private final BedRepository beds;
    private final LeaseRepository leases;
    private final BillingPeriodRepository periods;
    private final UserRepository users;
    private final Clock clock;

    public PropertyOverviewService(
            PropertyAccess access,
            UnitRepository units,
            BedRepository beds,
            LeaseRepository leases,
            BillingPeriodRepository periods,
            UserRepository users,
            Clock clock) {
        this.access = access;
        this.units = units;
        this.beds = beds;
        this.leases = leases;
        this.periods = periods;
        this.users = users;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public PropertyOverview of(UUID propertyId, UUID landlordId) {
        access.readable(propertyId, landlordId);
        LocalDate today = LocalDate.now(clock.withZone(PHILIPPINES));

        int occupied = 0;
        int rentable = 0;
        BigDecimal overdue = BigDecimal.ZERO;
        List<UnitOverview> rows = new ArrayList<>();

        for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(propertyId)) {
            boolean shut = unit.getStatus() == UnitStatus.MAINTENANCE;
            List<Lease> living = leases.findByUnitIdAndStatus(unit.getId(), LeaseStatus.ACTIVE);

            int lateTenancies = 0;
            for (Lease lease : living) {
                BigDecimal late = BigDecimal.ZERO;
                for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(lease.getId())) {
                    if (period.isOverdue(today)) {
                        late = late.add(period.outstanding());
                    }
                }
                if (late.signum() > 0) {
                    lateTenancies++;
                    overdue = overdue.add(late);
                }
            }

            List<BedState> spaces = new ArrayList<>();
            String tenantName = null;
            if (unit.getRentalMode() == RentalMode.WHOLE_UNIT) {
                boolean let = !living.isEmpty();
                if (let) {
                    tenantName = users.findById(living.get(0).getTenantId())
                            .map(user -> user.getName()).orElse(null);
                }
                if (!shut) {
                    rentable++;
                    if (let) {
                        occupied++;
                    }
                }
            } else {
                for (Bed bed : beds.findByUnitIdOrderByBedLabelAsc(unit.getId())) {
                    if (shut || bed.getStatus() == BedStatus.MAINTENANCE) {
                        continue;
                    }
                    rentable++;
                    if (bed.isOccupied()) {
                        occupied++;
                    }
                    spaces.add(new BedState(bed.getBedLabel(), bed.isOccupied()));
                }
            }

            rows.add(new UnitOverview(
                    unit.getId(),
                    unit.getUnitNumber(),
                    unit.getFloor(),
                    unit.getRentalMode(),
                    unit.getStatus(),
                    unit.getRent(),
                    spaces,
                    tenantName,
                    readyFrom(unit, today),
                    lateTenancies));
        }

        return new PropertyOverview(occupied, rentable, rentable - occupied, overdue, rows);
    }

    /** A day still to come; a day gone by is ready now, and says nothing. */
    private static LocalDate readyFrom(Unit unit, LocalDate today) {
        LocalDate ready = unit.getReadyFrom();
        return ready != null && ready.isAfter(today) ? ready : null;
    }

    @Schema(description = "One building at a glance, for its landlord")
    public record PropertyOverview(
            @Schema(description = "Spaces let: beds, and whole units counted as one")
            int occupied,
            @Schema(description = "Spaces that can be let: out of service ones are not")
            int rentable,
            int vacant,
            @Schema(description = "What is owed late across every tenancy here")
            BigDecimal overdueTotal,
            List<UnitOverview> units) {
    }

    @Schema(description = "A unit as its property screen shows it")
    public record UnitOverview(
            UUID id,
            String unitNumber,
            String floor,
            RentalMode rentalMode,
            UnitStatus status,
            @Schema(description = "Per bed for a bedspace room, for the unit otherwise")
            BigDecimal rent,
            @Schema(description = "Each rentable bed, let or not. Empty for a whole unit")
            List<BedState> beds,
            @Schema(description = "Who a whole unit is let to, when it is")
            String tenantName,
            @Schema(description = "When its vacant space is ready, if not now")
            LocalDate readyFrom,
            @Schema(description = "Tenancies in it with rent owed late")
            int overdueTenancies) {
    }

    @Schema(description = "One bed in a bedspace room")
    public record BedState(String label, boolean let) {
    }

    /** The endpoint, with the rest of a property's reads. */
    @RestController
    @Tag(name = "Properties")
    public static class Controller {

        private final PropertyOverviewService overview;
        private final CurrentUser currentUser;

        public Controller(PropertyOverviewService overview, CurrentUser currentUser) {
            this.overview = overview;
            this.currentUser = currentUser;
        }

        @GetMapping("/api/v1/properties/{id}/overview")
        @Operation(operationId = "getPropertyOverview", summary = "A building at a glance",
                description = "How full it is, what is owed late, and each unit's beds.")
        @ApiResponse(responseCode = "200", description = "The overview",
                content = @Content(schema = @Schema(implementation = PropertyOverview.class)))
        public PropertyOverview get(@PathVariable UUID id) {
            return overview.of(id, currentUser.requireId());
        }
    }
}
