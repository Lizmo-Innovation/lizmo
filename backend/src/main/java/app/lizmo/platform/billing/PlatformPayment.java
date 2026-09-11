package app.lizmo.platform.billing;

import app.lizmo.billing.PaymentMethod;
import app.lizmo.billing.PaymentStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * A landlord saying they have paid Lizmo, and what an admin made of it.
 *
 * <p>The same shape as a tenant paying rent, because it is the same event one
 * level up: money moved outside the app, proof uploaded, somebody on the
 * receiving end agrees or does not. Only agreement moves the invoice.
 */
@Entity
@Table(name = "platform_payments")
public class PlatformPayment {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "billing_cycle_id", nullable = false, updatable = false)
    private UUID invoiceId;

    @Column(name = "amount_paid", nullable = false, updatable = false)
    private BigDecimal amountPaid;

    @Column(name = "payment_date", nullable = false, updatable = false)
    private LocalDate paymentDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", nullable = false, updatable = false)
    private PaymentMethod paymentMethod;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentStatus status = PaymentStatus.PENDING_VERIFICATION;

    @Column(name = "submitted_by", nullable = false, updatable = false)
    private UUID submittedBy;

    @Column(name = "verified_by")
    private UUID verifiedBy;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    @Column
    private String remarks;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected PlatformPayment() {
    }

    public PlatformPayment(
            UUID invoiceId,
            BigDecimal amountPaid,
            LocalDate paymentDate,
            PaymentMethod paymentMethod,
            UUID submittedBy,
            String remarks) {
        this.invoiceId = invoiceId;
        this.amountPaid = amountPaid;
        this.paymentDate = paymentDate;
        this.paymentMethod = paymentMethod;
        this.submittedBy = submittedBy;
        this.remarks = remarks;
    }

    /** An admin agreeing the money arrived. The caller credits the invoice. */
    public void confirm(UUID adminId, Instant at) {
        this.status = PaymentStatus.CONFIRMED;
        this.verifiedBy = adminId;
        this.verifiedAt = at;
    }

    /**
     * An admin saying it did not arrive, and why.
     *
     * <p>The landlord's own note is replaced by the reason, which is the thing
     * they now need to read.
     */
    public void reject(UUID adminId, Instant at, String why) {
        this.status = PaymentStatus.REJECTED;
        this.verifiedBy = adminId;
        this.verifiedAt = at;
        if (why != null && !why.isBlank()) {
            this.remarks = why.trim();
        }
    }

    public boolean isPending() {
        return status == PaymentStatus.PENDING_VERIFICATION;
    }

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public UUID getInvoiceId() {
        return invoiceId;
    }

    public BigDecimal getAmountPaid() {
        return amountPaid;
    }

    public LocalDate getPaymentDate() {
        return paymentDate;
    }

    public PaymentMethod getPaymentMethod() {
        return paymentMethod;
    }

    public PaymentStatus getStatus() {
        return status;
    }

    public UUID getSubmittedBy() {
        return submittedBy;
    }

    public UUID getVerifiedBy() {
        return verifiedBy;
    }

    public Instant getVerifiedAt() {
        return verifiedAt;
    }

    public String getRemarks() {
        return remarks;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
