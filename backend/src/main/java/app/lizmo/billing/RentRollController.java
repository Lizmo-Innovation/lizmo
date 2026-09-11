package app.lizmo.billing;

import app.lizmo.billing.dto.RentRoll;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Rent for one month, room by room, across everything a landlord owns. */
@RestController
@RequestMapping("/api/v1/me/rent-roll")
@Tag(name = "Rent", description = "What is owed, and what has come in")
public class RentRollController {

    private final RentRollService rentRoll;
    private final CurrentUser currentUser;

    public RentRollController(RentRollService rentRoll, CurrentUser currentUser) {
        this.rentRoll = rentRoll;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "getRentRoll", summary = "Every tenancy's rent for one month",
            description = "A month's rent belongs to the month it falls due in, as on the "
                    + "dashboard. Tenancies that have since ended still appear for the months "
                    + "they owed. Asking brings live schedules up to date first.")
    @ApiResponse(responseCode = "200", description = "The month",
            content = @Content(schema = @Schema(implementation = RentRoll.class)))
    @ApiResponse(responseCode = "400", description = "Not a month")
    public RentRoll forMonth(
            @Parameter(description = "As 2026-09. This month when left out.",
                    example = "2026-09")
            @RequestParam(required = false) String month) {
        return rentRoll.forLandlord(currentUser.requireId(), month);
    }
}
