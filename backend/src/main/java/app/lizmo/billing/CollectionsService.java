package app.lizmo.billing;

import app.lizmo.billing.dto.CollectionsSummary;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.user.UserRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Rent across a whole portfolio.
 *
 * <p>The three questions a landlord opens the app for: how much is owed me,
 * how much has come in, and who is behind. Everything here is read from the
 * same billing periods the per-tenancy screens show, so the dashboard and a
 * tenant's own page can never disagree about the same money.
 *
 * <p>Months are brought up to date as a side effect of asking, the same way
 * they are anywhere else. Without that, a landlord who has not opened a
 * particular tenancy this month would see a dashboard missing it.
 */
@Service
public class CollectionsService {

    private final PropertyRepository properties;
    private final UnitRepository units;
    private final LeaseRepository leases;
    private final BillingPeriodRepository periods;
    private final PaymentRepository payments;
    private final UserRepository users;
    private final app.lizmo.property.BedRepository beds;
    private final BillingService billing;
    private final Clock clock;

    public CollectionsService(
            PropertyRepository properties,
            UnitRepository units,
            LeaseRepository leases,
            BillingPeriodRepository periods,
            PaymentRepository payments,
            UserRepository users,
            app.lizmo.property.BedRepository beds,
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

    @Transactional
    public CollectionsSummary forLandlord(UUID landlordId) {
        LocalDate today = LocalDate.now(clock);
        YearMonth thisMonth = YearMonth.from(today);

        List<Lease> live = liveLeases(landlordId);

        // Brought up to date first. A landlord who has not opened a particular
        // tenant this month would otherwise see a dashboard that quietly left
        // them out.
        for (Lease lease : live) {
            billing.catchUp(lease, today);
        }

        BigDecimal dueThisMonth = BigDecimal.ZERO;
        BigDecimal collectedThisMonth = BigDecimal.ZERO;
        BigDecimal outstanding = BigDecimal.ZERO;
        List<Behind> behind = new ArrayList<>();

        BigDecimal depositsHeld = BigDecimal.ZERO;

        for (Lease lease : live) {
            BigDecimal owedOnThisLease = BigDecimal.ZERO;
            BigDecimal depositOwed = BigDecimal.ZERO;
            int monthsLate = 0;
            LocalDate oldest = null;

            for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(
                    lease.getId())) {

                // Held, not earned: kept out of every rent figure, and counted
                // on its own.
                if (period.isDeposit()) {
                    depositsHeld = depositsHeld.add(period.getAmountPaid());
                    if (period.isOverdue(today)) {
                        depositOwed = depositOwed.add(period.outstanding());
                    }
                    continue;
                }

                // "This month" means the month rent fell due in, not the month
                // the period covers. A tenancy running the 3rd to the 2nd
                // straddles two calendar months, and the due date is the one
                // both sides think of as the deadline.
                if (YearMonth.from(period.getDueDate()).equals(thisMonth)) {
                    dueThisMonth = dueThisMonth.add(period.getAmountDue());
                    collectedThisMonth = collectedThisMonth.add(period.getAmountPaid());
                }

                BigDecimal left = period.outstanding();
                if (left.compareTo(BigDecimal.ZERO) > 0) {
                    owedOnThisLease = owedOnThisLease.add(left);
                }
                if (period.isOverdue(today)) {
                    monthsLate++;
                    if (oldest == null || period.getDueDate().isBefore(oldest)) {
                        oldest = period.getDueDate();
                    }
                }
            }

            outstanding = outstanding.add(owedOnThisLease);

            // A deposit not received after move-in is something to chase, so
            // the tenant is listed -- with it said apart from the rent.
            if (monthsLate > 0 || depositOwed.signum() > 0) {
                behind.add(new Behind(lease, owedOnThisLease, monthsLate, oldest, depositOwed));
            }
        }

        List<Waiting> waiting = waitingOn(live);

        // Bed labels for every row at once. A landlord with forty beds in
        // arrears would otherwise make forty queries to render one screen.
        Map<UUID, String> bedLabels = new HashMap<>();
        List<UUID> bedIds = java.util.stream.Stream.concat(
                        behind.stream().map(Behind::lease),
                        waiting.stream().map(Waiting::lease))
                .map(Lease::getBedId)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
        if (!bedIds.isEmpty()) {
            beds.findAllById(bedIds).forEach(
                    bed -> bedLabels.put(bed.getId(), bed.getBedLabel()));
        }

        List<CollectionsSummary.ArrearsRow> arrears = new ArrayList<>();
        for (Behind row : behind) {
            arrears.add(arrearsRow(row, bedLabels));
        }

        // Worst first: the tenant furthest behind is the one a landlord needs
        // to deal with, and a list sorted by anything else buries them.
        arrears.sort(Comparator
                .comparingInt(CollectionsSummary.ArrearsRow::monthsLate).reversed()
                .thenComparing(CollectionsSummary.ArrearsRow::outstanding,
                        Comparator.reverseOrder()));

        List<CollectionsSummary.AwaitingRow> awaiting = new ArrayList<>();
        for (Waiting row : waiting) {
            awaiting.add(awaitingRow(row, bedLabels));
        }

        // Oldest first: the tenant who has waited longest for an answer is the
        // one most likely to be wondering whether they were believed. By when
        // they told the app rather than the date they gave, which is how long
        // they have actually been waiting.
        awaiting.sort(Comparator.comparing(
                CollectionsSummary.AwaitingRow::declaredAt,
                Comparator.nullsLast(Comparator.naturalOrder())));

        return new CollectionsSummary(
                dueThisMonth,
                collectedThisMonth,
                outstanding,
                awaiting.size(),
                arrears.size(),
                arrears,
                awaiting,
                depositsHeld);
    }

    /**
     * Tenant claims waiting for this landlord to answer.
     *
     * <p>The one part of the dashboard about the landlord's own behaviour
     * rather than their tenants'.
     */
    private List<Waiting> waitingOn(List<Lease> live) {
        List<Waiting> waiting = new ArrayList<>();
        for (Lease lease : live) {
            for (Payment payment : payments.findByLeaseIdOrderByPaymentDateDesc(
                    lease.getId())) {
                if (payment.getStatus() == PaymentStatus.PENDING_VERIFICATION) {
                    waiting.add(new Waiting(lease, payment));
                }
            }
        }
        return waiting;
    }

    /** A claim waiting on the landlord, before it has been dressed up. */
    private record Waiting(Lease lease, Payment payment) {
    }

    private CollectionsSummary.AwaitingRow awaitingRow(
            Waiting row, Map<UUID, String> bedLabels) {

        Lease lease = row.lease();
        Unit unit = units.findById(lease.getUnitId()).orElse(null);
        Property property = unit == null ? null
                : properties.findById(unit.getPropertyId()).orElse(null);

        return new CollectionsSummary.AwaitingRow(
                lease.getId(),
                row.payment().getId(),
                users.findById(lease.getTenantId()).map(user -> user.getName()).orElse(null),
                property == null ? null : property.getName(),
                unit == null ? null : unit.getUnitNumber(),
                lease.getBedId() == null ? null : bedLabels.get(lease.getBedId()),
                row.payment().getAmountPaid(),
                row.payment().getPaymentDate(),
                row.payment().getSentTo(),
                row.payment().getCreatedAt());
    }

    /**
     * Every active tenancy on this landlord's properties.
     *
     * <p>Active only. Rent owed by somebody who moved out is a debt, not a
     * collection problem, and mixing the two would make the dashboard read
     * worse every time a tenancy ended badly.
     */
    private List<Lease> liveLeases(UUID landlordId) {
        List<Lease> live = new ArrayList<>();
        for (Property property : properties.findByLandlordIdOrderByNameAsc(landlordId)) {
            for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(property.getId())) {
                live.addAll(leases.findByUnitIdAndStatus(unit.getId(), LeaseStatus.ACTIVE));
            }
        }
        return live;
    }

    /** A tenancy in arrears, before it has been dressed up for the screen. */
    private record Behind(
            Lease lease, BigDecimal owed, int monthsLate, LocalDate oldest,
            BigDecimal depositOwed) {
    }

    private CollectionsSummary.ArrearsRow arrearsRow(
            Behind row, Map<UUID, String> bedLabels) {

        Lease lease = row.lease();
        Unit unit = units.findById(lease.getUnitId()).orElse(null);
        Property property = unit == null ? null
                : properties.findById(unit.getPropertyId()).orElse(null);

        return new CollectionsSummary.ArrearsRow(
                lease.getId(),
                users.findById(lease.getTenantId()).map(user -> user.getName()).orElse(null),
                property == null ? null : property.getName(),
                unit == null ? null : unit.getUnitNumber(),
                lease.getBedId() == null ? null : bedLabels.get(lease.getBedId()),
                row.owed(),
                row.monthsLate(),
                row.oldest(),
                row.depositOwed());
    }

}
