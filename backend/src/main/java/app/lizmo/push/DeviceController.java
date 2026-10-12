package app.lizmo.push;

import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** The phones notifications are pushed to. */
@RestController
@RequestMapping("/api/v1/me/devices")
@Tag(name = "Devices", description = "Phones that receive push notifications")
public class DeviceController {

    private final DeviceService devices;
    private final CurrentUser currentUser;

    public DeviceController(DeviceService devices, CurrentUser currentUser) {
        this.devices = devices;
        this.currentUser = currentUser;
    }

    @Schema(description = "A phone to push notifications to")
    public record RegisterDevice(
            @NotBlank @Size(max = 4096) String token,
            @NotNull DevicePlatform platform) {
    }

    @PutMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "registerDevice", summary = "Push to this phone",
            description = "After signing in, and whenever the phone's token changes. The same "
                    + "token twice is one phone; a token another account held moves here.")
    public void register(@Valid @RequestBody RegisterDevice device) {
        devices.register(currentUser.requireId(), device.token(), device.platform());
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "forgetDevice", summary = "Stop pushing to this phone",
            description = "On signing out, so a shared phone stops being told the last "
                    + "person's business. Only ever the caller's own.")
    public void forget(@RequestParam String token) {
        devices.forget(currentUser.requireId(), token);
    }
}
