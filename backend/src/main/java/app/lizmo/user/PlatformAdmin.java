package app.lizmo.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Marks a user as internal Lizmo staff.
 *
 * <p>Distinct from landlord staff: a landlord's caretaker administers that
 * landlord's properties, while a platform admin verifies payments made
 * <em>to Lizmo</em> and can see every landlord's account. Conflating them would
 * let a landlord's own staff confirm their employer's platform invoice.
 *
 * <p>There is deliberately no endpoint that creates one of these. Admin access
 * is granted by inserting a row directly, so a compromised API cannot mint
 * itself an administrator.
 */
@Entity
@Table(name = "platform_admins")
public class PlatformAdmin {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected PlatformAdmin() {
        // for JPA
    }

    public PlatformAdmin(UUID userId) {
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
