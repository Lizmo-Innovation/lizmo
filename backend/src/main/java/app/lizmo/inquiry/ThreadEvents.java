package app.lizmo.inquiry;

import app.lizmo.billing.BillingPeriod;
import app.lizmo.billing.BillingPeriodRepository;
import app.lizmo.billing.Payment;
import app.lizmo.billing.PaymentRepository;
import app.lizmo.billing.PaymentStatus;
import app.lizmo.billing.receipt.Receipt;
import app.lizmo.billing.receipt.ReceiptRepository;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentType;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.inquiry.dto.InquiryDtos.ThreadEvent;
import app.lizmo.inquiry.dto.InquiryDtos.ThreadEventKind;
import app.lizmo.lease.Lease;
import app.lizmo.maintenance.MaintenanceReport;
import app.lizmo.maintenance.MaintenanceReportRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * What changed the tenancy, to sit in its conversation between what was said.
 *
 * <p>A thread that runs the length of a tenancy is its history: the ID shared
 * before it, the rent said to be paid and then confirmed, the fan reported and
 * then fixed. Each kept as a card rather than a message, so talking and doing
 * stay apart and nothing that happened is lost in "paid na po".
 *
 * <p>Facts only, and the same facts for both sides. The words are the
 * phone's: it knows whose name to put on "Waiting for".
 */
@Service
public class ThreadEvents {

    /** How long before its end a fixed-term lease is said to be ending. */
    static final int ENDING_WITHIN_DAYS = 30;

    private final StoredDocumentRepository documents;
    private final PaymentRepository payments;
    private final BillingPeriodRepository periods;
    private final ReceiptRepository receipts;
    private final MaintenanceReportRepository repairs;
    private final Clock clock;

    public ThreadEvents(
            StoredDocumentRepository documents,
            PaymentRepository payments,
            BillingPeriodRepository periods,
            ReceiptRepository receipts,
            MaintenanceReportRepository repairs,
            Clock clock) {
        this.documents = documents;
        this.payments = payments;
        this.periods = periods;
        this.receipts = receipts;
        this.repairs = repairs;
        this.clock = clock;
    }

    /**
     * Oldest first, as the messages are.
     *
     * @param lease the tenancy the conversation belongs to; null before one.
     */
    @Transactional(readOnly = true)
    public List<ThreadEvent> of(Inquiry inquiry, Lease lease) {
        List<ThreadEvent> events = new ArrayList<>();
        idShared(inquiry, events);
        if (lease != null) {
            tenancy(lease, events);
            money(lease, events);
            repairs(lease, events);
        }
        events.sort(Comparator.comparing(ThreadEvent::at));
        return events;
    }

    /**
     * The photo of their ID, which is what makes them somebody a landlord can
     * let to. Dated no earlier than the conversation: an ID uploaded a year
     * ago was shared with this landlord when they started asking.
     */
    private void idShared(Inquiry inquiry, List<ThreadEvent> events) {
        documents.findByOwnerTypeAndOwnerIdAndDocType(
                        DocumentOwnerType.TENANT, inquiry.getTenantId(), DocumentType.VALID_ID)
                .map(StoredDocument::getUploadedAt)
                .ifPresent(uploaded -> {
                    Instant started = inquiry.getCreatedAt();
                    Instant at = uploaded == null || (started != null && uploaded.isBefore(started))
                            ? started
                            : uploaded;
                    if (at != null) {
                        events.add(event(ThreadEventKind.ID_SHARED, at, null, null, null, null, null));
                    }
                });
    }

    private void tenancy(Lease lease, List<ThreadEvent> events) {
        ZoneId zone = clock.getZone();
        LocalDate today = LocalDate.now(clock);
        if (lease.getStartDate() != null) {
            events.add(event(ThreadEventKind.LEASE_STARTED,
                    lease.getStartDate().atStartOfDay(zone).toInstant(),
                    lease.getId(), lease.getRentAmount(), null, null, null));
        }
        LocalDate ends = lease.getTermEndsOn();
        if (lease.isActive() && ends != null
                && !today.isBefore(ends.minusDays(ENDING_WITHIN_DAYS))) {
            // Where it came into view, not where it falls: a card dated next
            // month would sit below everything said today.
            LocalDate noticed = ends.minusDays(ENDING_WITHIN_DAYS);
            if (lease.getStartDate() != null && noticed.isBefore(lease.getStartDate())) {
                noticed = lease.getStartDate();
            }
            events.add(event(ThreadEventKind.LEASE_ENDING,
                    noticed.atStartOfDay(zone).toInstant(),
                    lease.getId(), null, ends.toString(), null, null));
        }
        if (!lease.isActive() && lease.getEndDate() != null) {
            events.add(event(ThreadEventKind.MOVED_OUT,
                    lease.getEndDate().atTime(23, 59, 59).atZone(zone).toInstant(),
                    lease.getId(), null, null, null, null));
        }
    }

    private void money(Lease lease, List<ThreadEvent> events) {
        List<Payment> paid = payments.findByLeaseIdOrderByPaymentDateDesc(lease.getId());
        if (paid.isEmpty()) {
            return;
        }
        Map<UUID, String> months = new HashMap<>();
        for (BillingPeriod period : periods.findByLeaseIdOrderByPeriodStartAsc(lease.getId())) {
            months.put(period.getId(), period.describe());
        }
        Map<UUID, Receipt> issued = new HashMap<>();
        for (Receipt receipt : receipts.findByPaymentIdIn(paid.stream().map(Payment::getId).toList())) {
            issued.put(receipt.getPaymentId(), receipt);
        }

        for (Payment payment : paid) {
            String month = months.get(payment.getBillingPeriodId());
            boolean told = lease.getTenantId().equals(payment.getSubmittedBy());
            // What the tenant said, whatever came of it: "I have paid" is a
            // thing that happened even once it is confirmed.
            if (told && payment.getCreatedAt() != null) {
                events.add(event(ThreadEventKind.PAYMENT_REPORTED, payment.getCreatedAt(),
                        payment.getId(), payment.getAmountPaid(), month, null,
                        payment.getStatus().name()));
            }
            if (payment.getStatus() == PaymentStatus.CONFIRMED) {
                Receipt receipt = issued.get(payment.getId());
                Instant at = receipt != null && receipt.getIssuedAt() != null
                        ? receipt.getIssuedAt()
                        : payment.getVerifiedAt() != null ? payment.getVerifiedAt() : payment.getCreatedAt();
                if (at != null) {
                    events.add(event(ThreadEventKind.PAYMENT_CONFIRMED, at, payment.getId(),
                            payment.getAmountPaid(), month,
                            receipt == null ? null : receipt.getNumber(), null));
                }
            } else if (payment.getStatus() == PaymentStatus.REJECTED
                    && payment.getVerifiedAt() != null) {
                events.add(event(ThreadEventKind.PAYMENT_REJECTED, payment.getVerifiedAt(),
                        payment.getId(), payment.getAmountPaid(), month, null, null));
            }
        }
    }

    private void repairs(Lease lease, List<ThreadEvent> events) {
        for (MaintenanceReport report : repairs.findBySubmittedByOrderBySubmittedAtDesc(lease.getTenantId())) {
            if (!lease.getId().equals(report.getLeaseId()) || report.getSubmittedAt() == null) {
                continue;
            }
            events.add(event(ThreadEventKind.REPAIR_REPORTED, report.getSubmittedAt(),
                    report.getId(), null, report.getDescription(), null,
                    report.getStatus().name()));
        }
    }

    private static ThreadEvent event(ThreadEventKind kind, Instant at, UUID entityId,
            java.math.BigDecimal amount, String label, String receiptNumber, String state) {
        return new ThreadEvent(kind, at, entityId, amount, label, receiptNumber, state);
    }
}
