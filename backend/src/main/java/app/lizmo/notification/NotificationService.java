package app.lizmo.notification;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.notification.dto.NotificationResponse;
import java.time.Clock;
import java.util.List;
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
    private final Clock clock;

    public NotificationService(NotificationRepository notifications, Clock clock) {
        this.notifications = notifications;
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
        notifications.save(
                new Notification(recipient, type, title, message, entityType, entityId));
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> mine(UUID userId) {
        return notifications.findByRecipientUserIdOrderByCreatedAtDesc(userId).stream()
                .map(NotificationResponse::of)
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
