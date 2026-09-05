package app.lizmo.platform;

import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * The handful of settings the console owns, and the one page that reads them
 * without signing in.
 */
@RestController
@Tag(name = "Admin", description = "Lizmo's own staff")
public class PlatformSettingsController {

    private final PlatformSettingsService settings;
    private final CurrentUser currentUser;

    public PlatformSettingsController(
            PlatformSettingsService settings, CurrentUser currentUser) {
        this.settings = settings;
        this.currentUser = currentUser;
    }

    /**
     * Public, because the page that carries it is.
     *
     * <p>Google Play requires an account-deletion route reachable without
     * installing the app, and that page has to name an address somebody can
     * write to. Requiring a sign-in to read it would defeat the purpose.
     */
    @GetMapping("/api/v1/platform/support")
    @Operation(operationId = "getSupportContact", summary = "Where to write to Lizmo",
            description = "Public: the account deletion page shows it, and that page "
                    + "must work for somebody who has already uninstalled the app.")
    @ApiResponse(responseCode = "200", description = "The address")
    public SupportContact support() {
        return new SupportContact(settings.supportEmail());
    }

    @GetMapping("/api/v1/admin/settings")
    @Operation(operationId = "getPlatformSettings", summary = "Settings the console owns")
    public PlatformSettings read() {
        return new PlatformSettings(settings.supportEmail());
    }

    @PutMapping("/api/v1/admin/settings")
    @Operation(operationId = "updatePlatformSettings", summary = "Change them",
            description = "The support address appears on a public page and is what a "
                    + "stranger is told to write to, so it is validated and who changed "
                    + "it is recorded.")
    public PlatformSettings update(@Valid @RequestBody PlatformSettings body) {
        return new PlatformSettings(
                settings.changeSupportEmail(body.supportEmail(), currentUser.requireId()));
    }

    @Schema(description = "Where to write to Lizmo")
    public record SupportContact(String email) {}

    @Schema(description = "Settings the console owns")
    public record PlatformSettings(
            @NotBlank @Size(max = 255)
            @Schema(example = "lizmodev@gmail.com") String supportEmail) {}
}
