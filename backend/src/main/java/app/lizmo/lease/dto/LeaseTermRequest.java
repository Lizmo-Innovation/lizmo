package app.lizmo.lease.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

@Schema(description = "When a lease is meant to end")
public record LeaseTermRequest(
        @Schema(example = "2027-08-31",
                description = "The last day of the lease. Null takes the end date away, "
                        + "leaving it month to month. A later date is how a lease is "
                        + "extended.")
        LocalDate endsOn) {
}
