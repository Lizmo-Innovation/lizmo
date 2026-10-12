package app.lizmo.billing;

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
 * Money handed over against one month's rent.
 *
 * <p>A record of a payment, not a movement of one. Lizmo does not touch the
 * money: people pay by GCash, by transfer, or in cash at the door, and this is
 * the agreed note of it afterwards.
 *
 * <p>Which is why it has both a submitter and a verifier. A tenant saying they
 * paid and a landlord agreeing are different events, and only the second moves
 * a balance.
 */
@Entity
@Table(name = "payments")
public class Payment {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "lease_id", nullable = false, updatable = false)
    private UUID leaseId;

    @Column(name = "billing_period_id", nullable = false, updatable = false)
    private UUID billingPeriodId;

    @Column(name = "amount_paid", nullable = false)
    private BigDecimal amountPaid;

    @Column(name = "payment_date", nullable = false)
    private LocalDate paymentDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", nullable = false)
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

    @Column(name = "remarks")
    private String remarks;

    /** The landlord's word on a refusal. Apart from remarks, which are the payer's. */
    @Column(name = "rejection_reason")
    private String rejectionReason;

    /**
     * Where the payer said the money went, as the landlord's channel read at
     * that moment: "GCash · Ariel Asebias · 09771231234". Null for cash.
     */
    @Column(name = "sent_to")
    private String sentTo;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected Payment() {
    }

    public Payment(
            UUID leaseId,
            UUID billingPeriodId,
            BigDecimal amountPaid,
            LocalDate paymentDate,
            PaymentMethod paymentMethod,
            UUID submittedBy,
            PaymentStatus status,
            String remarks) {
        this.leaseId = leaseId;
        this.billingPeriodId = billingPeriodId;
        this.amountPaid = amountPaid;
        this.paymentDate = paymentDate;
        this.paymentMethod = paymentMethod;
        this.submittedBy = submittedBy;
        this.status = status;
        this.remarks = remarks;
        if (status == PaymentStatus.CONFIRMED) {
            // Recorded by the person who received it, so it is verified in the
            // same breath by the same person.
            this.verifiedBy = submittedBy;
            this.verifiedAt = Instant.now();
        }
    }

    /**
     * The landlord agreeing the money arrived.
     *
     * <p>Named rather than a status setter because it is the moment a balance
     * moves, and the caller must credit the month in the same transaction.
     */
    public void confirm(UUID landlordId, java.time.Instant at) {
        this.status = PaymentStatus.CONFIRMED;
        this.verifiedBy = landlordId;
        this.verifiedAt = at;
    }

    /**
     * The landlord saying it did not arrive.
     *
     * <p>Rejected, never deleted: a tenant who wrote something down and found
     * it gone would not know whether it was refused or lost, and the
     * disagreement is itself worth keeping.
     */
    public void reject(UUID landlordId, java.time.Instant at, String why) {
        this.status = PaymentStatus.REJECTED;
        this.verifiedBy = landlordId;
        this.verifiedAt = at;
        // Beside the payer's remarks, not over them: both are worth keeping,
        // and the tenant needs to know which words are the landlord's.
        this.rejectionReason = why == null || why.isBlank() ? null : why.trim();
    }

    /** Written once, when the payment is made, from the channel the payer picked. */
    public void sendTo(String channelLabel) {
        this.sentTo = channelLabel;
    }

    public String getSentTo() {
        return sentTo;
    }

    public boolean isConfirmed() {
        return status == PaymentStatus.CONFIRMED;
    }

    /**
     * When it was told to the app, from the application's clock.
     *
     * <p>How long a declared payment has waited is counted from this, by a job
     * reading that same clock. Stamped on persist from the machine's clock
     * instead, the two disagree the moment anything moves the application's
     * -- which tests do, and which is how this was found.
     */
    public void toldAt(Instant at) {
        this.createdAt = at;
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

    public UUID getLeaseId() {
        return leaseId;
    }

    public UUID getBillingPeriodId() {
        return billingPeriodId;
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

    public String getRemarks() {
        return remarks;
    }

    public String getRejectionReason() {
        return rejectionReason;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
