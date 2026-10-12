package app.lizmo.property.place;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

/**
 * The landlord, as somebody deciding whether to ask sees them: enough to know
 * there is a person and whether they answer, and nothing to reach them by.
 */
@Schema(description = "Who lets this place, as a stranger sees them")
public record LandlordCard(
        @Schema(example = "Elena B.", description = "First name and last initial")
        String name,

        @Schema(description = "When they joined Lizmo; the apps show the month")
        LocalDate since,

        @Schema(description = "How fast they usually answer somebody asking. Null until "
                + "there have been enough conversations to say.")
        ReplySpeed replies) {

    public enum ReplySpeed {
        WITHIN_AN_HOUR,
        WITHIN_A_DAY,
        WITHIN_DAYS
    }
}
