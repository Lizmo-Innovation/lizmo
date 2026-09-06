package app.lizmo.lease.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * The terms a landlord is accepting on.
 *
 * <p>All optional, and all defaulted from what the tenant was already looking
 * at: the asking rent, today, and the day of the month they move in. A landlord
 * saying yes to what is on the screen should not have to retype it.
 *
 * @param dueDateDay overridden when a landlord wants every bed in a room
 *                   falling due on the same day regardless of move-in.
 */
@Schema(description = "Terms for the lease being created")
public record AcceptRequest(
        @DecimalMin(value = "0.0", inclusive = false)
        @Schema(example = "2500.00", description = "Defaults to the asking rent")
        BigDecimal rentAmount,

        @Min(1) @Max(31)
        @Schema(example = "5", description = "Defaults to the start date's day")
        Integer dueDateDay,

        @Schema(example = "2026-09-01", description = "Defaults to today")
        LocalDate startDate,

        @DecimalMin(value = "0.0")
        @Schema(example = "5000.00",
                description = "Held against damage, and mostly given back. Not rent. "
                        + "Null means none was recorded, which is not the same as none "
                        + "being taken.")
        BigDecimal depositAmount,

        @DecimalMin(value = "0.0")
        @Schema(example = "2500.00",
                description = "Rent paid before moving in, which pays for the first "
                        + "month. Kept apart from the deposit because it is money the "
                        + "landlord has earned rather than money they are holding.")
        BigDecimal advanceAmount) {
}
