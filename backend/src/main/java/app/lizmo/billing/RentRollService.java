package app.lizmo.billing;

import app.lizmo.billing.dto.BillingPeriodResponse;
import app.lizmo.billing.dto.RentRoll;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.property.BedRepository;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.user.UserRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Rent for one month, tenancy by tenancy, across a whole portfolio.
 *
 * <p>The ledger a landlord kept in a notebook: every room, what it owed that
 * month, and whether it came in. Read from the same billing periods the
 * tenant's own screen and the dashboard use, so no two screens can disagree
 * about the same money.
 *
 * <p>Ownership is by construction. Only properties found by this owner are
 * read, so another landlord's tenancies can never appear.
 */
@Service
public class RentRollService {

    private final PropertyRepository properties;
    private final UnitRepository units;
    private final LeaseRepository leases;
    private final BillingPeriodRepository periods;
    private final PaymentRepository payments;
    private final UserRepository users;
    private final BedRepository beds;
    private final BillingService billing;
    private final Clock clock;

    public RentRollService(
            PropertyRepository properties,
            UnitRepository units,
            LeaseRepository leases,
            BillingPeriodRepository periods,
            PaymentRepository payments,
            UserRepository users,
            BedRepository beds,
            BillingService billing,
            Clock clock) {
        this.properties = properties;
        this.units = units;
        this.leases = leases;
        this.periods = periods;
        this.payments = payments;
        this.users = users;
        this.beds = beds;
        this.billing = billing;
        this.clock = clock;
    }

    /**
     * @param month as {@code 2026-09}, or null for the month it is now.
     * @throws ApiException if the month is not a month.
     */
    @Transactional
    public RentRoll forLandlord(UUID landlordId, String month) {
        LocalDate today = LocalDate.now(clock);
        YearMonth asked = parse(month, today);

        List<Tenancy> tenancies = new ArrayList<>();
        for (Property property : properties.findByLandlordIdOrderByNameAsc(landlordId)) {
            for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(property.getId())) {
                // Every status, not only the live ones: somebody who moved out
                // in September still owed August.
                for (Lease lease : leases.findByUnitId(unit.getId())) {
                    tenancies.add(new Tenancy(property, unit, lease));
                }
            }
        }

        if (tenancies.isEmpty()) {
            return new RentRoll(asked.toString(), null,
                    BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, List.of());
        }

        // Every tenancy brought up to date first, ended ones included. Months
        // are only written when somebody reads them, so a tenancy ended before
        // anybody looked would otherwise never have its last month written,
        // and would vanish from the roll for the month it owed. Safe for an
        // ended tenancy: the schedule stops at its last day.
        for (Tenancy tenancy : tenancies) {
            billing.catchUp(tenancy.lease(), today);
        }

        // Rent only. A deposit is owed and confirmed like rent, but it is held
        // rather than earned, and a month's roll is the month's rent.
        List<BillingPeriod> everyPeriod = periods.findByLeaseIdIn(
                        tenancies.stream().map(tenancy -> tenancy.lease().getId()).toList())
                .stream()
                .filter(period -> !period.isDeposit())
                .toList();

        YearMonth earliest = everyPeriod.stream()
                .map(period -> YearMonth.from(period.getDueDate()))
                .min(Comparator.naturalOrder())
                .orElse(null);

        // The month a rent falls due in, not the month it covers: a tenancy
        // running the 3rd to the 2nd straddles two calendar months, and the
        // due date is the one both sides think of as the deadline.
        Map<UUID, List<BillingPeriod>> dueInMonth = new HashMap<>();
        for (BillingPeriod period : everyPeriod) {
            if (YearMonth.from(period.getDueDate()).equals(asked)) {
                dueInMonth.computeIfAbsent(period.getLeaseId(), id -> new ArrayList<>())
                        .add(period);
            }
        }

        // Names and bed labels for every row at once, rather than a query per
        // row on a screen that lists every room a landlord has.
        Map<UUID, String> names = new HashMap<>();
        users.findAllById(tenancies.stream()
                        .map(tenancy -> tenancy.lease().getTenantId())
                        .distinct()
                        .toList())
                .forEach(user -> names.put(user.getId(), user.getName()));

        Map<UUID, String> bedLabels = new HashMap<>();
        beds.findAllById(tenancies.stream()
                        .map(tenancy -> tenancy.lease().getBedId())
                        .filter(Objects::nonNull)
                        .distinct()
                        .toList())
                .forEach(bed -> bedLabels.put(bed.getId(), bed.getBedLabel()));

        BigDecimal due = BigDecimal.ZERO;
        BigDecimal collected = BigDecimal.ZERO;
        BigDecimal outstanding = BigDecimal.ZERO;
        List<Ordered> rows = new ArrayList<>();

        for (int position = 0; position < tenancies.size(); position++) {
            Tenancy tenancy = tenancies.get(position);
            Lease lease = tenancy.lease();

            for (BillingPeriod period : dueInMonth.getOrDefault(lease.getId(), List.of())) {
                due = due.add(period.getAmountDue());
                collected = collected.add(period.getAmountPaid());
                outstanding = outstanding.add(period.outstanding());

                List<RentRoll.WaitingPayment> waiting = payments
                        .findByBillingPeriodIdOrderByCreatedAtAsc(period.getId()).stream()
                        .filter(payment -> payment.getStatus() == PaymentStatus.PENDING_VERIFICATION)
                        .map(payment -> new RentRoll.WaitingPayment(
                                payment.getId(),
                                payment.getAmountPaid(),
                                payment.getPaymentDate(),
                                payment.getPaymentMethod(),
                                payment.getRemarks(),
                                payment.getSentTo()))
                        .toList();

                String bedLabel = lease.getBedId() == null ? null : bedLabels.get(lease.getBedId());

                rows.add(new Ordered(position, bedLabel, new RentRoll.RentRollRow(
                        tenancy.property().getId(),
                        tenancy.property().getName(),
                        lease.getId(),
                        lease.isActive(),
                        names.get(lease.getTenantId()),
                        tenancy.unit().getUnitNumber(),
                        bedLabel,
                        BillingPeriodResponse.of(period, today),
                        waiting)));
            }
        }

        // Tenancies were gathered property by property and unit by unit. Within
        // a unit, beds in label order -- the order they are on the door.
        rows.sort(Comparator
                .comparing((Ordered row) -> row.row().propertyName(),
                        Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(row -> row.row().unitNumber(),
                        Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(Ordered::bedLabel,
                        Comparator.nullsFirst(Comparator.naturalOrder()))
                .thenComparingInt(Ordered::position));

        return new RentRoll(
                asked.toString(),
                earliest == null ? null : earliest.toString(),
                due,
                collected,
                outstanding,
                rows.stream().map(Ordered::row).toList());
    }

    private static YearMonth parse(String month, LocalDate today) {
        if (month == null || month.isBlank()) {
            return YearMonth.from(today);
        }
        try {
            return YearMonth.parse(month.trim());
        } catch (DateTimeParseException wrong) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A month looks like 2026-09.");
        }
    }

    private record Tenancy(Property property, Unit unit, Lease lease) {
    }

    private record Ordered(int position, String bedLabel, RentRoll.RentRollRow row) {
    }
}
