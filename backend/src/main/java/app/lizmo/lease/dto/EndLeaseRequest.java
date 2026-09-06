package app.lizmo.lease.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;
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
        @Schema(example = "2026-09-30") LocalDate endDate,

        @DecimalMin(value = "0.0")
        @Schema(example = "4500.00",
                description = "How much of the deposit went back. Null when there was "
                        + "no deposit, or when the landlord has not settled it yet.")
        java.math.BigDecimal depositReturned,

        @Size(max = 2000)
        @Schema(example = "Withheld P500 for the broken window latch.",
                description = "What was withheld and why, in the landlord's own words. "
                        + "Free text rather than itemised deductions: withholding money "
                        + "is where tenancies go wrong, and an explanation somebody "
                        + "actually wrote beats a form nobody fills in honestly.")
        String depositSettlement) {
}
