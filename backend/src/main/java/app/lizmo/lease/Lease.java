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

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    /** Null while the lease is open-ended, which is the normal case here. */
    @Column(name = "end_date")
    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LeaseStatus status = LeaseStatus.ACTIVE;

    /** The request that became this lease, where there was one. */
    @Column(name = "rental_request_id", updatable = false)
    private UUID rentalRequestId;

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
            UUID rentalRequestId) {
        this.tenantId = tenantId;
        this.unitId = unitId;
        this.bedId = bedId;
        this.rentAmount = rentAmount;
        this.dueDateDay = dueDateDay;
        this.startDate = startDate;
        this.rentalRequestId = rentalRequestId;
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

    public UUID getRentalRequestId() {
        return rentalRequestId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
