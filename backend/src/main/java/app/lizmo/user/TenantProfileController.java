package app.lizmo.user;

import app.lizmo.common.ApiError;
import app.lizmo.security.CurrentUser;
import app.lizmo.user.dto.TenantProfileRequest;
import app.lizmo.user.dto.TenantProfileResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * A tenant's own profile.
 *
 * <p>Addressed as "me" rather than by id, because there is no id a caller could
 * pass that would be legitimate: this endpoint only ever serves the signed-in
 * tenant their own details.
 */
@RestController
@RequestMapping("/api/v1/me/tenant-profile")
@Tag(name = "Tenant profile", description = "A tenant's own details")
public class TenantProfileController {

    private final TenantProfileService service;
    private final CurrentUser currentUser;

    public TenantProfileController(TenantProfileService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "getMyTenantProfile", summary = "My tenant profile")
    @ApiResponse(responseCode = "200", description = "The profile",
            content = @Content(schema = @Schema(implementation = TenantProfileResponse.class)))
    @ApiResponse(responseCode = "404", description = "This account holds no tenant profile",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public TenantProfileResponse get() {
        return service.get(currentUser.requireId());
    }

    @PutMapping
    @Operation(operationId = "updateMyTenantProfile", summary = "Update my tenant profile",
            description = "Every field is optional; blank clears it.")
    @ApiResponse(responseCode = "200", description = "The saved profile",
            content = @Content(schema = @Schema(implementation = TenantProfileResponse.class)))
    public TenantProfileResponse update(@Valid @RequestBody TenantProfileRequest request) {
        return service.update(currentUser.requireId(), request);
    }
}
