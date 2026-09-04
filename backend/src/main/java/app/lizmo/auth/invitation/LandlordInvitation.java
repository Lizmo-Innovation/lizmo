package app.lizmo.auth.invitation;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Lizmo asking somebody to be a landlord.
 *
 * <p>Lives on its own until it is accepted, so an invitation nobody takes up
 * expires rather than leaving a landlord account that never had an owner.
 */
@Entity
@Table(name = "landlord_invitations")
public class LandlordInvitation {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, updatable = false)
    private String email;

    /** Hashed. The token itself is only ever in the email. */
    @Column(name = "token_hash", nullable = false, updatable = false)
    private String tokenHash;

    /** The admin who sent it. Granting this should not be anonymous. */
    @Column(name = "invited_by", nullable = false, updatable = false)
    private UUID invitedBy;

    @Column(name = "expires_at", nullable = false, updatable = false)
    private Instant expiresAt;

    @Column(name = "accepted_at")
    private Instant acceptedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected LandlordInvitation() {
    }

    public LandlordInvitation(
            String email, String tokenHash, UUID invitedBy, Instant expiresAt, Instant createdAt) {
        this.email = email;
        this.tokenHash = tokenHash;
        this.invitedBy = invitedBy;
        this.expiresAt = expiresAt;
        this.createdAt = createdAt;
    }

    public boolean hasExpired(Instant now) {
        return !now.isBefore(expiresAt);
    }

    public boolean isSpent() {
        return acceptedAt != null;
    }

    /**
     * Used up, for good.
     *
     * <p>Also how a superseded invitation is retired when a new one is sent:
     * a spent row is out of the way of the one-live-invitation index.
     */
    public void accept(Instant at) {
        this.acceptedAt = at;
    }

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getTokenHash() {
        return tokenHash;
    }

    public UUID getInvitedBy() {
        return invitedBy;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public Instant getAcceptedAt() {
        return acceptedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
