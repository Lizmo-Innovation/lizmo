package app.lizmo.property;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * One rentable bed inside a BEDSPACE unit.
 *
 * <p>A first-class entity rather than a label on a lease, because it has a life
 * of its own: it can be taken out of service without ending a tenancy, and it
 * keeps its occupancy history as tenants come and go.
 */
@Entity
@Table(name = "beds")
public class Bed {

    @Id
    private UUID id;

    @Column(name = "unit_id", nullable = false)
    private UUID unitId;

    /** Unique within a unit, enforced by uq_bed_label_per_unit. */
    @Column(name = "bed_label", nullable = false)
    private String bedLabel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BedStatus status = BedStatus.VACANT;

    /**
     * What this bed asks, when it differs from its unit's rent.
     *
     * <p>Null means "whatever the unit asks" — never free. Reading it in
     * isolation is a mistake; the unit's rent is the fallback.
     */
    private BigDecimal rent;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Bed() {
        // for JPA
    }

    public Bed(UUID unitId, String bedLabel) {
        this.id = UUID.randomUUID();
        this.unitId = unitId;
        this.bedLabel = bedLabel;
        this.status = BedStatus.VACANT;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = Instant.now();
    }

    public void rename(String bedLabel) {
        this.bedLabel = bedLabel;
    }

    /** Both details a landlord can edit, applied together. */
    public void update(String bedLabel, BigDecimal rent) {
        this.bedLabel = bedLabel;
        this.rent = rent;
    }

    /**
     * Takes the bed in or out of service.
     *
     * <p>Refuses while occupied: a bed with a live lease is not free to be
     * flipped, and doing so would hide a tenant from occupancy counts while
     * they are still paying rent.
     */
    /** Taken, by a tenant under an active lease. */
    public void markOccupied() {
        this.status = BedStatus.OCCUPIED;
    }

    /**
     * Freed when a lease ends.
     *
     * <p>Only from OCCUPIED. A bed out of service must not quietly come back
     * into the vacancy list because a lease elsewhere ended.
     */
    public void markVacated() {
        if (status == BedStatus.OCCUPIED) {
            this.status = BedStatus.VACANT;
        }
    }

    public void markMaintenance(boolean underMaintenance) {
        if (status == BedStatus.OCCUPIED) {
            throw new IllegalStateException("Cannot change maintenance state of an occupied bed");
        }
        this.status = underMaintenance ? BedStatus.MAINTENANCE : BedStatus.VACANT;
    }

    public boolean isOccupied() {
        return status == BedStatus.OCCUPIED;
    }

    public UUID getId() {
        return id;
    }

    public UUID getUnitId() {
        return unitId;
    }

    public String getBedLabel() {
        return bedLabel;
    }

    public BedStatus getStatus() {
        return status;
    }

    public BigDecimal getRent() {
        return rent;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
