package app.lizmo.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Marks a user as rentable-to. Deliberately thin — a tenant's substance lives
 * in their leases, and the profile persists across tenancies so re-renting
 * attaches a new lease rather than creating a duplicate person.
 */
@Entity
@Table(name = "tenant_profiles")
public class TenantProfile {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected TenantProfile() {
        // for JPA
    }

    public TenantProfile(UUID userId) {
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
