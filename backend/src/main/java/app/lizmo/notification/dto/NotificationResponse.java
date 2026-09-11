package app.lizmo.notification.dto;

import app.lizmo.notification.Notification;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationType;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

/**
 * @param relatedEntityId what the notification is about, exactly as it was
 *                        raised.
 * @param leaseId         the tenancy it concerns, where it concerns one. The
 *                        app opens this rather than [relatedEntityId]: a
 *                        payment or a month of rent cannot be opened on its
 *                        own, and nothing answers "which tenancy is this
 *                        payment on" -- so without this, a landlord told a
 *                        tenant has paid had no way to get to the tenant.
 * @param propertyId      the property it concerns, for a request about a
 *                        room, whose answers live on the property.
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
        UUID leaseId,
        UUID propertyId,
        Instant createdAt) {

    public static NotificationResponse of(Notification notification) {
        return of(notification, null, null);
    }

    public static NotificationResponse of(
            Notification notification, UUID leaseId, UUID propertyId) {
        return new NotificationResponse(
                notification.getId(),
                notification.getType(),
                notification.getTitle(),
                notification.getMessage(),
                notification.isUnread(),
                notification.getRelatedEntityType(),
                notification.getRelatedEntityId(),
                leaseId,
                propertyId,
                notification.getCreatedAt());
    }
}
