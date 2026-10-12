package app.lizmo.notice;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** What goes in and out of announcements. */
public final class NoticeDtos {

    private NoticeDtos() {
    }

    @Schema(description = "An announcement to post")
    public record PostNotice(
            @NotBlank @Size(max = 80)
            @Schema(example = "Water off on Saturday")
            String title,

            @NotBlank @Size(max = 2000)
            @Schema(example = "Maynilad is working on the main line, 9am to noon. "
                    + "Fill a bucket the night before.")
            String message,

            @Schema(description = "One unit only. Null for everybody in the building.")
            UUID unitId,

            @Schema(example = "2026-10-17",
                    description = "The last day it is shown. Null for until taken down.")
            LocalDate until) {
    }

    @Schema(description = "An announcement, as the landlord who posted it sees it")
    public record NoticeResponse(
            UUID id,
            UUID propertyId,
            String propertyName,
            @Schema(description = "Set when it went to one unit only") UUID unitId,
            String unitNumber,
            String title,
            String message,
            Instant postedAt,
            @Schema(description = "The last day it is shown, if it has one") LocalDate until,
            @Schema(description = "False once past its last day") boolean live,
            @Schema(description = "How many of the people it is for have opened it")
            int seenBy,
            @Schema(description = "How many people it is for: everybody renting there now")
            int audience) {
    }

    @Schema(description = "An announcement, as a tenant sees it")
    public record MyNoticeResponse(
            UUID id,
            String propertyName,
            @Schema(description = "Set when it went to their unit only") String unitNumber,
            String fromName,
            String title,
            String message,
            Instant postedAt,
            LocalDate until,
            boolean read) {
    }
}
