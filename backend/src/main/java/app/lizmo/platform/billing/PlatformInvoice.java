package app.lizmo.platform.billing;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * One property's share of a month, before and after it is paid for.
 *
 * <p>Two lives, one row. While the statement is unpaid this is a line on it:
 * what this property let, at what rates, for how much. When the statement is
 * settled in full the same row becomes an invoice -- numbered and dated -- and
 * that is what a landlord files against the building.
 *
 * <p>Nothing here tracks payment. Money arrives against the statement, which
 * is the only place a balance lives, so there is no second answer to disagree
 * with it.
 *
 * <p>Keeps the platform_billing_cycles table, which has held the per-property
 * figures since V1.
 */
@Entity
@Table(name = "platform_billing_cycles")
public class PlatformInvoice {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "statement_id", nullable = false, updatable = false)
    private UUID statementId;

    @Column(name = "property_id", nullable = false, updatable = false)
    private UUID propertyId;

    @Column(name = "occupied_units_count", nullable = false, updatable = false)
    private int occupiedUnits;

    @Column(name = "occupied_bedspaces_count", nullable = false, updatable = false)
    private int occupiedBeds;

    @Column(name = "unit_rate", nullable = false, updatable = false)
    private BigDecimal unitRate;

    @Column(name = "bed_rate", nullable = false, updatable = false)
    private BigDecimal bedRate;

    @Column(name = "amount_due", nullable = false, updatable = false)
    private BigDecimal amountDue;

    @Column(name = "invoice_number")
    private String invoiceNumber;

    @Column(name = "issued_at")
    private Instant issuedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PlatformInvoice() {
    }

    public PlatformInvoice(
            UUID statementId,
            UUID propertyId,
            int occupiedUnits,
            int occupiedBeds,
            BigDecimal unitRate,
            BigDecimal bedRate) {
        this.statementId = statementId;
        this.propertyId = propertyId;
        this.occupiedUnits = occupiedUnits;
        this.occupiedBeds = occupiedBeds;
        this.unitRate = unitRate;
        this.bedRate = bedRate;
        this.amountDue = unitRate.multiply(BigDecimal.valueOf(occupiedUnits))
                .add(bedRate.multiply(BigDecimal.valueOf(occupiedBeds)));
    }

    /**
     * The line becomes an invoice, because the statement has been paid.
     *
     * <p>Named and dated once. An invoice that could be reissued with a new
     * number is not a document anybody can quote back.
     */
    public void issue(String number, Instant at) {
        if (isIssued()) {
            return;
        }
        this.invoiceNumber = number;
        this.issuedAt = at;
    }

    public boolean isIssued() {
        return invoiceNumber != null;
    }

    @PrePersist
    @PreUpdate
    void touch() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    public UUID getId() {
        return id;
    }

    public UUID getStatementId() {
        return statementId;
    }

    public UUID getPropertyId() {
        return propertyId;
    }

    public int getOccupiedUnits() {
        return occupiedUnits;
    }

    public int getOccupiedBeds() {
        return occupiedBeds;
    }

    public BigDecimal getUnitRate() {
        return unitRate;
    }

    public BigDecimal getBedRate() {
        return bedRate;
    }

    public BigDecimal getAmountDue() {
        return amountDue;
    }

    public String getInvoiceNumber() {
        return invoiceNumber;
    }

    public Instant getIssuedAt() {
        return issuedAt;
    }
}
