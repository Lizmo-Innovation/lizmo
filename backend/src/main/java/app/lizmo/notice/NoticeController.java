package app.lizmo.notice;

import app.lizmo.common.ApiError;
import app.lizmo.notice.NoticeDtos.MyNoticeResponse;
import app.lizmo.notice.NoticeDtos.NoticeResponse;
import app.lizmo.notice.NoticeDtos.PostNotice;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Announcements from a landlord to everybody in a building, or in one unit. */
@RestController
@Tag(name = "Announcements", description = "A landlord telling everybody at once")
public class NoticeController {

    private final NoticeService notices;
    private final CurrentUser currentUser;

    public NoticeController(NoticeService notices, CurrentUser currentUser) {
        this.notices = notices;
        this.currentUser = currentUser;
    }

    // ---- the landlord ------------------------------------------------------

    @PostMapping("/api/v1/properties/{propertyId}/notices")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "postNotice", summary = "Post an announcement",
            description = "To everybody renting in the building, or in one unit. Those "
                    + "living there now are notified; anybody who moves in while it is "
                    + "up sees it too. Cannot be edited: take it down and post again.")
    @ApiResponse(responseCode = "201", description = "Posted",
            content = @Content(schema = @Schema(implementation = NoticeResponse.class)))
    @ApiResponse(responseCode = "404", description = "Not your property, or not its unit",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public NoticeResponse post(
            @PathVariable UUID propertyId, @Valid @RequestBody PostNotice command) {
        return notices.post(propertyId, currentUser.requireId(), command);
    }

    @GetMapping("/api/v1/properties/{propertyId}/notices")
    @Operation(operationId = "listPropertyNotices", summary = "Announcements up on a building",
            description = "Newest first, with how many of the people each is for have "
                    + "opened it. Taken-down ones are not listed.")
    @ApiResponse(responseCode = "200", description = "The announcements",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = NoticeResponse.class))))
    public List<NoticeResponse> forProperty(@PathVariable UUID propertyId) {
        return notices.forProperty(propertyId, currentUser.requireId());
    }

    @PostMapping("/api/v1/notices/{id}/take-down")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "takeDownNotice", summary = "Take an announcement down",
            description = "Gone from every tenant's screen. Nobody is told.")
    @ApiResponse(responseCode = "204", description = "Taken down")
    public void takeDown(@PathVariable UUID id) {
        notices.takeDown(id, currentUser.requireId());
    }

    // ---- the tenant --------------------------------------------------------

    @GetMapping("/api/v1/me/notices")
    @Operation(operationId = "listMyNotices", summary = "Announcements where I live",
            description = "Everything up in the buildings, and units, I rent in now, "
                    + "newest first.")
    @ApiResponse(responseCode = "200", description = "The announcements",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = MyNoticeResponse.class))))
    public List<MyNoticeResponse> mine() {
        return notices.mine(currentUser.requireId());
    }

    @PostMapping("/api/v1/me/notices/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "markNoticeRead", summary = "I have read this announcement")
    @ApiResponse(responseCode = "204", description = "Marked")
    public void read(@PathVariable UUID id) {
        notices.read(id, currentUser.requireId());
    }
}
