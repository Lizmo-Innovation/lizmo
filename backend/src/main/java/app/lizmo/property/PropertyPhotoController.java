package app.lizmo.property;

import app.lizmo.common.ApiError;
import app.lizmo.property.dto.PhotoOrder;
import app.lizmo.property.dto.PropertyPhoto;
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
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * What a place looks like.
 *
 * <p>The landlord's end of it. What a prospective tenant sees comes back with
 * the property itself, on the code lookup, because somebody standing at a gate
 * should get the photographs in the same breath as the address.
 */
@RestController
@RequestMapping("/api/v1/properties/{propertyId}/photos")
@Tag(name = "Properties", description = "Photographs of a place")
public class PropertyPhotoController {

    private final PropertyPhotoService service;
    private final CurrentUser currentUser;

    public PropertyPhotoController(PropertyPhotoService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "listPropertyPhotos", summary = "This property's photos",
            description = "In order. The first is the one that represents the place.")
    @ApiResponse(responseCode = "200", description = "The photos",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PropertyPhoto.class))))
    public List<PropertyPhoto> list(@PathVariable UUID propertyId) {
        return service.listFor(propertyId, currentUser.requireId());
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "addPropertyPhoto", summary = "Add a photo",
            description = "Up to 8 per property. Re-encoded on the way in, so what is "
                    + "stored carries no EXIF and no GPS.")
    @ApiResponse(responseCode = "201", description = "The photo",
            content = @Content(schema = @Schema(implementation = PropertyPhoto.class)))
    @ApiResponse(responseCode = "400", description = "Not an image, too large, or already 8",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PropertyPhoto add(
            @PathVariable UUID propertyId,
            @RequestPart("file") MultipartFile file) {
        return service.add(propertyId, currentUser.requireId(), file);
    }

    @PutMapping("/order")
    @Operation(operationId = "reorderPropertyPhotos", summary = "Put them in order",
            description = "Every id once. Whichever is first is the one a tenant sees "
                    + "against the place.")
    @ApiResponse(responseCode = "200", description = "The photos, reordered",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = PropertyPhoto.class))))
    public List<PropertyPhoto> reorder(
            @PathVariable UUID propertyId,
            @Valid @RequestBody PhotoOrder order) {
        return service.reorder(propertyId, currentUser.requireId(), order.ids());
    }

    @DeleteMapping("/{photoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "deletePropertyPhoto", summary = "Remove a photo")
    @ApiResponse(responseCode = "204", description = "Gone, and the rest close up")
    public void remove(@PathVariable UUID propertyId, @PathVariable UUID photoId) {
        service.remove(propertyId, photoId, currentUser.requireId());
    }
}
