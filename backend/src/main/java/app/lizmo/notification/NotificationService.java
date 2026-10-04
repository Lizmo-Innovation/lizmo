package app.lizmo.notification;

import app.lizmo.billing.BillingPeriodRepository;
import app.lizmo.billing.PaymentRepository;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.notification.dto.NotificationResponse;
import app.lizmo.inquiry.InquiryRepository;
import java.time.Clock;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Telling people what happened.
 *
 * <p>Written as a record rather than a delivery: a person who was asleep when
 * their request was answered still has to find out, and a row they will see
 * next time they open the app is the only version of that which cannot be
 * missed. Push, when it exists, delivers a copy of this — it does not replace
 * it.
 *
 * <p>The wording is decided by whoever raises the notification, not by this
 * class. What somebody was told is a fact about the past, and rendering it
 * from a type at read time would rewrite it every time the copy changed.
 */
@Service
public class NotificationService {

    private final NotificationRepository notifications;
    private final PaymentRepository payments;
    private final BillingPeriodRepository periods;
    private final InquiryRepository inquiries;
    private final Clock clock;

    public NotificationService(
            NotificationRepository notifications,
            PaymentRepository payments,
            BillingPeriodRepository periods,
            InquiryRepository inquiries,
            Clock clock) {
        this.notifications = notifications;
        this.payments = payments;
        this.periods = periods;
        this.inquiries = inquiries;
        this.clock = clock;
    }

    /**
     * Raises one.
     *
     * <p>Never throws at the caller. A notification is a side effect of
     * something that already happened -- a lease exists, a bed is taken -- and
     * failing to record the announcement must not undo the event it is
     * announcing.
     */
    @Transactional
    public void raise(
            UUID recipient,
            NotificationType type,
            String title,
            String message,
            NotificationEntityType entityType,
            UUID entityId) {
        if (recipient == null) {
            return;
        }
        notifications.save(new Notification(
                recipient, type, title, message, entityType, entityId, clock.instant()));
    }

    /**
     * Everything this person has been told, each with the tenancy or property
     * it leads to.
     *
     * <p>Resolved as it is read rather than stored when raised, so that the
     * notifications written before tapping one opened anything lead somewhere
     * too. One query per kind of thing, not per row: a feed of forty payments
     * is still three lookups.
     */
    @Transactional(readOnly = true)
    public List<NotificationResponse> mine(UUID userId) {
        List<Notification> rows =
                notifications.findByRecipientUserIdOrderByCreatedAtDesc(userId);

        Map<UUID, UUID> leaseOfPayment = new HashMap<>();
        payments.findAllById(idsOf(rows, NotificationEntityType.PAYMENT))
                .forEach(payment -> leaseOfPayment.put(payment.getId(), payment.getLeaseId()));

        Map<UUID, UUID> leaseOfPeriod = new HashMap<>();
        periods.findAllById(idsOf(rows, NotificationEntityType.BILLING_PERIOD))
                .forEach(period -> leaseOfPeriod.put(period.getId(), period.getLeaseId()));

        // Which property a conversation is about, so tapping the notification
        // can open the place as well as the thread. Rows raised before threads
        // existed point at a rental request, which is gone: they resolve to
        // nothing rather than being rewritten, because they are a record of
        // what happened.
        Map<UUID, UUID> propertyOfInquiry = new HashMap<>();
        inquiries.findAllById(idsOf(rows, NotificationEntityType.INQUIRY))
                .forEach(inquiry -> propertyOfInquiry.put(
                        inquiry.getId(), inquiry.getPropertyId()));

        return rows.stream()
                .map(row -> {
                    UUID about = row.getRelatedEntityId();
                    NotificationEntityType kind = row.getRelatedEntityType();
                    UUID lease = kind == null ? null : switch (kind) {
                        case LEASE -> about;
                        case PAYMENT -> leaseOfPayment.get(about);
                        case BILLING_PERIOD -> leaseOfPeriod.get(about);
                        default -> null;
                    };
                    UUID property = kind == NotificationEntityType.INQUIRY
                            ? propertyOfInquiry.get(about)
                            : null;
                    return NotificationResponse.of(row, lease, property);
                })
                .toList();
    }

    private static List<UUID> idsOf(List<Notification> rows, NotificationEntityType kind) {
        return rows.stream()
                .filter(row -> row.getRelatedEntityType() == kind)
                .map(Notification::getRelatedEntityId)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
    }

    @Transactional(readOnly = true)
    public long unreadCount(UUID userId) {
        return notifications.countByRecipientUserIdAndStatus(
                userId, NotificationStatus.UNREAD);
    }

    /**
     * @throws ApiException if the notification belongs to somebody else. 404
     *                      rather than 403: whether a notification exists is
     *                      not something to confirm to a stranger.
     */
    @Transactional
    public void markRead(UUID notificationId, UUID userId) {
        Notification notification = notifications.findById(notificationId)
                .filter(candidate -> candidate.getRecipientUserId().equals(userId))
                .orElseThrow(() -> new ApiException(
                        ErrorCode.NOT_FOUND, "No such notification."));

        notification.markRead(clock.instant());
        notifications.save(notification);
    }

    /** For the "mark everything read" the badge invites. */
    @Transactional
    public void markAllRead(UUID userId) {
        List<Notification> unread = notifications.findByRecipientUserIdAndStatus(
                userId, NotificationStatus.UNREAD);
        for (Notification notification : unread) {
            notification.markRead(clock.instant());
        }
        notifications.saveAll(unread);
    }
}
