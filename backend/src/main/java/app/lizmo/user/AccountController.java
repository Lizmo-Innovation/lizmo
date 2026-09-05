package app.lizmo.user;

import app.lizmo.common.ApiError;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * The account itself, as opposed to the roles hanging off it.
 *
 * <p>Closing one is required by Google Play — an app that lets somebody sign
 * up must let them leave, from inside the app and from a web page — and the
 * shape of it is described on {@link AccountDeletionService}.
 */
@RestController
@RequestMapping("/api/v1/me")
@Tag(name = "My account", description = "The signed-in person's own account")
public class AccountController {

    private final AccountDeletionService deletion;
    private final CurrentUser currentUser;

    public AccountController(AccountDeletionService deletion, CurrentUser currentUser) {
        this.deletion = deletion;
        this.currentUser = currentUser;
    }

    @GetMapping("/deletable")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "checkAccountDeletable",
            summary = "Whether this account can be closed",
            description = "204 when it can. Asked before the confirmation screen, so "
                    + "somebody is told why not while they can still act on it rather "
                    + "than after they have typed DELETE.")
    @ApiResponse(responseCode = "204", description = "It can be closed")
    @ApiResponse(responseCode = "409", description = "A tenancy is still running",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public void deletable() {
        deletion.requireDeletable(currentUser.requireId());
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "deleteMyAccount", summary = "Close my account",
            description = "Ends every session, deletes the photographs of your ID, and "
                    + "removes your name, phone number and profile details. Leases and "
                    + "the history of what was paid stay, attached to an id that no "
                    + "longer names anybody, because they are your landlord's records "
                    + "as much as yours.")
    @ApiResponse(responseCode = "204", description = "Closed")
    @ApiResponse(responseCode = "409", description = "A tenancy is still running",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public void delete() {
        deletion.delete(currentUser.requireId());
    }
}
