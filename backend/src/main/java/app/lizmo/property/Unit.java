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

    /**
     * Asking rent: per bed for BEDSPACE, for the whole unit for WHOLE_UNIT.
     *
     * <p>Nullable, because a landlord may set a unit up before deciding what to
     * charge. Null means "not set" — never zero, which would read as free.
     *
     * <p>A default for new leases, not the truth about what is charged:
     * {@code leases.rent_amount} stays authoritative, since a sitting tenant may
     * be on an older rate.
     */
    @Column(name = "rent")
    private BigDecimal rent;

    @Enumerated(EnumType.STRING)
    @Column(name = "rental_mode", nullable = false, updatable = false)
    private RentalMode rentalMode;

    /** Maximum occupants. Only meaningful for BEDSPACE. */
    @Column(nullable = false)
    private int capacity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UnitStatus status = UnitStatus.VACANT;

    /**
     * How this unit's utility charges reach the tenant.
     *
     * <p>Kept on the unit rather than on each utility: a landlord decides how
     * they bill, not how they bill the water as against the WiFi.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "utility_billing", nullable = false)
    private UtilityBilling utilityBilling = UtilityBilling.COMBINED;

    @Column(name = "ready_from")
    private java.time.LocalDate readyFrom;

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
            int capacity,
            BigDecimal rent) {
        this.id = UUID.randomUUID();
        this.propertyId = propertyId;
        this.unitNumber = unitNumber;
        this.floor = floor;
        this.sizeSqm = sizeSqm;
        this.rentalMode = rentalMode;
        this.capacity = capacity;
        this.rent = rent;
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
    public void update(
            String unitNumber, String floor, BigDecimal sizeSqm, int capacity, BigDecimal rent) {
        this.unitNumber = unitNumber;
        this.floor = floor;
        this.sizeSqm = sizeSqm;
        this.capacity = capacity;
        this.rent = rent;
    }

    public void billUtilities(UtilityBilling billing) {
        this.utilityBilling = billing;
    }

    /** Let entire, to one tenant. */
    public void markLetEntire() {
        this.status = UnitStatus.OCCUPIED;
    }

    /**
     * Recomputed from the beds inside it, after one is taken or freed.
     *
     * <p>Never touches a unit that is out of service: a room shut for repairs
     * stays shut whatever its beds say, and the landlord is the only one who
     * reopens it.
     */
    public void reflectBedOccupancy(boolean anyVacant, boolean anyOccupied) {
        if (status == UnitStatus.MAINTENANCE) {
            return;
        }
        if (!anyOccupied) {
            this.status = UnitStatus.VACANT;
        } else if (anyVacant) {
            this.status = UnitStatus.PARTIALLY_OCCUPIED;
        } else {
            this.status = UnitStatus.OCCUPIED;
        }
    }

    /**
     * When a vacant room is ready to move into, if not now -- being
     * repainted, say. Null, or a day gone by, is ready now.
     */
    public void readyFrom(java.time.LocalDate on) {
        this.readyFrom = on;
    }

    public java.time.LocalDate getReadyFrom() {
        return readyFrom;
    }

    public void markMaintenance(boolean underMaintenance) {
        this.status = underMaintenance ? UnitStatus.MAINTENANCE : UnitStatus.VACANT;
    }

    public UtilityBilling getUtilityBilling() {
        return utilityBilling;
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

    public BigDecimal getRent() {
        return rent;
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
