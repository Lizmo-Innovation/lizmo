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

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PropertyType type;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Property() {
        // for JPA
    }

    public Property(UUID landlordId, String name, String address, PropertyType type) {
        this.id = UUID.randomUUID();
        this.landlordId = landlordId;
        this.name = name;
        this.address = address;
        this.type = type;
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

    public void update(String name, String address, PropertyType type) {
        this.name = name;
        this.address = address;
        this.type = type;
    }

    public boolean isOwnedBy(UUID landlordId) {
        return this.landlordId.equals(landlordId);
    }

    public UUID getId() {
        return id;
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

    public PropertyType getType() {
        return type;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
