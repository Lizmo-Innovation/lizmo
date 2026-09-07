package app.lizmo.billing;

import app.lizmo.billing.dto.CollectionsSummary;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Rent across everything a landlord owns. */
@RestController
@RequestMapping("/api/v1/me/collections")
@Tag(name = "Rent", description = "What is owed, and what has come in")
public class CollectionsController {

    private final CollectionsService collections;
    private final CurrentUser currentUser;

    public CollectionsController(
            CollectionsService collections, CurrentUser currentUser) {
        this.collections = collections;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "getCollections", summary = "How rent is going",
            description = "Due and collected this month, everything still outstanding, "
                    + "and who is behind -- worst first. Asking also brings the "
                    + "schedule up to date, so a tenancy nobody has opened this month "
                    + "is still counted.")
    @ApiResponse(responseCode = "200", description = "The summary",
            content = @Content(schema = @Schema(implementation = CollectionsSummary.class)))
    public CollectionsSummary mine() {
        return collections.forLandlord(currentUser.requireId());
    }
}
