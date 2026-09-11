package app.lizmo.platform.billing;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * What one property owes Lizmo for one month.
 *
 * <p>An invoice in the code; a billing cycle in the table, which keeps its
 * original name. Per property rather than per landlord since V16, so a
 * landlord can check each invoice against that building's own income.
 *
 * <p>A snapshot, not a running meter. It counts the slots let on the day it was
 * raised, at the rates of that day, and both are stored on it: an invoice from
 * March must still explain itself in September.
 */
@Entity
@Table(name = "platform_billing_cycles")
public class PlatformInvoice {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "property_id", nullable = false, updatable = false)
    private UUID propertyId;

    @Column(name = "billing_date", nullable = false, updatable = false)
    private LocalDate billingDate;

    @Column(name = "due_date", nullable = false, updatable = false)
    private LocalDate dueDate;

    @Column(name = "occupied_units_count", nullable = false, updatable = false)
    private int occupiedUnits;

    @Column(name = "occupied_bedspaces_count", nullable = false, updatable = false)
    private int occupiedBeds;

    @Column(name = "unit_rate", nullable = false, updatable = false)
    private BigDecimal unitRate;

    @Column(name = "bed_rate", nullable = false, updatable = false)
    private BigDecimal bedRate;

    @Column(name = "amount_due", nullable = false, updatable = false)
    private BigDecimal amountDue;

    @Column(name = "amount_paid", nullable = false)
    private BigDecimal amountPaid = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PlatformInvoiceStatus status = PlatformInvoiceStatus.UNPAID;

    @Column(name = "overdue_warned_at")
    private Instant overdueWarnedAt;

    @Column(name = "locked_at")
    private Instant lockedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PlatformInvoice() {
    }

    public PlatformInvoice(
            UUID propertyId,
            LocalDate billingDate,
            int occupiedUnits,
            int occupiedBeds,
            BigDecimal unitRate,
            BigDecimal bedRate) {
        this.propertyId = propertyId;
        this.billingDate = billingDate;
        // Due on the day it is raised, as the spec has it. The grace period is
        // counted from here.
        this.dueDate = billingDate;
        this.occupiedUnits = occupiedUnits;
        this.occupiedBeds = occupiedBeds;
        this.unitRate = unitRate;
        this.bedRate = bedRate;
        this.amountDue = unitRate.multiply(BigDecimal.valueOf(occupiedUnits))
                .add(bedRate.multiply(BigDecimal.valueOf(occupiedBeds)));
    }

    /**
     * Money an admin has confirmed arrived.
     *
     * <p>The only thing that moves a balance. A landlord saying they paid is a
     * claim until then.
     */
    public void credit(BigDecimal amount) {
        this.amountPaid = this.amountPaid.add(amount);
        this.status = amountPaid.compareTo(amountDue) >= 0
                ? PlatformInvoiceStatus.PAID
                : PlatformInvoiceStatus.PARTIALLY_PAID;
    }

    /** What is still owed. Never negative: paying a little over creates no credit. */
    public BigDecimal outstanding() {
        BigDecimal left = amountDue.subtract(amountPaid);
        return left.signum() < 0 ? BigDecimal.ZERO : left;
    }

    public boolean isPaid() {
        return status == PlatformInvoiceStatus.PAID;
    }

    /** Past its due date with something still owed. */
    public boolean isOverdue(LocalDate today) {
        return !isPaid() && today.isAfter(dueDate);
    }

    public void markOverdueWarned(Instant at) {
        this.overdueWarnedAt = at;
    }

    /** Enforcement locked the property over this invoice. */
    public void markLocked(Instant at) {
        this.lockedAt = at;
    }

    /** The lock this invoice caused is lifted. */
    public void clearLock() {
        this.lockedAt = null;
    }

    @PrePersist
    @PreUpdate
    void touch() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    public UUID getId() {
        return id;
    }

    public UUID getPropertyId() {
        return propertyId;
    }

    public LocalDate getBillingDate() {
        return billingDate;
    }

    public LocalDate getDueDate() {
        return dueDate;
    }

    public int getOccupiedUnits() {
        return occupiedUnits;
    }

    public int getOccupiedBeds() {
        return occupiedBeds;
    }

    public BigDecimal getUnitRate() {
        return unitRate;
    }

    public BigDecimal getBedRate() {
        return bedRate;
    }

    public BigDecimal getAmountDue() {
        return amountDue;
    }

    public BigDecimal getAmountPaid() {
        return amountPaid;
    }

    public PlatformInvoiceStatus getStatus() {
        return status;
    }

    public Instant getOverdueWarnedAt() {
        return overdueWarnedAt;
    }

    public Instant getLockedAt() {
        return lockedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
