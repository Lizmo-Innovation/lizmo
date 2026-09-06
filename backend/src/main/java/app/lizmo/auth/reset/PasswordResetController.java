package app.lizmo.auth.reset;

import app.lizmo.auth.AuthService;
import app.lizmo.auth.dto.AuthResponse;
import app.lizmo.auth.reset.dto.CompletePasswordResetRequest;
import app.lizmo.auth.reset.dto.StartPasswordResetRequest;
import app.lizmo.auth.reset.dto.StartPasswordResetResponse;
import app.lizmo.common.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Getting back in after forgetting a password.
 *
 * <p>Both endpoints are public, which is what makes the enumeration rule and
 * the rate limits load-bearing rather than decorative.
 */
@RestController
@RequestMapping("/api/v1/auth/password-reset")
@Tag(name = "Auth", description = "Registration, login and token lifecycle")
public class PasswordResetController {

    private final PasswordResetService resets;
    private final AuthService auth;

    public PasswordResetController(PasswordResetService resets, AuthService auth) {
        this.resets = resets;
        this.auth = auth;
    }

    @PostMapping
    @Operation(operationId = "startPasswordReset", summary = "Send me a reset code",
            description = "Emails a six-digit code, good for fifteen minutes and one "
                    + "use. The response is the same whether or not the address has an "
                    + "account: saying otherwise would make this a way to ask Lizmo who "
                    + "its users are.")
    @ApiResponse(responseCode = "200", description = "If that address has an account, a code is on its way",
            content = @Content(schema = @Schema(implementation = StartPasswordResetResponse.class)))
    @ApiResponse(responseCode = "429", description = "Too soon, or too many for today",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public StartPasswordResetResponse start(
            @Valid @RequestBody StartPasswordResetRequest request) {
        return new StartPasswordResetResponse(resets.start(request.email()));
    }

    @PostMapping("/complete")
    @Operation(operationId = "completePasswordReset", summary = "Set a new password",
            description = "Spends the code, sets the password, and ends every session "
                    + "the account had -- including whoever's knowledge of the old "
                    + "password prompted the reset. Signs the caller back in.")
    @ApiResponse(responseCode = "200", description = "Signed in, with the new password",
            content = @Content(schema = @Schema(implementation = AuthResponse.class)))
    @ApiResponse(responseCode = "400",
            description = "The code was wrong or expired, or the password is too weak",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public AuthResponse complete(
            @Valid @RequestBody CompletePasswordResetRequest request) {
        return auth.startSession(
                resets.complete(request.email(), request.code(), request.password()));
    }
}
