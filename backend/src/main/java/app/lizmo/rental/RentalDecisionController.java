package app.lizmo.rental;

import app.lizmo.common.ApiError;
import app.lizmo.lease.dto.AcceptRequest;
import app.lizmo.lease.dto.LeaseResponse;
import app.lizmo.rental.dto.RentalRequestForLandlord;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The landlord answering a request.
 *
 * <p>Accepting is the only thing in the API that creates a lease.
 */
@RestController
@RequestMapping("/api/v1/rental-requests")
@Tag(name = "Requests to answer", description = "What is waiting for a landlord")
public class RentalDecisionController {

    private final RentalDecisionService decisions;
    private final CurrentUser currentUser;

    public RentalDecisionController(
            RentalDecisionService decisions, CurrentUser currentUser) {
        this.decisions = decisions;
        this.currentUser = currentUser;
    }

    @PostMapping("/{id}/accept")
    @Operation(operationId = "acceptRentalRequest", summary = "Say yes, and create the lease",
            description = "Terms are optional and default to the asking rent, today, and "
                    + "the day of the month the tenant moves in. Everyone else still "
                    + "waiting on the same bed or unit is superseded.")
    @ApiResponse(responseCode = "200", description = "The new lease",
            content = @Content(schema = @Schema(implementation = LeaseResponse.class)))
    @ApiResponse(responseCode = "409", description = "The bed or unit has gone",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "404", description = "Not your property",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public LeaseResponse accept(
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) AcceptRequest terms) {
        return decisions.accept(id, currentUser.requireId(), terms);
    }

    @PostMapping("/{id}/decline")
    @Operation(operationId = "declineRentalRequest", summary = "Say no",
            description = "Frees nothing, because a request never held anything.")
    @ApiResponse(responseCode = "200", description = "The declined request",
            content = @Content(schema = @Schema(implementation = RentalRequestForLandlord.class)))
    public RentalRequestForLandlord decline(@PathVariable UUID id) {
        return decisions.decline(id, currentUser.requireId());
    }
}
