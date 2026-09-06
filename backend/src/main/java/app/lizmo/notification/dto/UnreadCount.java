package app.lizmo.notification.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/** What the badge shows. Its own endpoint so a badge costs one small request. */
@Schema(description = "How many notifications are unread")
public record UnreadCount(long unread) {
}
