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

    /**
      * What the app checks when it opens.
      *
      * <p>Public, and deliberately so: this is read on the splash screen,
      * before anybody has signed in, and an app too old to be allowed in is
      * also too old to be trusted with a session.
      */
    @GetMapping("/api/v1/platform/app-version")
    @Operation(operationId = "getAppVersion", summary = "The oldest app build allowed",
            description = "Public: the app asks before anybody signs in. A minimum of 0 "
                    + "means nobody is turned away.")
    @ApiResponse(responseCode = "200", description = "The minimum, and where to update")
    public AppVersion appVersion() {
        return new AppVersion(
                settings.minimumAndroidVersion(),
                settings.minimumIosVersion(),
                settings.androidUpdateUrl(),
                settings.iosUpdateUrl());
    }

    @GetMapping("/api/v1/admin/settings")
    @Operation(operationId = "getPlatformSettings", summary = "Settings the console owns")
    public PlatformSettings read() {
        return new PlatformSettings(
                settings.supportEmail(),
                settings.paymentInstructions(),
                settings.minimumAndroidVersion(),
                settings.minimumIosVersion(),
                settings.androidUpdateUrl(),
                settings.iosUpdateUrl());
    }

    @PutMapping("/api/v1/admin/settings")
    @Operation(operationId = "updatePlatformSettings", summary = "Change them",
            description = "The support address appears on a public page and is what a "
                    + "stranger is told to write to, so it is validated and who changed "
                    + "it is recorded.")
    public PlatformSettings update(@Valid @RequestBody PlatformSettings body) {
        String email = settings.changeSupportEmail(body.supportEmail(), currentUser.requireId());
        // Left alone when not sent, so a console that only saves the address
        // cannot wipe the payment details by omission.
        String instructions = body.paymentInstructions() == null
                ? settings.paymentInstructions()
                : settings.changePaymentInstructions(
                        body.paymentInstructions(), currentUser.requireId());
        String minimumAndroid = body.minimumAndroidVersion() == null
                ? settings.minimumAndroidVersion()
                : settings.changeMinimumAndroidVersion(
                        body.minimumAndroidVersion(), currentUser.requireId());
        String minimumIos = body.minimumIosVersion() == null
                ? settings.minimumIosVersion()
                : settings.changeMinimumIosVersion(
                        body.minimumIosVersion(), currentUser.requireId());
        String android = body.androidUpdateUrl() == null
                ? settings.androidUpdateUrl()
                : settings.changeAndroidUpdateUrl(
                        body.androidUpdateUrl(), currentUser.requireId());
        String ios = body.iosUpdateUrl() == null
                ? settings.iosUpdateUrl()
                : settings.changeIosUpdateUrl(body.iosUpdateUrl(), currentUser.requireId());
        return new PlatformSettings(
                email, instructions, minimumAndroid, minimumIos, android, ios);
    }

    @Schema(description = "Where to write to Lizmo")
    public record SupportContact(String email) {}

    /**
      * @param minimumAndroidVersion the oldest Android version allowed to carry
      *                              on. Null means Android is not checked,
      *                              which is what an operator who has never set
      *                              one has.
      * @param minimumIosVersion     the same for iOS. The two are separate
      *                              because releases drift apart: an iOS build
      *                              can sit in review for a week after the
      *                              Android one has shipped.
      */
    @Schema(description = "What the app checks when it opens")
    public record AppVersion(
            @Schema(example = "1.1.1") String minimumAndroidVersion,
            @Schema(example = "1.1.0") String minimumIosVersion,
            @Schema(example = "https://play.google.com/store/apps/details?id=app.lizmo")
            String androidUpdateUrl,
            String iosUpdateUrl) {}

    @Schema(description = "Settings the console owns")
    public record PlatformSettings(
            @NotBlank @Size(max = 255)
            @Schema(example = "lizmodev@gmail.com") String supportEmail,
            @Size(max = 1000)
            @Schema(example = "GCash 0917 123 4567 (Lizmo Innovation)")
            String paymentInstructions,
            @Size(max = 20) @Schema(example = "1.1.1",
                    description = "The oldest Android version allowed in. Raising it locks "
                            + "out everybody on an older one, so it is left alone when not "
                            + "sent; blank stops Android being checked.")
            String minimumAndroidVersion,
            @Size(max = 20) @Schema(example = "1.1.0",
                    description = "The same for iOS, separately: releases drift apart.")
            String minimumIosVersion,
            @Size(max = 500) String androidUpdateUrl,
            @Size(max = 500) String iosUpdateUrl) {}
}
