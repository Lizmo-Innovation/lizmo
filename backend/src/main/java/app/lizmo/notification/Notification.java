package app.lizmo.notification;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Something the app has to tell somebody.
 *
 * <p>Stored rather than sent and forgotten: a person who was asleep when their
 * request was answered still needs to find out, and the only reliable place to
 * put that is a row they will see next time they open the app. Push delivery,
 * when it exists, is a second copy of this — not a replacement for it.
 *
 * <p>The title and message are written when the notification is raised, not
 * rendered from the type later. A notification is a record of what somebody
 * was told, and rebuilding the words afterwards from an id would quietly
 * rewrite history when the wording changes.
 */
@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "recipient_user_id", nullable = false, updatable = false)
    private UUID recipientUserId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false)
    private NotificationType type;

    @Enumerated(EnumType.STRING)
    @Column(name = "related_entity_type", updatable = false)
    private NotificationEntityType relatedEntityType;

    @Column(name = "related_entity_id", updatable = false)
    private UUID relatedEntityId;

    @Column(nullable = false, updatable = false)
    private String title;

    @Column(nullable = false, updatable = false)
    private String message;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NotificationStatus status = NotificationStatus.UNREAD;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "read_at")
    private Instant readAt;

    protected Notification() {
    }

    public Notification(
            UUID recipientUserId,
            NotificationType type,
            String title,
            String message,
            NotificationEntityType relatedEntityType,
            UUID relatedEntityId) {
        this.recipientUserId = recipientUserId;
        this.type = type;
        this.title = title;
        this.message = message;
        this.relatedEntityType = relatedEntityType;
        this.relatedEntityId = relatedEntityId;
        this.status = NotificationStatus.UNREAD;
    }

    public void markRead(Instant at) {
        if (status == NotificationStatus.READ) {
            return;
        }
        this.status = NotificationStatus.READ;
        this.readAt = at;
    }

    public boolean isUnread() {
        return status == NotificationStatus.UNREAD;
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

    public UUID getRecipientUserId() {
        return recipientUserId;
    }

    public NotificationType getType() {
        return type;
    }

    public NotificationEntityType getRelatedEntityType() {
        return relatedEntityType;
    }

    public UUID getRelatedEntityId() {
        return relatedEntityId;
    }

    public String getTitle() {
        return title;
    }

    public String getMessage() {
        return message;
    }

    public NotificationStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getReadAt() {
        return readAt;
    }
}
