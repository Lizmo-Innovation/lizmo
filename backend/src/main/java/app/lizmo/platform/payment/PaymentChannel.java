package app.lizmo.platform.payment;

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
 * One way to pay Lizmo: a GCash number, a Maya account, a bank account.
 *
 * <p>Admins keep a list of these; landlords see the visible ones on their
 * billing screen. The QR, when there is one, is a document owned by this row
 * rather than a column on it, so it is stored, re-encoded and served like every
 * other image.
 */
@Entity
@Table(name = "platform_payment_channels")
public class PaymentChannel {

    @Id
    @GeneratedValue
    private UUID id;

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

    @Column(name = "updated_by")
    private UUID updatedBy;

    protected PaymentChannel() {
    }

    public PaymentChannel(
            String channel, String accountName, String accountNumber, int sortOrder, UUID admin) {
        this.channel = channel;
        this.accountName = accountName;
        this.accountNumber = accountNumber;
        this.sortOrder = sortOrder;
        this.updatedBy = admin;
    }

    /** New details for the same channel. Its place in the list and its QR stay. */
    public void describe(String channel, String accountName, String accountNumber, UUID admin) {
        this.channel = channel;
        this.accountName = accountName;
        this.accountNumber = accountNumber;
        this.updatedBy = admin;
    }

    /** Whether landlords are shown it. Hidden is kept, not deleted. */
    public void showToLandlords(boolean shown, UUID admin) {
        this.visible = shown;
        this.updatedBy = admin;
    }

    public void moveTo(int sortOrder, UUID admin) {
        this.sortOrder = sortOrder;
        this.updatedBy = admin;
    }

    /** Recorded when only the QR changed, which is still a change to where money goes. */
    public void touchedBy(UUID admin) {
        this.updatedBy = admin;
        this.updatedAt = Instant.now();
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
