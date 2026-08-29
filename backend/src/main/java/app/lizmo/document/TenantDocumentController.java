package app.lizmo.document;

import app.lizmo.common.ApiError;
import app.lizmo.document.dto.TenantDocumentResponse;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * A tenant's own photographs: a valid ID, and a 1x1 or selfie.
 *
 * <p>Addressed as "me" for the same reason the profile is. These are the most
 * personal things the app holds, and there is no id a caller could pass that
 * would be legitimate.
 */
@RestController
@RequestMapping("/api/v1/me/tenant-profile/documents")
@Tag(name = "Tenant documents", description = "A tenant's own photographs")
public class TenantDocumentController {

    private final TenantDocumentService service;
    private final CurrentUser currentUser;

    public TenantDocumentController(TenantDocumentService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "listMyTenantDocuments", summary = "My photographs",
            description = "Each carries a presigned URL valid for a few minutes. "
                    + "Do not cache it; ask again instead.")
    @ApiResponse(responseCode = "200", description = "What has been uploaded so far",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = TenantDocumentResponse.class))))
    public List<TenantDocumentResponse> list() {
        return service.listMine(currentUser.requireId());
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "uploadMyTenantDocument", summary = "Upload a photograph",
            description = "Re-encoded on arrival, so no EXIF or location data is kept. "
                    + "Uploading again replaces what is there.")
    @ApiResponse(responseCode = "201", description = "The stored photograph",
            content = @Content(schema = @Schema(implementation = TenantDocumentResponse.class)))
    @ApiResponse(responseCode = "400", description = "Not an image, too large, or a type "
            + "a tenant may not upload",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public TenantDocumentResponse upload(
            @RequestParam DocumentType docType,
            @RequestPart("file") MultipartFile file) {
        return service.upload(currentUser.requireId(), docType, file);
    }
}
