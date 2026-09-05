package app.lizmo.user;

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
 * Base identity. Roles are non-exclusive: the same user may hold a tenant
 * profile, a landlord profile, and any number of staff assignments at once, so
 * roles live in separate profile tables rather than a column here.
 *
 * <p>Either email or phone must be present (chk_contact) — many Philippine
 * tenants have a mobile number but no email address.
 */
@Entity
@Table(name = "users")
public class User {

    @Id
    private UUID id;

    @Column(nullable = false)
    private String name;

    /** Nullable: a user may identify by phone instead. Unique when present. */
    @Column(unique = true)
    private String email;

    @Column(unique = true)
    private String phone;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserStatus status = UserStatus.ACTIVE;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected User() {
        // for JPA
    }

    public User(String name, String email, String phone, String passwordHash) {
        this.id = UUID.randomUUID();
        this.name = name;
        this.email = email;
        this.phone = phone;
        this.passwordHash = passwordHash;
        this.status = UserStatus.ACTIVE;
    }

    /**
     * When the address was proved, or null for an account that never did.
     *
     * <p>Every account created before verification existed was stamped in the
     * migration: they are Ariel's own, and locking himself out of both test
     * phones to be pedantic would have proved nothing.
     */
    @Column(name = "email_verified_at")
    private Instant emailVerifiedAt;

    /**
     * When the person asked to be deleted, or null for a live account.
     *
     * <p>The row survives so that a landlord's record of a tenancy does not
     * disappear with their tenant. What does not survive is on the same line
     * as this one: see {@link #close}.
     */
    @Column(name = "deleted_at")
    private Instant deletedAt;

    /**
     * Closes the account at the person's own request.
     *
     * <p>Everything that names them is overwritten in the same breath as the
     * timestamp, so there is no window in which an account is marked deleted
     * and still carries an email address and a phone number.
     *
     * @param releasedEmail an address at a domain that can never exist, so the
     *                      real one is free to be used again
     */
    public void close(String releasedEmail, String unusablePasswordHash) {
        this.email = releasedEmail;
        this.phone = null;
        this.name = "Deleted account";
        this.passwordHash = unusablePasswordHash;
        this.status = UserStatus.INACTIVE;
        this.deletedAt = Instant.now();
    }

    public Instant getDeletedAt() {
        return deletedAt;
    }

    public boolean isDeleted() {
        return deletedAt != null;
    }

    /** Records that somebody read a code sent to this address. */
    public void markEmailVerified(Instant at) {
        this.emailVerifiedAt = at;
    }

    public Instant getEmailVerifiedAt() {
        return emailVerifiedAt;
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

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
        return phone;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public UserStatus getStatus() {
        return status;
    }

    public boolean isActive() {
        return status == UserStatus.ACTIVE;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
