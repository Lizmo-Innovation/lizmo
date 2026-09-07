package app.lizmo.property;

import app.lizmo.property.dto.OccupancySummary;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** How much of a landlord's portfolio is let. */
@RestController
@RequestMapping("/api/v1/me/occupancy")
@Tag(name = "Properties", description = "A landlord's properties and their units")
public class OccupancyController {

    private final OccupancyService occupancy;
    private final CurrentUser currentUser;

    public OccupancyController(OccupancyService occupancy, CurrentUser currentUser) {
        this.occupancy = occupancy;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "getOccupancy", summary = "What is let and what is empty",
            description = "Counted in lettable slots rather than units: a four-bed room "
                    + "with one tenant is one let and three empty. Beds taken off the "
                    + "market are counted apart from vacancies, because a refurbishment "
                    + "is not a failure to let.")
    @ApiResponse(responseCode = "200", description = "The summary",
            content = @Content(schema = @Schema(implementation = OccupancySummary.class)))
    public OccupancySummary mine() {
        return occupancy.forLandlord(currentUser.requireId());
    }
}
