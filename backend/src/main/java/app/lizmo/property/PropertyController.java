package app.lizmo.property;

import app.lizmo.common.ApiError;
import app.lizmo.property.dto.PropertyRequest;
import app.lizmo.property.dto.PropertyResponse;
import app.lizmo.property.dto.UnitRequest;
import app.lizmo.property.dto.UnitResponse;
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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Every operation declares an explicit {@code operationId} and an explicit
 * success response.
 *
 * <p>Both matter because the Dart client is generated from this document:
 * <ul>
 *   <li>Without an operationId, springdoc derives one from the Java method name
 *       and disambiguates collisions across controllers with a suffix — three
 *       controllers with a {@code get} produced {@code get_1}, and a client
 *       method called {@code get1}.
 *   <li>Declaring any {@code @ApiResponse} suppresses the auto-generated 200, so
 *       an endpoint documenting only its 404 appears to return nothing. That is
 *       how {@code GET /properties/&#123;id&#125;} generated a client method
 *       returning void.
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/properties")
@Tag(name = "Properties", description = "A landlord's properties and their units")
public class PropertyController {

    private final PropertyService service;
    private final CurrentUser currentUser;

    public PropertyController(PropertyService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "listProperties", summary = "List my properties",
            description = "Only properties owned by the signed-in landlord are ever returned.")
    @ApiResponse(responseCode = "200", description = "The caller's properties",
            content = @Content(array = @ArraySchema(schema = @Schema(implementation = PropertyResponse.class))))
    public List<PropertyResponse> list() {
        return service.listProperties(currentUser.requireId());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "createProperty", summary = "Create a property")
    @ApiResponse(responseCode = "201", description = "Created",
            content = @Content(schema = @Schema(implementation = PropertyResponse.class)))
    @ApiResponse(responseCode = "403", description = "Not a landlord, or the account is locked for an unpaid invoice",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PropertyResponse create(@Valid @RequestBody PropertyRequest request) {
        return service.createProperty(request, currentUser.requireId());
    }

    @GetMapping("/{id}")
    @Operation(operationId = "getProperty", summary = "View one property")
    @ApiResponse(responseCode = "200", description = "The property",
            content = @Content(schema = @Schema(implementation = PropertyResponse.class)))
    @ApiResponse(responseCode = "404", description = "No such property, or it belongs to another landlord",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PropertyResponse get(@PathVariable UUID id) {
        return service.getProperty(id, currentUser.requireId());
    }

    @PutMapping("/{id}")
    @Operation(operationId = "updateProperty", summary = "Update a property")
    @ApiResponse(responseCode = "200", description = "Updated",
            content = @Content(schema = @Schema(implementation = PropertyResponse.class)))
    public PropertyResponse update(@PathVariable UUID id, @Valid @RequestBody PropertyRequest request) {
        return service.updateProperty(id, request, currentUser.requireId());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "deleteProperty", summary = "Delete a property",
            description = "Refused while the property still has units, to protect their billing history.")
    @ApiResponse(responseCode = "204", description = "Deleted")
    public void delete(@PathVariable UUID id) {
        service.deleteProperty(id, currentUser.requireId());
    }

    @GetMapping("/{id}/units")
    @Operation(operationId = "listUnits", summary = "List a property's units")
    @ApiResponse(responseCode = "200", description = "Units in the property",
            content = @Content(array = @ArraySchema(schema = @Schema(implementation = UnitResponse.class))))
    public List<UnitResponse> listUnits(@PathVariable UUID id) {
        return service.listUnits(id, currentUser.requireId());
    }

    @PostMapping("/{id}/units")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "createUnit", summary = "Add a unit to a property",
            description = "Rental mode is fixed at creation and cannot be changed afterwards.")
    @ApiResponse(responseCode = "201", description = "Created",
            content = @Content(schema = @Schema(implementation = UnitResponse.class)))
    public UnitResponse createUnit(@PathVariable UUID id, @Valid @RequestBody UnitRequest request) {
        return service.createUnit(id, request, currentUser.requireId());
    }
}
