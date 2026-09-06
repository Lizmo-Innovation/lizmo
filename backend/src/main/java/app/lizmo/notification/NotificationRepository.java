package app.lizmo.notification;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    /** What is waiting for somebody, newest first. */
    List<Notification> findByRecipientUserIdOrderByCreatedAtDesc(UUID recipientUserId);

    /** The badge. */
    long countByRecipientUserIdAndStatus(UUID recipientUserId, NotificationStatus status);

    List<Notification> findByRecipientUserIdAndStatus(
            UUID recipientUserId, NotificationStatus status);
}
