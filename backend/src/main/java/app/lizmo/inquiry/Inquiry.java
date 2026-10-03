package app.lizmo.inquiry;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * One conversation about one property, between the person asking and the
 * landlord.
 *
 * <p>There is exactly one per pair. Asking again about a building you have
 * asked about before picks the same thread back up rather than starting a
 * second one nobody could tell from the first.
 *
 * <p>The landlord is not stored: they are the property's owner, and a property
 * can change hands. Held here it would go stale, and a stale copy of who owns
 * a building is somebody reading a stranger's messages.
 */
@Entity
@Table(name = "inquiries")
public class Inquiry {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "property_id", nullable = false, updatable = false)
    private UUID propertyId;

    @Column(name = "tenant_id", nullable = false, updatable = false)
    private UUID tenantId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InquiryStatus status = InquiryStatus.OPEN;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    /** Null until somebody says something, which orders an empty thread by age. */
    @Column(name = "last_message_at")
    private Instant lastMessageAt;

    @Column(name = "tenant_unread", nullable = false)
    private boolean tenantUnread;

    @Column(name = "landlord_unread", nullable = false)
    private boolean landlordUnread;

    @Column(name = "closed_at")
    private Instant closedAt;

    protected Inquiry() {
    }

    public Inquiry(UUID propertyId, UUID tenantId) {
        this.propertyId = propertyId;
        this.tenantId = tenantId;
    }

    /**
     * Somebody wrote: the thread moves to the top of both inboxes, and the
     * other side has something new.
     *
     * <p>Writing counts as reading. Whoever just spoke has by definition seen
     * everything above what they wrote.
     */
    public void spoke(boolean byTenant, Instant when) {
        this.lastMessageAt = when;
        this.tenantUnread = !byTenant;
        this.landlordUnread = byTenant;
    }

    /**
     * Picks a finished conversation back up.
     *
     * <p>A closed thread reopens rather than a second one being started: the
     * landlord who said there was nothing free in March is the same person
     * being asked again in June, and the March exchange is worth having in
     * front of them.
     */
    public void reopen() {
        this.status = InquiryStatus.OPEN;
        this.closedAt = null;
    }

    public void close(Instant when) {
        this.status = InquiryStatus.CLOSED;
        this.closedAt = when;
    }

    /** A tenancy came out of it. The thread stays usable. */
    public void leased(Instant when) {
        this.status = InquiryStatus.LEASED;
        this.closedAt = when;
    }

    public void read(boolean asTenant) {
        if (asTenant) {
            this.tenantUnread = false;
        } else {
            this.landlordUnread = false;
        }
    }

    /** Whether this side has something they have not seen. */
    public boolean unreadFor(boolean asTenant) {
        return asTenant ? tenantUnread : landlordUnread;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getPropertyId() {
        return propertyId;
    }

    public UUID getTenantId() {
        return tenantId;
    }

    public InquiryStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getLastMessageAt() {
        return lastMessageAt;
    }

    public Instant getClosedAt() {
        return closedAt;
    }
}
