package app.lizmo.notification;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    /** What is waiting for somebody, newest first. */
    List<Notification> findByRecipientUserIdOrderByCreatedAtDesc(UUID recipientUserId);

    /** The badge. */
    long countByRecipientUserIdAndStatus(UUID recipientUserId, NotificationStatus status);

    /**
     * The last time this person was told this particular thing about this
     * particular row.
     *
     * <p>What makes rent reminders idempotent without a second table: the
     * notifications already raised are the record of what was sent.
     */
    java.util.Optional<Notification>
            findFirstByRecipientUserIdAndTypeAndRelatedEntityIdOrderByCreatedAtDesc(
                    UUID recipientUserId, NotificationType type, UUID relatedEntityId);

    List<Notification> findByRecipientUserIdAndStatus(
            UUID recipientUserId, NotificationStatus status);
}
