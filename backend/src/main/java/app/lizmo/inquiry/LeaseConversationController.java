package app.lizmo.inquiry;

import app.lizmo.inquiry.dto.InquiryDtos.InquirySummary;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * From a tenancy to talking about it.
 *
 * <p>Under {@code /leases} because that is where either side starts: the
 * tenant from where they live, the landlord from the tenant's page. The tag is
 * the conversations' own, word for word -- two tags with one name and two
 * descriptions make the generated spec invalid.
 */
@RestController
@RequestMapping("/api/v1/leases")
@Tag(name = "Asking about a place", description = "Conversations about a property")
public class LeaseConversationController {

    private final InquiryService service;
    private final CurrentUser currentUser;

    public LeaseConversationController(InquiryService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    @PostMapping("/{leaseId}/conversation")
    @Operation(operationId = "openLeaseConversation", summary = "The conversation for a tenancy",
            description = "For the tenant or the landlord. Returns the conversation these two "
                    + "already have about the property, starting one if a tenancy from before "
                    + "conversations has none. Works after the tenancy has ended.")
    @ApiResponse(responseCode = "200", description = "The conversation",
            content = @Content(schema = @Schema(implementation = InquirySummary.class)))
    public InquirySummary open(@PathVariable UUID leaseId) {
        return service.conversationFor(leaseId, currentUser.requireId());
    }
}
