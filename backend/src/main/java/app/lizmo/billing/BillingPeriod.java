package app.lizmo.billing;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * One month of rent on one tenancy.
 *
 * <p>The unit the whole of rent collection is counted in: what was owed, what
 * has come in, and when it was due. A tenancy of eight months is eight of
 * these, generated from the lease rather than entered by anybody.
 *
 * <p>{@code amountPaid} is kept in step with the confirmed payments behind it
 * rather than derived on read. Two reasons: the roll-up is what every screen
 * shows and summing payments per period would be a query per row, and a
 * partial payment has to be visible without opening anything.
 */
@Entity
@Table(name = "billing_periods")
public class BillingPeriod {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "lease_id", nullable = false, updatable = false)
    private UUID leaseId;

    /** "October 2026". What a person calls the month, so no screen has to format one. */
    @Column(name = "period_label", nullable = false)
    private String periodLabel;

    @Column(name = "period_start", nullable = false)
    private LocalDate periodStart;

    @Column(name = "period_end", nullable = false)
    private LocalDate periodEnd;

    @Column(name = "due_date", nullable = false)
    private LocalDate dueDate;

    @Column(name = "amount_due", nullable = false)
    private BigDecimal amountDue;

    @Column(name = "amount_paid", nullable = false)
    private BigDecimal amountPaid = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BillingPeriodStatus status = BillingPeriodStatus.UNPAID;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected BillingPeriod() {
    }

    public BillingPeriod(
            UUID leaseId,
            String periodLabel,
            LocalDate periodStart,
            LocalDate periodEnd,
            LocalDate dueDate,
            BigDecimal amountDue) {
        this.leaseId = leaseId;
        this.periodLabel = periodLabel;
        this.periodStart = periodStart;
        this.periodEnd = periodEnd;
        this.dueDate = dueDate;
        this.amountDue = amountDue;
        this.amountPaid = BigDecimal.ZERO;
        this.status = BillingPeriodStatus.UNPAID;
    }

    /**
     * Adds confirmed money to this month.
     *
     * <p>Takes a delta rather than a total so that two payments cannot
     * overwrite one another, and recomputes the status here so that no caller
     * can leave a period marked UNPAID with money against it.
     */
    public void credit(BigDecimal amount) {
        this.amountPaid = this.amountPaid.add(amount);
        this.status = statusFor(amountPaid, amountDue);
        this.updatedAt = Instant.now();
    }

    private static BillingPeriodStatus statusFor(BigDecimal paid, BigDecimal due) {
        if (paid.compareTo(BigDecimal.ZERO) <= 0) {
            return BillingPeriodStatus.UNPAID;
        }
        // Overpayment counts as paid rather than as a fourth state: somebody
        // who handed over an extra hundred pesos has not created a problem.
        return paid.compareTo(due) >= 0
                ? BillingPeriodStatus.PAID
                : BillingPeriodStatus.PARTIALLY_PAID;
    }

    /**
     * Whether this month is late, as of a given day.
     *
     * <p>Asked rather than stored. A period that fell due yesterday is overdue
     * today without anything having run overnight, and a stored flag would be
     * wrong until it did.
     */
    public boolean isOverdue(LocalDate today) {
        return status != BillingPeriodStatus.PAID && today.isAfter(dueDate);
    }

    public BigDecimal outstanding() {
        BigDecimal left = amountDue.subtract(amountPaid);
        return left.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : left;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
    }

    public UUID getId() {
        return id;
    }

    public UUID getLeaseId() {
        return leaseId;
    }

    public String getPeriodLabel() {
        return periodLabel;
    }

    public LocalDate getPeriodStart() {
        return periodStart;
    }

    public LocalDate getPeriodEnd() {
        return periodEnd;
    }

    public LocalDate getDueDate() {
        return dueDate;
    }

    public BigDecimal getAmountDue() {
        return amountDue;
    }

    public BigDecimal getAmountPaid() {
        return amountPaid;
    }

    public BillingPeriodStatus getStatus() {
        return status;
    }
}
