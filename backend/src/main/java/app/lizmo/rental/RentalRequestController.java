package app.lizmo.rental;

import app.lizmo.common.ApiError;
import app.lizmo.rental.dto.RentalRequestCreate;
import app.lizmo.rental.dto.RentalRequestResponse;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * A tenant's own requests: what they have asked for, and where each one got to.
 *
 * <p>Addressed as "me" like the profile it depends on. A tenant only ever sees
 * their own; the landlord's side of the same conversation is a separate
 * endpoint, because the two see different things.
 */
@RestController
@RequestMapping("/api/v1/me/rental-requests")
@Tag(name = "Asking for a room", description = "Requests a tenant has sent")
public class RentalRequestController {

    private final RentalRequestService service;
    private final CurrentUser currentUser;

    public RentalRequestController(RentalRequestService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "listMyRentalRequests", summary = "What I have asked for")
    @ApiResponse(responseCode = "200", description = "Newest first",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = RentalRequestResponse.class))))
    public List<RentalRequestResponse> list() {
        return service.listMine(currentUser.requireId());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "sendRentalRequest", summary = "Ask for a bed or a unit",
            description = "Needs a complete tenant profile. Omit bedId to ask for the "
                    + "whole unit.")
    @ApiResponse(responseCode = "201", description = "The request, waiting on the landlord",
            content = @Content(schema = @Schema(implementation = RentalRequestResponse.class)))
    @ApiResponse(responseCode = "409",
            description = "Profile incomplete, slot taken, or already asked",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public RentalRequestResponse send(@Valid @RequestBody RentalRequestCreate command) {
        return service.create(currentUser.requireId(), command);
    }

    @PostMapping("/{id}/withdraw")
    @Operation(operationId = "withdrawRentalRequest", summary = "Change my mind",
            description = "Only while it is still waiting on the landlord.")
    @ApiResponse(responseCode = "200", description = "The withdrawn request",
            content = @Content(schema = @Schema(implementation = RentalRequestResponse.class)))
    public RentalRequestResponse withdraw(@PathVariable UUID id) {
        return service.withdraw(currentUser.requireId(), id);
    }
}
