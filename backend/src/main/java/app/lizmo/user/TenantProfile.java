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
import java.time.LocalDate;
import java.util.UUID;

/**
 * What a tenant tells a landlord before signing a lease.
 *
 * <p>Identity — name, phone, email — stays on the user; a landlord account has
 * those too. What lives here is what a landlord asks a *tenant*: who to call in
 * an emergency, what ID they carry, where they are from.
 *
 * <p>The profile persists across tenancies, so re-renting attaches a new lease
 * rather than creating a duplicate person.
 *
 * <p>Every field is optional. A tenant fills this in on a phone at move-in and
 * skips whatever they can; a half-finished profile is worth more than an
 * abandoned one. Whether a *lease* may be signed against it is a separate
 * question, asked where leases are created.
 */
@Entity
@Table(name = "tenant_profiles")
public class TenantProfile {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    private LocalDate birthdate;

    @Column(name = "permanent_address")
    private String permanentAddress;

    private String occupation;

    /**
      * How a landlord reaches them about a room they asked for. Theirs, not
      * their emergency contact's, and the one thing asked before asking.
      */
    @Column(name = "contact_phone")
    private String contactPhone;

    @Column(name = "emergency_contact_name")
    private String emergencyContactName;

    @Column(name = "emergency_contact_relationship")
    private String emergencyContactRelationship;

    @Column(name = "emergency_contact_phone")
    private String emergencyContactPhone;

    @Enumerated(EnumType.STRING)
    @Column(name = "id_type")
    private IdType idType;

    @Column(name = "id_number")
    private String idNumber;

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

    /** Applies everything a tenant can edit about themselves, in one go. */
    public void update(
            LocalDate birthdate,
            String permanentAddress,
            String occupation,
            String contactPhone,
            String emergencyContactName,
            String emergencyContactRelationship,
            String emergencyContactPhone,
            IdType idType,
            String idNumber) {
        this.birthdate = birthdate;
        this.permanentAddress = permanentAddress;
        this.occupation = occupation;
        this.contactPhone = contactPhone;
        this.emergencyContactName = emergencyContactName;
        this.emergencyContactRelationship = emergencyContactRelationship;
        this.emergencyContactPhone = emergencyContactPhone;
        this.idType = idType;
        this.idNumber = idNumber;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getContactPhone() {
        return contactPhone;
    }

    /**
     * Empties everything personal, keeping the row.
     *
     * <p>The row itself cannot go: leases point at it by foreign key, and a
     * lease is the landlord's record of their own property as much as the
     * tenant's. So the profile survives as an empty shell attached to an id
     * that no longer names anybody, and every fact somebody would recognise --
     * their birthday, their address, their ID number, who to ring in an
     * emergency -- is gone.
     */
    public void scrub() {
        this.birthdate = null;
        this.permanentAddress = null;
        this.occupation = null;
        this.contactPhone = null;
        this.emergencyContactName = null;
        this.emergencyContactRelationship = null;
        this.emergencyContactPhone = null;
        this.idType = null;
        this.idNumber = null;
    }

    public LocalDate getBirthdate() {
        return birthdate;
    }

    public String getPermanentAddress() {
        return permanentAddress;
    }

    public String getOccupation() {
        return occupation;
    }

    public String getEmergencyContactName() {
        return emergencyContactName;
    }

    public String getEmergencyContactRelationship() {
        return emergencyContactRelationship;
    }

    public String getEmergencyContactPhone() {
        return emergencyContactPhone;
    }

    public IdType getIdType() {
        return idType;
    }

    public String getIdNumber() {
        return idNumber;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
