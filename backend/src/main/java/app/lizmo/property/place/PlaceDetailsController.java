package app.lizmo.property.place;

import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/** House rules, money up front and what comes with a place, as its landlord sets them. */
@RestController
@Tag(name = "Properties")
public class PlaceDetailsController {

    private final PlaceDetailsService details;
    private final CurrentUser currentUser;

    public PlaceDetailsController(PlaceDetailsService details, CurrentUser currentUser) {
        this.details = details;
        this.currentUser = currentUser;
    }

    @GetMapping("/api/v1/properties/{id}/details")
    @Operation(operationId = "getPlaceDetails", summary = "A place's rules, money up front "
            + "and what comes with it")
    @ApiResponse(responseCode = "200", description = "Every field null where nothing is said",
            content = @Content(schema = @Schema(implementation = PlaceDetailsDto.class)))
    public PlaceDetailsDto get(@PathVariable UUID id) {
        return details.forLandlord(id, currentUser.requireId());
    }

    @PutMapping("/api/v1/properties/{id}/details")
    @Operation(operationId = "savePlaceDetails", summary = "Set a place's details",
            description = "Replaced whole: a field left out is cleared. Shown on the page "
                    + "anybody sees after scanning the property code.")
    @ApiResponse(responseCode = "200", description = "As saved",
            content = @Content(schema = @Schema(implementation = PlaceDetailsDto.class)))
    public PlaceDetailsDto save(
            @PathVariable UUID id, @Valid @RequestBody PlaceDetailsDto command) {
        return details.save(id, currentUser.requireId(), command);
    }
}
