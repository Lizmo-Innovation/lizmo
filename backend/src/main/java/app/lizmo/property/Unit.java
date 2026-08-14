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
 * A lettable space within a property.
 *
 * <p>{@link RentalMode} decides its shape: a WHOLE_UNIT takes one lease, a
 * BEDSPACE takes one lease per bed. The mode is fixed at creation — changing it
 * later would orphan either the beds or the unit's own lease, so it is not
 * updatable.
 */
@Entity
@Table(name = "units")
public class Unit {

    @Id
    private UUID id;

    @Column(name = "property_id", nullable = false)
    private UUID propertyId;

    /** Unique within a property, enforced by uq_unit_number_per_property. */
    @Column(name = "unit_number", nullable = false)
    private String unitNumber;

    private String floor;

    @Column(name = "size_sqm")
    private BigDecimal sizeSqm;

    @Enumerated(EnumType.STRING)
    @Column(name = "rental_mode", nullable = false, updatable = false)
    private RentalMode rentalMode;

    /** Maximum occupants. Only meaningful for BEDSPACE. */
    @Column(nullable = false)
    private int capacity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UnitStatus status = UnitStatus.VACANT;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Unit() {
        // for JPA
    }

    public Unit(
            UUID propertyId,
            String unitNumber,
            String floor,
            BigDecimal sizeSqm,
            RentalMode rentalMode,
            int capacity) {
        this.id = UUID.randomUUID();
        this.propertyId = propertyId;
        this.unitNumber = unitNumber;
        this.floor = floor;
        this.sizeSqm = sizeSqm;
        this.rentalMode = rentalMode;
        this.capacity = capacity;
        this.status = UnitStatus.VACANT;
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

    /** Rental mode is deliberately absent: it cannot change after creation. */
    public void update(String unitNumber, String floor, BigDecimal sizeSqm, int capacity) {
        this.unitNumber = unitNumber;
        this.floor = floor;
        this.sizeSqm = sizeSqm;
        this.capacity = capacity;
    }

    public void markMaintenance(boolean underMaintenance) {
        this.status = underMaintenance ? UnitStatus.MAINTENANCE : UnitStatus.VACANT;
    }

    public boolean isBedspace() {
        return rentalMode == RentalMode.BEDSPACE;
    }

    public UUID getId() {
        return id;
    }

    public UUID getPropertyId() {
        return propertyId;
    }

    public String getUnitNumber() {
        return unitNumber;
    }

    public String getFloor() {
        return floor;
    }

    public BigDecimal getSizeSqm() {
        return sizeSqm;
    }

    public RentalMode getRentalMode() {
        return rentalMode;
    }

    public int getCapacity() {
        return capacity;
    }

    public UnitStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
