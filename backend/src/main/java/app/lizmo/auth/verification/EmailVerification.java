package app.lizmo.auth.verification;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Somebody proving they can read email at an address they typed.
 *
 * <p>Lives on its own until the password is set, so an abandoned sign-up
 * expires instead of leaving a passwordless account squatting on the address.
 */
@Entity
@Table(name = "email_verifications")
public class EmailVerification {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, updatable = false)
    private String email;

    /** Hashed. The digits themselves are never stored. */
    @Column(name = "code_hash", nullable = false, updatable = false)
    private String codeHash;

    @Column(name = "expires_at", nullable = false, updatable = false)
    private Instant expiresAt;

    @Column(nullable = false)
    private short attempts;

    @Column(name = "consumed_at")
    private Instant consumedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected EmailVerification() {
    }

    public EmailVerification(
            String email, String codeHash, Instant expiresAt, Instant createdAt) {
        this.email = email;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        // Passed in rather than stamped on persist: the resend cooldown is
        // measured from it, and a rule measured from an untestable clock is a
        // rule nothing can check.
        this.createdAt = createdAt;
    }

    public boolean hasExpired(Instant now) {
        return !now.isBefore(expiresAt);
    }

    public boolean isSpent() {
        return consumedAt != null;
    }

    /** A wrong guess. */
    public void recordAttempt() {
        attempts++;
    }

    /**
     * Used up, for good.
     *
     * <p>Also how a burned verification is retired after too many guesses: a
     * spent row is out of the way of the unique index, so the next request can
     * issue a fresh code.
     */
    public void consume() {
        consumedAt = Instant.now();
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

    public String getCodeHash() {
        return codeHash;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public short getAttempts() {
        return attempts;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
