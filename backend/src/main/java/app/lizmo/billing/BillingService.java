package app.lizmo.billing;

import app.lizmo.billing.dto.BillingPeriodResponse;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeasePaperworkAccess;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * What a tenancy owes, month by month.
 *
 * <p>Periods are made on demand rather than by a scheduled job. Whenever
 * somebody opens the rent screen, any month that has begun and has no row yet
 * gets one. That needs no infrastructure, heals itself after any amount of
 * downtime, and makes a period nobody has looked at indistinguishable from one
 * that exists — which is the only property that matters.
 *
 * <p>The unique index on (lease_id, period_start) is what makes it safe. Two
 * taps arriving together both try to write October; one wins, the other is told
 * so by the database and reads what the winner wrote.
 */
@Service
public class BillingService {

    private final BillingPeriodRepository periods;
    private final PaymentRepository payments;
    private final LeasePaperworkAccess access;
    private final Clock clock;

    public BillingService(
            BillingPeriodRepository periods,
            PaymentRepository payments,
            LeasePaperworkAccess access,
            Clock clock) {
        this.periods = periods;
        this.payments = payments;
        this.access = access;
        this.clock = clock;
    }

    /** The rent on one tenancy, as the landlord who owns it sees it. */
    @Transactional
    public List<BillingPeriodResponse> forLandlord(UUID leaseId, UUID landlordId) {
        return describe(access.requireLandlord(leaseId, landlordId));
    }

    /** The same months, as the tenant living under them sees it. */
    @Transactional
    public List<BillingPeriodResponse> forTenant(UUID leaseId, UUID tenantId) {
        return describe(access.requireTenant(leaseId, tenantId));
    }

    private List<BillingPeriodResponse> describe(Lease lease) {
        LocalDate today = LocalDate.now(clock);
        catchUp(lease, today);

        return periods.findByLeaseIdOrderByPeriodStartAsc(lease.getId()).stream()
                .map(period -> BillingPeriodResponse.of(period, today))
                .toList();
    }

    /**
     * Writes any month that has begun and has no row yet.
     *
     * <p>Idempotent by construction: what exists is read first, and only the
     * gaps are written.
     *
     * <p>Package-visible so the dashboard can bring a whole portfolio up to
     * date before summing it. A landlord who has not opened a particular
     * tenancy this month would otherwise see totals that quietly left it out.
     */
    void catchUp(Lease lease, LocalDate today) {
        Set<LocalDate> already = new HashSet<>();
        for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(lease.getId())) {
            already.add(period.getPeriodStart());
        }

        boolean first = already.isEmpty();

        for (RentSchedule.Month month : RentSchedule.upTo(lease, today)) {
            if (already.contains(month.start())) {
                first = false;
                continue;
            }

            BillingPeriod period = new BillingPeriod(
                    lease.getId(),
                    month.label(),
                    month.start(),
                    month.end(),
                    month.due(),
                    month.amount());

            try {
                period = periods.saveAndFlush(period);
            } catch (DataIntegrityViolationException raced) {
                // Two screens opened at once. The unique index settled it, and
                // the month exists either way, which is all anybody wanted.
                continue;
            }

            if (first) {
                applyAdvance(lease, period);
            }
            first = false;
        }
    }

    /**
     * Rent paid before moving in pays the first month.
     *
     * <p>Ariel's call, and recorded as a payment rather than by simply marking
     * the period paid: amount_paid has to agree with the payments behind it, or
     * a tenant's history shows a month settled by nothing at all.
     *
     * <p>Only ever the first month. An advance larger than one month's rent
     * settles that month and stops — spilling it into later months would be a
     * guess about an agreement nobody wrote down.
     */
    private void applyAdvance(Lease lease, BillingPeriod period) {
        BigDecimal advance = lease.getAdvanceAmount();
        if (advance == null || advance.compareTo(BigDecimal.ZERO) <= 0) {
            return;
        }

        BigDecimal applied = advance.min(period.getAmountDue());

        Payment advanced = new Payment(
                lease.getId(),
                period.getId(),
                applied,
                lease.getStartDate(),
                PaymentMethod.ADVANCE,
                lease.getTenantId(),
                PaymentStatus.CONFIRMED,
                "Advance rent, paid before moving in.");
        advanced.toldAt(clock.instant());
        payments.save(advanced);

        period.credit(applied);
        periods.save(period);
    }
}
