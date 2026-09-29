package app.lizmo.rental;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * A tenant asking for a particular bed, or a whole unit.
 *
 * <p>Not a lease in waiting. Several tenants may hold a pending request on the
 * same bed at once — that is what lets a landlord choose — whereas a lease is
 * exclusive. Accepting one request is what creates the lease and settles the
 * others.
 */
@Entity
@Table(name = "rental_requests")
public class RentalRequest {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "tenant_id", nullable = false, updatable = false)
    private UUID tenantId;

    /**
     * Carried alongside the unit so the landlord's inbox is one indexed read.
     * A unit cannot move between properties, so this cannot fall out of step.
     */
    @Column(name = "property_id", nullable = false, updatable = false)
    private UUID propertyId;

    /**
      * Null when the request is about the property rather than one room: the
      * tenant is shown how many beds are free per floor, not which, and the
      * landlord picks the room when they accept.
      */
    @Column(name = "unit_id")
    private UUID unitId;

    /** Null for a whole unit. */
    @Column(name = "bed_id")
    private UUID bedId;



    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RentalRequestStatus status = RentalRequestStatus.PENDING;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    /** When it stopped being pending, whichever way it went. */
    @Column(name = "decided_at")
    private Instant decidedAt;

    protected RentalRequest() {
    }

    public RentalRequest(UUID tenantId, UUID propertyId, UUID unitId, UUID bedId) {
        this.tenantId = tenantId;
        this.propertyId = propertyId;
        this.unitId = unitId;
        this.bedId = bedId;
    }

    /**
     * Moves it out of PENDING.
     *
     * <p>One method for every ending, because they share the rule that matters:
     * a request is decided once. Without it, a landlord declining something the
     * tenant had already withdrawn would quietly overwrite the record of what
     * actually happened.
     */
    public void settle(RentalRequestStatus outcome) {
        if (status != RentalRequestStatus.PENDING) {
            throw new IllegalStateException("Already " + status);
        }
        this.status = outcome;
        this.decidedAt = Instant.now();
    }

    public boolean isPending() {
        return status == RentalRequestStatus.PENDING;
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

    public UUID getPropertyId() {
        return propertyId;
    }

    public UUID getUnitId() {
        return unitId;
    }

    public UUID getBedId() {
        return bedId;
    }

    public RentalRequestStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getDecidedAt() {
        return decidedAt;
    }

    /**
     * The room a landlord chose for somebody who asked about the place.
     *
     * <p>Written onto the request as it is accepted, so the queue, the
     * notification and anything reading it later say which room was given
     * rather than leaving it blank forever.
     */
    public void roomChosen(UUID unitId, UUID bedId) {
        this.unitId = unitId;
        this.bedId = bedId;
    }
}
