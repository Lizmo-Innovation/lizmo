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
 * <p>Carries no billing status of its own: an unpaid Lizmo statement locks the
 * landlord's properties, not this row. See
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

    /**
     * The line shown to tenants under this landlord's payment channels, such as
     * "Cash to Aling Nena at unit 1A". Null when there is none.
     */
    @Column(name = "payment_note")
    private String paymentNote;

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

    /** Null clears it. */
    public void notePayments(String note) {
        this.paymentNote = note;
    }

    public String getPaymentNote() {
        return paymentNote;
    }
}
