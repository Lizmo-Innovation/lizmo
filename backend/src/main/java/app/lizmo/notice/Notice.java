package app.lizmo.notice;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * An announcement from a landlord to the people renting in one of their
 * buildings, or in one unit of it.
 *
 * <p>Never edited once posted: everybody it went to has been told, and a
 * quiet edit would leave people having read different things. A landlord
 * takes it down and posts again.
 */
@Entity
@Table(name = "notices")
public class Notice {

    /** Who it is for. One tenant is not an audience: that is a conversation. */
    public enum Scope {
        ALL_TENANTS,
        SPECIFIC_UNIT,
        SPECIFIC_TENANT
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "posted_by", nullable = false, updatable = false)
    private UUID postedBy;

    @Column(name = "property_id", nullable = false, updatable = false)
    private UUID propertyId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false)
    private Scope scope;

    @Column(name = "unit_id", updatable = false)
    private UUID unitId;

    @Column(nullable = false, updatable = false)
    private String title;

    @Column(nullable = false, updatable = false)
    private String message;

    @Column(name = "posted_at", nullable = false, updatable = false)
    private Instant postedAt;

    /** When it stops being shown; null for until it is taken down. */
    @Column(name = "expires_at", updatable = false)
    private Instant expiresAt;

    @Column(name = "is_archived", nullable = false)
    private boolean archived;

    @Column(name = "archived_at")
    private Instant archivedAt;

    protected Notice() {
        // JPA
    }

    public Notice(
            UUID postedBy, UUID propertyId, UUID unitId, String title, String message,
            Instant postedAt, Instant expiresAt) {
        this.postedBy = postedBy;
        this.propertyId = propertyId;
        this.unitId = unitId;
        this.scope = unitId == null ? Scope.ALL_TENANTS : Scope.SPECIFIC_UNIT;
        this.title = title;
        this.message = message;
        this.postedAt = postedAt;
        this.expiresAt = expiresAt;
    }

    /** Taken down: gone from every tenant's screen, and from the landlord's list. */
    public void takeDown(Instant at) {
        this.archived = true;
        this.archivedAt = at;
    }

    /** Still shown: not taken down, and not past its date. */
    public boolean isLive(Instant now) {
        return !archived && (expiresAt == null || expiresAt.isAfter(now));
    }

    public UUID getId() {
        return id;
    }

    public UUID getPostedBy() {
        return postedBy;
    }

    public UUID getPropertyId() {
        return propertyId;
    }

    public Scope getScope() {
        return scope;
    }

    public UUID getUnitId() {
        return unitId;
    }

    public String getTitle() {
        return title;
    }

    public String getMessage() {
        return message;
    }

    public Instant getPostedAt() {
        return postedAt;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public boolean isArchived() {
        return archived;
    }
}
