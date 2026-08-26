package app.lizmo.property;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * One utility charged on one unit, at a fixed monthly amount.
 *
 * <p>Fixed rather than metered: the point is that a landlord sets a figure once
 * and stops recalculating it every month, and a tenant knows what they owe
 * before the bill arrives.
 */
@Entity
@Table(name = "unit_utilities")
public class UnitUtility {

    @Id
    private UUID id;

    @Column(name = "unit_id", nullable = false)
    private UUID unitId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UtilityKind kind;

    @Column(nullable = false)
    private boolean enabled;

    /**
     * Kept when the utility is switched off, so turning it back on does not
     * make the landlord remember what they were charging.
     */
    private BigDecimal amount;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected UnitUtility() {
        // for JPA
    }

    public UnitUtility(UUID unitId, UtilityKind kind) {
        this.id = UUID.randomUUID();
        this.unitId = unitId;
        this.kind = kind;
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

    public void set(boolean enabled, BigDecimal amount) {
        this.enabled = enabled;
        // A blank amount does not clear a figure that is already there; only an
        // explicit one replaces it.
        if (amount != null) {
            this.amount = amount;
        }
    }

    /** What this utility adds to a month's bill: nothing when switched off. */
    public BigDecimal monthlyAmount() {
        return enabled && amount != null ? amount : BigDecimal.ZERO;
    }

    public UUID getId() {
        return id;
    }

    public UUID getUnitId() {
        return unitId;
    }

    public UtilityKind getKind() {
        return kind;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public BigDecimal getAmount() {
        return amount;
    }
}
