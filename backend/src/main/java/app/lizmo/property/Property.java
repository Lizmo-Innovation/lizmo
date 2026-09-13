package app.lizmo.property;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * A building or lot owned by one landlord.
 *
 * <p>May hold a single unit (a house let whole) or many (an apartment block or
 * boarding house). Rent lives on the unit, not here, because units in the same
 * property routinely differ.
 */
@Entity
@Table(name = "properties")
public class Property {

    @Id
    private UUID id;

    /**
     * Owner. Every read and write is scoped by this — it is the boundary that
     * keeps one landlord's portfolio invisible to another.
     */
    @Column(name = "landlord_id", nullable = false)
    private UUID landlordId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String address;

    /**
     * What the landlord says about the place, in their own words.
     *
     * <p>Null when they have not written one. Capped at 2000 characters by
     * chk_properties_description_length as well as by the request.
     */
    private String description;

    /**
     * The short code a tenant types or scans to find this place.
     *
     * <p>Set once when the property is created and never changed: it gets
     * written on a whiteboard by the gate and passed around a group chat, so a
     * code that rotates would strand everyone holding the old one.
     */
    @Column(nullable = false, updatable = false)
    private String code;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PropertyType type;

    /**
     * Residential or commercial. Constrains which {@link PropertyType} values
     * are legal — the database enforces the pairing too, in
     * chk_properties_usage_type.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PropertyUsage usage;

    /**
     * Whether this property may be added to.
     *
     * <p>Per property rather than per landlord: somebody with three boarding
     * houses who falls behind on one should not lose the other two. It never
     * affects the tenants living here -- see PropertyAccess for what it stops.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "account_status", nullable = false)
    private PropertyAccountStatus accountStatus = PropertyAccountStatus.ACTIVE;

    /**
     * Which unpaid statement locked this, if enforcement did.
     *
     * <p>Null when an admin locked it by hand, so paying a statement lifts
     * only what that statement caused and leaves an admin's decision alone.
     */
    @Column(name = "locked_by_statement_id")
    private UUID lockedByStatementId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Property() {
        // for JPA
    }

    public Property(
            UUID landlordId,
            String name,
            String address,
            String description,
            PropertyType type,
            PropertyUsage usage,
            String code) {
        this.id = UUID.randomUUID();
        this.landlordId = landlordId;
        this.name = name;
        this.address = address;
        this.description = description;
        this.type = type;
        this.usage = usage;
        this.code = code;
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

    public void update(
            String name,
            String address,
            String description,
            PropertyType type,
            PropertyUsage usage) {
        this.name = name;
        this.address = address;
        this.description = description;
        this.type = type;
        this.usage = usage;
    }

    public boolean isLocked() {
        return accountStatus == PropertyAccountStatus.LOCKED;
    }

    public PropertyAccountStatus getAccountStatus() {
        return accountStatus;
    }

    /** Stops the property being added to. Named for what an admin does, not for a setter. */
    public void lock() {
        this.accountStatus = PropertyAccountStatus.LOCKED;
    }

    /** The same, by an unpaid statement, which paying that statement undoes. */
    public void lockFor(UUID statementId) {
        lock();
        this.lockedByStatementId = statementId;
    }

    public void unlock() {
        this.accountStatus = PropertyAccountStatus.ACTIVE;
        this.lockedByStatementId = null;
    }

    public UUID getLockedByStatementId() {
        return lockedByStatementId;
    }

    public boolean isOwnedBy(UUID landlordId) {
        return this.landlordId.equals(landlordId);
    }

    public UUID getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public UUID getLandlordId() {
        return landlordId;
    }

    public String getName() {
        return name;
    }

    public String getAddress() {
        return address;
    }

    public String getDescription() {
        return description;
    }

    public PropertyType getType() {
        return type;
    }

    public PropertyUsage getUsage() {
        return usage;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
