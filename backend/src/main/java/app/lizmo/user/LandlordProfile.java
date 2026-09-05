package app.lizmo.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Marks a user as able to own properties.
 *
 * <p>Carries no billing status of its own. Lizmo bills a property, not a
 * person: a landlord with three boarding houses has three invoices and three
 * statuses, and falling behind on one does not touch the others. See
 * {@link app.lizmo.property.PropertyAccountStatus}.
 */
@Entity
@Table(name = "landlord_profiles")
public class LandlordProfile {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected LandlordProfile() {
        // for JPA
    }

    public LandlordProfile(UUID userId) {
        this.userId = userId;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }

    public UUID getUserId() {
        return userId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
