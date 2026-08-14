package app.lizmo.property;

import app.lizmo.property.dto.BedRequest;
import app.lizmo.property.dto.BedResponse;
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
 * Units and beds addressed directly by id.
 *
 * <p>Separate from the property-scoped routes because a client that already
 * holds a unit id should not have to know its property to act on it. Ownership
 * is still resolved through the property on every call.
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "Units", description = "Units and the beds within them")
public class UnitController {

    private final PropertyService service;
    private final CurrentUser currentUser;

    public UnitController(PropertyService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    @GetMapping("/units/{id}")
    @Operation(operationId = "getUnit", summary = "View one unit")
    @ApiResponse(responseCode = "200", description = "The unit",
            content = @Content(schema = @Schema(implementation = UnitResponse.class)))
    public UnitResponse get(@PathVariable UUID id) {
        return service.getUnit(id, currentUser.requireId());
    }

    @PutMapping("/units/{id}")
    @Operation(operationId = "updateUnit", summary = "Update a unit",
            description = "Rental mode cannot change, and capacity cannot drop below the beds already defined.")
    @ApiResponse(responseCode = "200", description = "Updated",
            content = @Content(schema = @Schema(implementation = UnitResponse.class)))
    public UnitResponse update(@PathVariable UUID id, @Valid @RequestBody UnitRequest request) {
        return service.updateUnit(id, request, currentUser.requireId());
    }

    @DeleteMapping("/units/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "deleteUnit", summary = "Delete a unit",
            description = "Refused while the unit still has beds.")
    @ApiResponse(responseCode = "204", description = "Deleted")
    public void delete(@PathVariable UUID id) {
        service.deleteUnit(id, currentUser.requireId());
    }

    @GetMapping("/units/{id}/beds")
    @Operation(operationId = "listBeds", summary = "List a unit's beds")
    @ApiResponse(responseCode = "200", description = "Beds in the unit",
            content = @Content(array = @ArraySchema(schema = @Schema(implementation = BedResponse.class))))
    public List<BedResponse> listBeds(@PathVariable UUID id) {
        return service.listBeds(id, currentUser.requireId());
    }

    @PostMapping("/units/{id}/beds")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "createBed", summary = "Add a bed",
            description = "Bedspace units only, and never beyond the unit's capacity.")
    @ApiResponse(responseCode = "201", description = "Created",
            content = @Content(schema = @Schema(implementation = BedResponse.class)))
    public BedResponse createBed(@PathVariable UUID id, @Valid @RequestBody BedRequest request) {
        return service.createBed(id, request, currentUser.requireId());
    }

    @DeleteMapping("/beds/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "deleteBed", summary = "Remove a bed",
            description = "Refused while the bed is occupied.")
    @ApiResponse(responseCode = "204", description = "Deleted")
    public void deleteBed(@PathVariable UUID id) {
        service.deleteBed(id, currentUser.requireId());
    }
}
