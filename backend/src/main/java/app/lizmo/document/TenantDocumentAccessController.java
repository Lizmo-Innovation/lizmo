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
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * A landlord looking at the ID of somebody living in their room.
 *
 * <p>Addressed by lease, not by tenant. There is no endpoint that takes a
 * person and returns their documents: the only question this API answers is
 * about the holder of a particular live lease.
 */
@RestController
@RequestMapping("/api/v1/leases")
@Tag(name = "Leases", description = "Who is living where")
public class TenantDocumentAccessController {

    private final TenantDocumentAccess documents;
    private final CurrentUser currentUser;

    public TenantDocumentAccessController(
            TenantDocumentAccess documents, CurrentUser currentUser) {
        this.documents = documents;
        this.currentUser = currentUser;
    }

    @GetMapping("/{leaseId}/tenant-documents")
    @Operation(operationId = "listTenantDocumentsForLease",
            summary = "The ID of the tenant living here",
            description = "Only while the lease is active. Each carries a presigned URL "
                    + "valid for a few minutes.")
    @ApiResponse(responseCode = "200", description = "The photographs",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = TenantDocumentResponse.class))))
    @ApiResponse(responseCode = "404",
            description = "Not your lease, or the tenancy has ended",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public List<TenantDocumentResponse> forLease(@PathVariable UUID leaseId) {
        return documents.forLease(leaseId, currentUser.requireId());
    }
}
