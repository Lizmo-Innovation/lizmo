package app.lizmo.auth;

import app.lizmo.auth.dto.AuthResponse;
import app.lizmo.auth.dto.LoginRequest;
import app.lizmo.auth.dto.RefreshRequest;
import app.lizmo.common.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Auth", description = "Registration, login and token lifecycle")
public class AuthController {

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/login")
    @Operation(summary = "Sign in with email or phone plus password",
            description = "Failed attempts are rate limited per account and per client address.")
    @ApiResponse(responseCode = "200", description = "Tokens issued")
    @ApiResponse(responseCode = "401", description = "Credentials rejected",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "429", description = "Too many failed attempts; see Retry-After",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public AuthResponse login(@Valid @RequestBody LoginRequest request, HttpServletRequest http) {
        return auth.login(request, clientAddressOf(http));
    }

    /**
     * The caller's address, as best it can be known.
     *
     * <p>Behind Cloud Run every request arrives from a Google front end, so
     * {@code getRemoteAddr} is the same for everybody and would throttle all
     * users as one. X-Forwarded-For's <em>first</em> entry is the original
     * client; later entries are the proxies it passed through.
     *
     * <p>The header is client-supplied and therefore spoofable, which makes the
     * per-address bucket a speed bump rather than a guarantee. The per-account
     * limit is the one that cannot be evaded this way, and it is why both exist.
     */
    private static String clientAddressOf(HttpServletRequest http) {
        String forwarded = http.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            int comma = forwarded.indexOf(',');
            return (comma > 0 ? forwarded.substring(0, comma) : forwarded).trim();
        }
        return http.getRemoteAddr();
    }

    @PostMapping("/refresh")
    @Operation(summary = "Exchange a refresh token for a new pair",
            description = "The presented refresh token is revoked, so each one is usable exactly once.")
    @ApiResponse(responseCode = "200", description = "New tokens issued")
    @ApiResponse(responseCode = "401", description = "Refresh token unknown, expired or already used",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public AuthResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return auth.refresh(request.refreshToken());
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Revoke a refresh token",
            description = "Idempotent: unknown or already-revoked tokens still return 204.")
    public void logout(@Valid @RequestBody RefreshRequest request) {
        auth.logout(request.refreshToken());
    }
}
