package app.lizmo.rental;

import app.lizmo.common.ApiError;
import app.lizmo.rental.dto.RentalRequestForLandlord;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * The landlord side of the conversation: who has asked, and for what.
 *
 * <p>Separate endpoints from the tenant's, because the two see different
 * things. A tenant sees where their own request got to. A landlord sees a
 * stranger's details, and only as much of them as deciding requires.
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "Requests to answer", description = "What is waiting for a landlord")
public class RentalInboxController {

    private final RentalInboxService inbox;
    private final CurrentUser currentUser;

    public RentalInboxController(RentalInboxService inbox, CurrentUser currentUser) {
        this.inbox = inbox;
        this.currentUser = currentUser;
    }

    @GetMapping("/properties/{propertyId}/rental-requests")
    @Operation(operationId = "listRentalRequestsForProperty",
            summary = "Who has asked about this property",
            description = "Pending only by default, oldest first: a queue is answered "
                    + "in the order people joined it.")
    @ApiResponse(responseCode = "200", description = "The requests",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = RentalRequestForLandlord.class))))
    @ApiResponse(responseCode = "404", description = "Not your property",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<RentalRequestForLandlord> forProperty(
            @PathVariable UUID propertyId,
            @RequestParam(defaultValue = "true") boolean pendingOnly) {
        return inbox.forProperty(propertyId, currentUser.requireId(), pendingOnly);
    }

    @GetMapping("/rental-requests")
    @Operation(operationId = "listRentalRequestsToAnswer",
            summary = "Everybody waiting on this landlord, across every property",
            description = "Pending only, oldest first across every property the caller "
                    + "owns. Empty for an account that owns none.")
    @ApiResponse(responseCode = "200", description = "The requests",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = RentalRequestForLandlord.class))))
    public List<RentalRequestForLandlord> waitingOnMe() {
        return inbox.waitingOn(currentUser.requireId());
    }

    @GetMapping("/rental-requests/{id}")
    @Operation(operationId = "getRentalRequest", summary = "One request in full")
    @ApiResponse(responseCode = "200", description = "The request",
            content = @Content(schema = @Schema(implementation = RentalRequestForLandlord.class)))
    @ApiResponse(responseCode = "404", description = "Not yours, or no such request",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public RentalRequestForLandlord one(@PathVariable UUID id) {
        return inbox.one(id, currentUser.requireId());
    }
}
