package app.lizmo.billing.channel;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * One way a landlord is paid rent: a GCash number, a Maya account, a bank
 * account.
 *
 * <p>Belongs to the landlord, not a property: one list covers everything they
 * own. Their tenants see the visible ones beside "I have paid". The QR, when
 * there is one, is a document owned by this row.
 */
@Entity
@Table(name = "landlord_payment_channels")
public class LandlordPaymentChannel {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "landlord_id", nullable = false, updatable = false)
    private UUID landlordId;

    @Column(nullable = false)
    private String channel;

    @Column(name = "account_name", nullable = false)
    private String accountName;

    @Column(name = "account_number", nullable = false)
    private String accountNumber;

    @Column(nullable = false)
    private boolean visible = true;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected LandlordPaymentChannel() {
    }

    public LandlordPaymentChannel(
            UUID landlordId, String channel, String accountName, String accountNumber,
            int sortOrder) {
        this.landlordId = landlordId;
        this.channel = channel;
        this.accountName = accountName;
        this.accountNumber = accountNumber;
        this.sortOrder = sortOrder;
    }

    /** New details for the same channel. Its place in the list and its QR stay. */
    public void describe(String channel, String accountName, String accountNumber) {
        this.channel = channel;
        this.accountName = accountName;
        this.accountNumber = accountNumber;
    }

    /** Whether tenants are shown it. Hidden is kept, not deleted. */
    public void showToTenants(boolean shown) {
        this.visible = shown;
    }

    public void moveTo(int sortOrder) {
        this.sortOrder = sortOrder;
    }

    /** Recorded when only the QR changed, which is still a change to where money goes. */
    public void touch() {
        this.updatedAt = Instant.now();
    }

    /**
     * How a payment remembers it: "GCash · Ariel Asebias · 09771231234".
     *
     * <p>Written onto the payment when a tenant picks it, so editing or deleting
     * this channel later cannot change what a past payment said.
     */
    public String label() {
        return "%s · %s · %s".formatted(channel, accountName, accountNumber);
    }

    @PrePersist
    void stampCreated() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void stampUpdated() {
        updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getLandlordId() {
        return landlordId;
    }

    public String getChannel() {
        return channel;
    }

    public String getAccountName() {
        return accountName;
    }

    public String getAccountNumber() {
        return accountNumber;
    }

    public boolean isVisible() {
        return visible;
    }

    public int getSortOrder() {
        return sortOrder;
    }
}
