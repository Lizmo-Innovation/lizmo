package app.lizmo.billing.receipt;

import app.lizmo.billing.BillingPeriodKind;
import app.lizmo.billing.PaymentMethod;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * An acknowledgement receipt: a landlord's word that money arrived.
 *
 * <p>Written once, when a payment is confirmed or recorded, and never
 * changed after -- with one exception, the name of somebody who has closed
 * their account. It copies what it says rather than pointing at it, so a
 * property renamed next year leaves this year's receipts as they were.
 *
 * <p>Not a BIR official receipt. Lizmo is not registered to issue those,
 * and the apps say so on its face.
 */
@Entity
@Table(name = "receipts")
public class Receipt {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "payment_id", nullable = false, updatable = false)
    private UUID paymentId;

    @Column(name = "lease_id", nullable = false, updatable = false)
    private UUID leaseId;

    @Column(name = "landlord_id", nullable = false, updatable = false)
    private UUID landlordId;

    @Column(name = "tenant_id", nullable = false, updatable = false)
    private UUID tenantId;

    @Column(nullable = false, updatable = false)
    private short year;

    @Column(nullable = false, updatable = false)
    private int sequence;

    @Column(nullable = false, updatable = false)
    private String number;

    @Column(name = "issued_at", nullable = false, updatable = false)
    private Instant issuedAt;

    @Column(name = "received_from", nullable = false)
    private String receivedFrom;

    @Column(name = "received_by", nullable = false)
    private String receivedBy;

    @Column(name = "property_name", nullable = false, updatable = false)
    private String propertyName;

    @Column(nullable = false, updatable = false)
    private String place;

    @Column(name = "period_label", nullable = false, updatable = false)
    private String periodLabel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false)
    private BillingPeriodKind kind;

    @Column(nullable = false, updatable = false)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", nullable = false, updatable = false)
    private PaymentMethod paymentMethod;

    @Column(name = "sent_to", updatable = false)
    private String sentTo;

    @Column(name = "paid_on", nullable = false, updatable = false)
    private LocalDate paidOn;

    @Column(name = "still_owed", nullable = false, updatable = false)
    private BigDecimal stillOwed;

    protected Receipt() {
        // JPA
    }

    Receipt(
            UUID paymentId, UUID leaseId, UUID landlordId, UUID tenantId,
            short year, int sequence, Instant issuedAt,
            String receivedFrom, String receivedBy, String propertyName, String place,
            String periodLabel, BillingPeriodKind kind, BigDecimal amount,
            PaymentMethod paymentMethod, String sentTo, LocalDate paidOn,
            BigDecimal stillOwed) {
        this.paymentId = paymentId;
        this.leaseId = leaseId;
        this.landlordId = landlordId;
        this.tenantId = tenantId;
        this.year = year;
        this.sequence = sequence;
        this.number = numbered(year, sequence);
        this.issuedAt = issuedAt;
        this.receivedFrom = receivedFrom;
        this.receivedBy = receivedBy;
        this.propertyName = propertyName;
        this.place = place;
        this.periodLabel = periodLabel;
        this.kind = kind;
        this.amount = amount;
        this.paymentMethod = paymentMethod;
        this.sentTo = sentTo;
        this.paidOn = paidOn;
        this.stillOwed = stillOwed;
    }

    /** "2026-0042". */
    static String numbered(int year, int sequence) {
        return "%d-%04d".formatted(year, sequence);
    }

    public UUID getId() {
        return id;
    }

    public UUID getPaymentId() {
        return paymentId;
    }

    public UUID getLeaseId() {
        return leaseId;
    }

    public UUID getLandlordId() {
        return landlordId;
    }

    public UUID getTenantId() {
        return tenantId;
    }

    public String getNumber() {
        return number;
    }

    public Instant getIssuedAt() {
        return issuedAt;
    }

    public String getReceivedFrom() {
        return receivedFrom;
    }

    public String getReceivedBy() {
        return receivedBy;
    }

    public String getPropertyName() {
        return propertyName;
    }

    public String getPlace() {
        return place;
    }

    public String getPeriodLabel() {
        return periodLabel;
    }

    public BillingPeriodKind getKind() {
        return kind;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public PaymentMethod getPaymentMethod() {
        return paymentMethod;
    }

    public String getSentTo() {
        return sentTo;
    }

    public LocalDate getPaidOn() {
        return paidOn;
    }

    public BigDecimal getStillOwed() {
        return stillOwed;
    }
}
