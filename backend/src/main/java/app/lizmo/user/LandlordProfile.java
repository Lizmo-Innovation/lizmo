package app.lizmo.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Marks a user as able to own properties.
 *
 * <p>{@code accountStatus} is Lizmo's billing relationship with the landlord,
 * not their standing with tenants — see {@link LandlordAccountStatus}.
 */
@Entity
@Table(name = "landlord_profiles")
public class LandlordProfile {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "account_status", nullable = false)
    private LandlordAccountStatus accountStatus = LandlordAccountStatus.ACTIVE;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected LandlordProfile() {
        // for JPA
    }

    public LandlordProfile(UUID userId) {
        this.userId = userId;
        this.accountStatus = LandlordAccountStatus.ACTIVE;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }

    public UUID getUserId() {
        return userId;
    }

    public LandlordAccountStatus getAccountStatus() {
        return accountStatus;
    }

    public boolean isLocked() {
        return accountStatus == LandlordAccountStatus.LOCKED;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
