package app.lizmo.auth.verification;

import app.lizmo.auth.AuthService;
import app.lizmo.auth.dto.AuthResponse;
import app.lizmo.auth.dto.CompleteRegistrationRequest;
import app.lizmo.auth.dto.StartRegistrationRequest;
import app.lizmo.auth.dto.StartRegistrationResponse;
import app.lizmo.common.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * The first half of signing up: proving the address is yours.
 *
 * <p>No account exists at this point and none is created here. What this leaves
 * behind is a short-lived verification that expires on its own if somebody
 * changes their mind.
 */
@RestController
@RequestMapping("/api/v1/auth/register")
@Tag(name = "Signing up", description = "Creating an account")
public class EmailVerificationController {

    private final EmailVerificationService verifications;
    private final AuthService auth;

    public EmailVerificationController(
            EmailVerificationService verifications, AuthService auth) {
        this.verifications = verifications;
        this.auth = auth;
    }

    @PostMapping("/start")
    @Operation(operationId = "startRegistration", summary = "Send me a code",
            description = "Emails a six-digit code, good for ten minutes and one use. "
                    + "Asking again replaces any code already sent to that address.")
    @ApiResponse(responseCode = "200", description = "A code is on its way",
            content = @Content(schema = @Schema(implementation = StartRegistrationResponse.class)))
    @ApiResponse(responseCode = "409", description = "That address already has an account",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "429", description = "Too soon, or too many for today",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public StartRegistrationResponse start(
            @Valid @RequestBody StartRegistrationRequest request) {
        return new StartRegistrationResponse(verifications.start(request.email()));
    }

    @PostMapping("/complete")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "completeRegistration", summary = "Finish signing up",
            description = "Spends the code and creates the account. The password needs "
                    + "at least eight characters, with a capital, a small letter, a "
                    + "number and a symbol.")
    @ApiResponse(responseCode = "201", description = "Signed in, with the new account",
            content = @Content(schema = @Schema(implementation = AuthResponse.class)))
    @ApiResponse(responseCode = "400",
            description = "The code was wrong or expired, or the password is too weak",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public AuthResponse complete(
            @Valid @RequestBody CompleteRegistrationRequest request) {
        return auth.completeRegistration(request);
    }
}
