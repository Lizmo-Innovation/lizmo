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
 * What a landlord owes Lizmo for one month, across everything they let.
 *
 * <p>One a month, itemised by property, and the only thing money arrives
 * against. The per-property figures live on its lines, which become invoices
 * when it is settled.
 *
 * <p>A snapshot: the slots let on the day it was raised, at that day's rates.
 * It does not follow later changes, so a bed let on the 3rd waits for the next
 * statement rather than appearing on this one.
 */
@Entity
@Table(name = "platform_statements")
public class PlatformStatement {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "landlord_id", nullable = false, updatable = false)
    private UUID landlordId;

    @Column(name = "billing_date", nullable = false, updatable = false)
    private LocalDate billingDate;

    @Column(name = "due_date", nullable = false, updatable = false)
    private LocalDate dueDate;

    @Column(name = "amount_due", nullable = false)
    private BigDecimal amountDue = BigDecimal.ZERO;

    @Column(name = "amount_paid", nullable = false)
    private BigDecimal amountPaid = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PlatformStatementStatus status = PlatformStatementStatus.UNPAID;

    @Column(name = "overdue_warned_at")
    private Instant overdueWarnedAt;

    @Column(name = "locked_at")
    private Instant lockedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PlatformStatement() {
    }

    public PlatformStatement(UUID landlordId, LocalDate billingDate) {
        this.landlordId = landlordId;
        this.billingDate = billingDate;
        // Due on the day it is raised, as the spec has it. The grace period is
        // counted from here.
        this.dueDate = billingDate;
    }

    /** Set once, as the lines are written. */
    public void total(BigDecimal amount) {
        this.amountDue = amount;
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
                ? PlatformStatementStatus.PAID
                : PlatformStatementStatus.PARTIALLY_PAID;
    }

    /** What is still owed. Never negative: paying a little over creates no credit. */
    public BigDecimal outstanding() {
        BigDecimal left = amountDue.subtract(amountPaid);
        return left.signum() < 0 ? BigDecimal.ZERO : left;
    }

    public boolean isPaid() {
        return status == PlatformStatementStatus.PAID;
    }

    /** Past its due date with something still owed. */
    public boolean isOverdue(LocalDate today) {
        return !isPaid() && today.isAfter(dueDate);
    }

    public void markOverdueWarned(Instant at) {
        this.overdueWarnedAt = at;
    }

    /** Enforcement locked this landlord's properties over this statement. */
    public void markLocked(Instant at) {
        this.lockedAt = at;
    }

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

    public UUID getLandlordId() {
        return landlordId;
    }

    public LocalDate getBillingDate() {
        return billingDate;
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

    public PlatformStatementStatus getStatus() {
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
