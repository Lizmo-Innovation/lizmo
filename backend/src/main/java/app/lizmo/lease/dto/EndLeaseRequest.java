package app.lizmo.lease.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

/**
 * How a tenancy finished.
 *
 * @param terminated true when it was stopped early rather than run to its end.
 *                   Two different things to look back on, and flattening them
 *                   would lose the only record of which happened.
 * @param endDate    defaults to today. Backdating is allowed because a landlord
 *                   records the move-out after it happened, not during it.
 */
@Schema(description = "Ending a lease")
public record EndLeaseRequest(
        @Schema(example = "false") Boolean terminated,
        @Schema(example = "2026-09-30") LocalDate endDate) {
}
