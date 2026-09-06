package app.lizmo.lease;

import app.lizmo.common.ApiError;
import app.lizmo.document.DocumentType;
import app.lizmo.lease.dto.LeaseDocumentResponse;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * The paperwork a landlord keeps against a tenancy.
 *
 * <p>Reachable after the tenancy ends, unlike everything else addressed by
 * lease. Disputes happen once somebody has moved out, and that is exactly when
 * the signed contract is wanted — see {@link LeasePaperworkAccess}.
 */
@RestController
@RequestMapping("/api/v1/leases/{leaseId}/documents")
@Tag(name = "Leases", description = "Who is living where")
public class LeaseDocumentController {

    private final LeaseDocumentService documents;
    private final CurrentUser currentUser;

    public LeaseDocumentController(
            LeaseDocumentService documents, CurrentUser currentUser) {
        this.documents = documents;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "listLeaseDocuments", summary = "Paperwork on this lease",
            description = "Newest first. Each carries a presigned URL valid for a few "
                    + "minutes; do not cache it, ask again instead.")
    @ApiResponse(responseCode = "200", description = "The documents",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = LeaseDocumentResponse.class))))
    @ApiResponse(responseCode = "404", description = "Not your lease",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<LeaseDocumentResponse> list(@PathVariable UUID leaseId) {
        return documents.forLandlord(leaseId, currentUser.requireId());
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "uploadLeaseDocument", summary = "Attach a document",
            description = "A photograph is re-encoded on arrival so no EXIF or location "
                    + "survives. A PDF is stored as it arrived — there is no equivalent "
                    + "scrub, and rewriting a signed document would change the artefact "
                    + "somebody may later have to rely on. 20MB each, 20 per lease.")
    @ApiResponse(responseCode = "201", description = "The stored document",
            content = @Content(schema = @Schema(implementation = LeaseDocumentResponse.class)))
    @ApiResponse(responseCode = "400", description = "Too large, too many, or the wrong kind",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public LeaseDocumentResponse upload(
            @PathVariable UUID leaseId,
            @RequestPart("file") MultipartFile file,
            @RequestParam(defaultValue = "LEASE_CONTRACT") DocumentType docType,
            @RequestParam(required = false) String label,
            // Defaults to shared: the commonest attachment is the contract, and
            // a lease one party cannot read is not much of an agreement.
            @RequestParam(defaultValue = "true") boolean sharedWithTenant) {
        return documents.upload(
                leaseId, currentUser.requireId(), docType, label, sharedWithTenant, file);
    }

    @PatchMapping("/{documentId}")
    @Operation(operationId = "updateLeaseDocument",
            summary = "Rename it, or change who can see it")
    @ApiResponse(responseCode = "200", description = "The document as it now stands",
            content = @Content(schema = @Schema(implementation = LeaseDocumentResponse.class)))
    @ApiResponse(responseCode = "404", description = "Not your lease, or no such document",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public LeaseDocumentResponse update(
            @PathVariable UUID leaseId,
            @PathVariable UUID documentId,
            @RequestParam(required = false) String label,
            @RequestParam(required = false) Boolean sharedWithTenant) {
        return documents.update(
                leaseId, documentId, currentUser.requireId(), label, sharedWithTenant);
    }

    @DeleteMapping("/{documentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "deleteLeaseDocument", summary = "Remove a document",
            description = "Gone for good, file and record together.")
    @ApiResponse(responseCode = "404", description = "Not your lease, or no such document",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public void delete(@PathVariable UUID leaseId, @PathVariable UUID documentId) {
        documents.delete(leaseId, documentId, currentUser.requireId());
    }
}
