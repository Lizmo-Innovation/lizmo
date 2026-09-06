package app.lizmo.notification.dto;

import app.lizmo.notification.Notification;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationType;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

/**
 * @param relatedEntityId what to open when it is tapped. The app decides how,
 *                        from the entity type — a notification that cannot be
 *                        acted on is a notification somebody dismisses.
 */
@Schema(description = "Something waiting to be read")
public record NotificationResponse(
        UUID id,
        NotificationType type,
        String title,
        String message,
        boolean unread,
        NotificationEntityType relatedEntityType,
        UUID relatedEntityId,
        Instant createdAt) {

    public static NotificationResponse of(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getType(),
                notification.getTitle(),
                notification.getMessage(),
                notification.isUnread(),
                notification.getRelatedEntityType(),
                notification.getRelatedEntityId(),
                notification.getCreatedAt());
    }
}
