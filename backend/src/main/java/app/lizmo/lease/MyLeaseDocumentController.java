package app.lizmo.lease;

import app.lizmo.common.ApiError;
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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The tenant's side of the same paperwork.
 *
 * <p>Read only, and only what the landlord marked as shared.
 *
 * <p>A separate controller rather than a flag on the landlord's: two audiences
 * with different rights reading the same rows is exactly the arrangement where
 * a shared endpoint eventually serves the wrong person the wrong list.
 */
@RestController
@RequestMapping("/api/v1/me/leases/{leaseId}/documents")
@Tag(name = "Leases", description = "Who is living where")
public class MyLeaseDocumentController {

    private final LeaseDocumentService documents;
    private final CurrentUser currentUser;

    public MyLeaseDocumentController(
            LeaseDocumentService documents, CurrentUser currentUser) {
        this.documents = documents;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "listMyLeaseDocuments",
            summary = "Paperwork my landlord has shared with me",
            description = "The signed contract, and anything else the landlord chose to "
                    + "share. Still readable after the tenancy ends: a copy of what you "
                    + "signed is worth having afterwards.")
    @ApiResponse(responseCode = "200", description = "The shared documents",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = LeaseDocumentResponse.class))))
    @ApiResponse(responseCode = "404", description = "Not your lease",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<LeaseDocumentResponse> list(@PathVariable UUID leaseId) {
        return documents.forTenant(leaseId, currentUser.requireId());
    }
}
