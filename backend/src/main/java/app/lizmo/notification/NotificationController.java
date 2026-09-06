package app.lizmo.notification;

import app.lizmo.notification.dto.NotificationResponse;
import app.lizmo.notification.dto.UnreadCount;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** What the app has to tell the person holding it. */
@RestController
@RequestMapping("/api/v1/me/notifications")
@Tag(name = "Notifications", description = "What is waiting to be read")
public class NotificationController {

    private final NotificationService notifications;
    private final CurrentUser currentUser;

    public NotificationController(
            NotificationService notifications, CurrentUser currentUser) {
        this.notifications = notifications;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "listMyNotifications", summary = "What is waiting",
            description = "Newest first, read and unread together: what happened last "
                    + "week is still the answer to what happened.")
    @ApiResponse(responseCode = "200", description = "The notifications")
    public List<NotificationResponse> mine() {
        return notifications.mine(currentUser.requireId());
    }

    @GetMapping("/unread-count")
    @Operation(operationId = "countUnreadNotifications", summary = "How many are unread",
            description = "Its own endpoint so drawing a badge costs one small request "
                    + "rather than the whole list.")
    public UnreadCount unread() {
        return new UnreadCount(notifications.unreadCount(currentUser.requireId()));
    }

    @PostMapping("/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "markNotificationRead", summary = "Mark one read")
    public void read(@PathVariable UUID id) {
        notifications.markRead(id, currentUser.requireId());
    }

    @PostMapping("/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "markAllNotificationsRead", summary = "Mark everything read",
            description = "What the badge invites somebody to do.")
    public void readAll() {
        notifications.markAllRead(currentUser.requireId());
    }
}
