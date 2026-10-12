package app.lizmo.billing;

import app.lizmo.billing.channel.LandlordPaymentChannelService;
import app.lizmo.billing.dto.PaymentResponse;
import app.lizmo.billing.dto.RecordPaymentRequest;
import app.lizmo.billing.receipt.Receipt;
import app.lizmo.billing.receipt.ReceiptService;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.DocumentType;
import app.lizmo.document.ImageNormaliser;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeasePaperworkAccess;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

/**
 * Money handed over, written down.
 *
 * <p>Lizmo does not move the money. People pay by GCash, by transfer, or in
 * cash at the door; this is the agreed note of it afterwards, which is the
 * thing a notebook was doing before.
 *
 * <p>Either side can write one, and who wrote it decides whether it counts
 * immediately. A landlord recording money they received is confirming it in
 * the same breath -- there is nobody for them to disagree with. A tenant
 * saying they paid is making a claim, and it waits.
 */
@Service
public class PaymentService {

    private static final Duration URL_LIFETIME = Duration.ofMinutes(10);

    private static final long MAX_UPLOAD_BYTES = 10L * 1024 * 1024;

    private final PaymentRepository payments;
    private final BillingPeriodRepository periods;
    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;
    private final LeasePaperworkAccess access;
    private final NotificationService notifications;
    private final LandlordPaymentChannelService channels;
    private final ReceiptService receipts;
    private final Clock clock;

    public PaymentService(
            PaymentRepository payments,
            BillingPeriodRepository periods,
            StoredDocumentRepository documents,
            DocumentStore store,
            ImageNormaliser normaliser,
            LeasePaperworkAccess access,
            NotificationService notifications,
            LandlordPaymentChannelService channels,
            ReceiptService receipts,
            Clock clock) {
        this.payments = payments;
        this.periods = periods;
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
        this.access = access;
        this.notifications = notifications;
        this.channels = channels;
        this.receipts = receipts;
        this.clock = clock;
    }

    /**
     * A landlord writing down money they have received.
     *
     * <p>Confirmed on the spot, and the month's balance moves immediately.
     */
    @Transactional
    public PaymentResponse recordByLandlord(
            UUID leaseId, UUID landlordId, RecordPaymentRequest command) {
        Lease lease = access.requireLandlord(leaseId, landlordId);
        BillingPeriod period = periodOn(lease, command.billingPeriodId());

        Payment payment = save(lease, period, command, landlordId,
                PaymentStatus.CONFIRMED);

        period.credit(payment.getAmountPaid());
        periods.save(period);
        Receipt receipt = receipts.issue(lease, period, payment);

        // Their own record reaching them, so a tenant is not left wondering
        // whether the landlord wrote it down -- with the receipt that says so.
        notifications.raise(
                lease.getTenantId(),
                NotificationType.PAYMENT_CONFIRMED,
                "Your landlord recorded a payment",
                "P%s recorded against %s. Receipt %s."
                        .formatted(plain(payment.getAmountPaid()), period.describe(),
                                receipt.getNumber()),
                NotificationEntityType.PAYMENT,
                payment.getId());

        return describe(payment);
    }

    /**
     * A tenant saying they have paid.
     *
     * <p>Waits for the landlord. Nothing about the balance moves until
     * somebody who would know agrees it arrived.
     */
    @Transactional
    public PaymentResponse declareByTenant(
            UUID leaseId, UUID tenantId, RecordPaymentRequest command, MultipartFile proof) {
        Lease lease = access.requireTenant(leaseId, tenantId);
        BillingPeriod period = periodOn(lease, command.billingPeriodId());

        Payment payment = save(lease, period, command, tenantId,
                PaymentStatus.PENDING_VERIFICATION);

        if (proof != null && !proof.isEmpty()) {
            attachProof(payment, tenantId, proof);
        }

        notifications.raise(
                landlordOf(lease),
                // Declared, not confirmed: nothing is confirmed until the
                // landlord says so, which is the next thing they are asked.
                NotificationType.PAYMENT_DECLARED,
                "A tenant says they have paid",
                "P%s for %s is waiting for you to confirm."
                        .formatted(plain(payment.getAmountPaid()), period.describe()),
                NotificationEntityType.PAYMENT,
                payment.getId());

        return describe(payment);
    }

    /** Everything recorded against one tenancy, newest first. */
    @Transactional(readOnly = true)
    public List<PaymentResponse> forLandlord(UUID leaseId, UUID landlordId) {
        access.requireLandlord(leaseId, landlordId);
        return describeAll(leaseId);
    }

    @Transactional(readOnly = true)
    public List<PaymentResponse> forTenant(UUID leaseId, UUID tenantId) {
        access.requireTenant(leaseId, tenantId);
        return describeAll(leaseId);
    }

    /**
     * The landlord agreeing that money arrived.
     *
     * <p>The only thing that moves a balance for a tenant-declared payment.
     */
    @Transactional
    public PaymentResponse confirm(UUID leaseId, UUID paymentId, UUID landlordId) {
        Lease lease = access.requireLandlord(leaseId, landlordId);
        Payment payment = pending(leaseId, paymentId);

        payment.confirm(landlordId, clock.instant());
        payments.save(payment);

        BillingPeriod period = periods.findById(payment.getBillingPeriodId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such month."));
        period.credit(payment.getAmountPaid());
        periods.save(period);
        Receipt receipt = receipts.issue(lease, period, payment);

        notifications.raise(
                lease.getTenantId(),
                NotificationType.PAYMENT_CONFIRMED,
                "Your payment was confirmed",
                "P%s for %s. Receipt %s."
                        .formatted(plain(payment.getAmountPaid()), period.describe(),
                                receipt.getNumber()),
                NotificationEntityType.PAYMENT,
                payment.getId());

        return describe(payment);
    }

    /**
     * The landlord saying it did not arrive.
     *
     * <p>Rejected rather than deleted. A tenant who wrote something down and
     * found it gone would have no idea whether it was refused or lost, and the
     * disagreement itself is worth keeping.
     */
    @Transactional
    public PaymentResponse reject(
            UUID leaseId, UUID paymentId, UUID landlordId, String remarks) {
        Lease lease = access.requireLandlord(leaseId, landlordId);
        Payment payment = pending(leaseId, paymentId);

        payment.reject(landlordId, clock.instant(), remarks);
        payments.save(payment);

        // Nothing is credited, so no balance moves.
        BillingPeriod period = periods.findById(payment.getBillingPeriodId()).orElse(null);

        notifications.raise(
                lease.getTenantId(),
                NotificationType.PAYMENT_REJECTED,
                "Your payment was not confirmed",
                StringUtils.hasText(remarks)
                        ? "P%s for %s. %s".formatted(
                                plain(payment.getAmountPaid()),
                                period == null ? "rent" : period.describe(),
                                remarks.trim())
                        : "P%s for %s was not confirmed. Ask your landlord why."
                                .formatted(
                                        plain(payment.getAmountPaid()),
                                        period == null ? "rent" : period.describe()),
                NotificationEntityType.PAYMENT,
                payment.getId());

        return describe(payment);
    }

    // ---- the shared parts --------------------------------------------------

    private Payment save(
            Lease lease,
            BillingPeriod period,
            RecordPaymentRequest command,
            UUID by,
            PaymentStatus status) {

        if (command.amountPaid() == null
                || command.amountPaid().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A payment has to be more than nothing.");
        }

        LocalDate paidOn = command.paymentDate() == null
                ? LocalDate.now(clock)
                : command.paymentDate();

        Payment payment = new Payment(
                lease.getId(),
                period.getId(),
                command.amountPaid(),
                paidOn,
                command.paymentMethod() == null
                        ? PaymentMethod.OTHER
                        : command.paymentMethod(),
                by,
                status,
                command.remarks());
        payment.sendTo(channels.sentTo(lease, command.channelId()));
        payment.toldAt(clock.instant());
        return payments.save(payment);
    }

    /**
     * The month being paid for, checked to be on this tenancy.
     *
     * <p>Both halves matter: the second stops a period id from one lease being
     * paid against another the caller happens to hold.
     */
    private BillingPeriod periodOn(Lease lease, UUID billingPeriodId) {
        return periods.findById(billingPeriodId)
                .filter(period -> period.getLeaseId().equals(lease.getId()))
                .orElseThrow(() -> new ApiException(
                        ErrorCode.NOT_FOUND, "No such month on this tenancy."));
    }

    private Payment pending(UUID leaseId, UUID paymentId) {
        Payment payment = payments.findById(paymentId)
                .filter(candidate -> candidate.getLeaseId().equals(leaseId))
                .orElseThrow(() -> new ApiException(
                        ErrorCode.NOT_FOUND, "No such payment."));

        if (payment.getStatus() != PaymentStatus.PENDING_VERIFICATION) {
            // Confirming twice would credit the month twice, which is the one
            // way this feature could quietly invent money.
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That payment has already been answered.");
        }
        return payment;
    }

    private void attachProof(Payment payment, UUID by, MultipartFile file) {
        if (file.getSize() > MAX_UPLOAD_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file is larger than 10MB. Please upload a smaller photo.");
        }

        byte[] original;
        try {
            original = file.getBytes();
        } catch (IOException e) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That upload did not arrive in one piece. Please try again.");
        }

        // Re-encoded like every other photograph, so a screenshot carries no
        // EXIF and no location out of somebody's phone.
        byte[] normalised = normaliser.normalise(original);
        String key = "payments/%s/%s.jpg".formatted(payment.getId(), UUID.randomUUID());
        store.put(key, normalised, ImageNormaliser.OUTPUT_CONTENT_TYPE);

        documents.save(new StoredDocument(
                DocumentOwnerType.PAYMENT,
                payment.getId(),
                by,
                DocumentType.RECEIPT,
                key,
                ImageNormaliser.OUTPUT_CONTENT_TYPE,
                normalised.length));
    }

    private List<PaymentResponse> describeAll(UUID leaseId) {
        return payments.findByLeaseIdOrderByPaymentDateDesc(leaseId).stream()
                .map(this::describe)
                .toList();
    }

    private PaymentResponse describe(Payment payment) {
        String proofUrl = documents
                .findByOwnerTypeAndOwnerId(DocumentOwnerType.PAYMENT, payment.getId())
                .stream()
                .findFirst()
                .map(document -> store.presignedUrl(document.getStorageKey(), URL_LIFETIME))
                .orElse(null);

        String label = periods.findById(payment.getBillingPeriodId())
                .map(BillingPeriod::getPeriodLabel)
                .orElse(null);

        return PaymentResponse.of(payment, label, proofUrl, URL_LIFETIME.toSeconds(),
                receipts.ofPayment(payment.getId()));
    }

    private UUID landlordOf(Lease lease) {
        return access.landlordOf(lease);
    }

    private static String plain(BigDecimal amount) {
        return amount.stripTrailingZeros().toPlainString();
    }
}
