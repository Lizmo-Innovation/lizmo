package app.lizmo.lease;

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
 * A tenant attached to a bed, or to a whole unit.
 *
 * <p>Exclusive, which is what separates it from the request that produced it:
 * many people may ask about one bed, and exactly one may hold it. Two partial
 * unique indexes enforce that -- per bed, and per unit when the unit is let
 * entire.
 */
@Entity
@Table(name = "leases")
public class Lease {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "tenant_id", nullable = false, updatable = false)
    private UUID tenantId;

    @Column(name = "unit_id", nullable = false, updatable = false)
    private UUID unitId;

    /** Null when the whole unit is let. */
    @Column(name = "bed_id", updatable = false)
    private UUID bedId;

    @Column(name = "rent_amount", nullable = false)
    private BigDecimal rentAmount;

    /**
     * Day of the month rent falls due, 1 to 31.
     *
     * <p>Set by the landlord rather than derived from the move-in date, so
     * every bed in a room can fall due on the same day no matter when each
     * person arrived. A 29th, 30th or 31st is allowed and clamped when a
     * billing period is generated -- February is a billing problem, not a
     * reason to refuse a lease.
     */
    @Column(name = "due_date_day", nullable = false)
    private short dueDateDay;

    /**
     * Held against damage, and mostly given back. Not rent.
     *
     * <p>Null means nobody recorded one, which is not the same as none being
     * taken -- the apps show a dash rather than a zero for exactly that
     * reason.
     */
    @Column(name = "deposit_amount")
    private BigDecimal depositAmount;

    /**
     * Rent paid before moving in, which pays for the first month.
     *
     * <p>Kept apart from the deposit because it is money the landlord has
     * earned, while a deposit is money they are holding.
     */
    @Column(name = "advance_amount")
    private BigDecimal advanceAmount;

    /**
     * Why it ended, in the landlord's own words.
     *
     * <p>Their note to themselves, not the tenant's business: it sits beside
     * "stopped early" to say what actually happened, while the deposit
     * settlement -- which the tenant does see -- is about money.
     */
    @Column(name = "end_reason")
    private String endReason;

    /** How much of the deposit went back, recorded when the tenancy ended. */
    @Column(name = "deposit_returned")
    private BigDecimal depositReturned;

    /** What was withheld and why, in the landlord's own words. */
    @Column(name = "deposit_settlement")
    private String depositSettlement;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    /** Null while the lease is open-ended, which is the normal case here. */
    @Column(name = "end_date")
    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LeaseStatus status = LeaseStatus.ACTIVE;

    /**
     * The conversation this tenancy came out of, where there was one.
     *
     * <p>Null for a tenancy written directly -- a boarding house moving onto
     * Lizmo has tenants who never asked anybody anything.
     */
    @Column(name = "inquiry_id", updatable = false)
    private UUID inquiryId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Lease() {
    }

    public Lease(
            UUID tenantId,
            UUID unitId,
            UUID bedId,
            BigDecimal rentAmount,
            short dueDateDay,
            LocalDate startDate,
            UUID inquiryId) {
        this(tenantId, unitId, bedId, rentAmount, dueDateDay, startDate,
                inquiryId, null, null);
    }

    public Lease(
            UUID tenantId,
            UUID unitId,
            UUID bedId,
            BigDecimal rentAmount,
            short dueDateDay,
            LocalDate startDate,
            UUID inquiryId,
            BigDecimal depositAmount,
            BigDecimal advanceAmount) {
        this.depositAmount = depositAmount;
        this.advanceAmount = advanceAmount;
        this.tenantId = tenantId;
        this.unitId = unitId;
        this.bedId = bedId;
        this.rentAmount = rentAmount;
        this.dueDateDay = dueDateDay;
        this.startDate = startDate;
        this.inquiryId = inquiryId;
    }

    /**
     * Ends the tenancy and gives the slot back.
     *
     * <p>The status is what frees it: both unique indexes are partial on
     * ACTIVE, so the bed becomes lettable again the moment this commits.
     */
    public void close(LeaseStatus outcome, LocalDate on) {
        if (status != LeaseStatus.ACTIVE) {
            throw new IllegalStateException("Already " + status);
        }
        this.status = outcome;
        this.endDate = on;
    }

    public boolean isActive() {
        return status == LeaseStatus.ACTIVE;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getTenantId() {
        return tenantId;
    }

    public UUID getUnitId() {
        return unitId;
    }

    public UUID getBedId() {
        return bedId;
    }

    public BigDecimal getRentAmount() {
        return rentAmount;
    }

    public BigDecimal getDepositAmount() {
        return depositAmount;
    }

    public BigDecimal getAdvanceAmount() {
        return advanceAmount;
    }

    public String getEndReason() {
        return endReason;
    }

    public void recordEndReason(String reason) {
        this.endReason = reason;
    }

    public BigDecimal getDepositReturned() {
        return depositReturned;
    }

    public String getDepositSettlement() {
        return depositSettlement;
    }

    /**
     * Records what happened to the deposit.
     *
     * <p>Named rather than two setters because the amount and the explanation
     * belong together: a figure smaller than the deposit with no reason beside
     * it is the shape of an argument.
     */
    public void settleDeposit(BigDecimal returned, String settlement) {
        this.depositReturned = returned;
        this.depositSettlement = settlement;
    }

    public short getDueDateDay() {
        return dueDateDay;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public LeaseStatus getStatus() {
        return status;
    }

    public UUID getInquiryId() {
        return inquiryId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
