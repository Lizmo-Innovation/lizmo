package app.lizmo.inquiry;

import app.lizmo.common.ApiError;
import app.lizmo.inquiry.dto.InquiryDtos.InquiryMessageResponse;
import app.lizmo.inquiry.dto.InquiryDtos.InquirySummary;
import app.lizmo.inquiry.dto.InquiryDtos.InquiryThread;
import app.lizmo.inquiry.dto.InquiryDtos.NewMessage;
import app.lizmo.inquiry.dto.InquiryDtos.StartInquiry;
import app.lizmo.lease.dto.AcceptRequest;
import app.lizmo.lease.dto.LeaseResponse;
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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Talking about a place, before there is a tenancy.
 *
 * <p>One set of endpoints for both sides. Who is asking decides what comes
 * back — the landlord sees who is asking and what they still need for a lease,
 * the tenant sees the landlord's name — so the phone does not have to know
 * which kind of account it is holding before it can open an inbox.
 */
@RestController
@RequestMapping("/api/v1/inquiries")
@Tag(name = "Asking about a place", description = "Conversations about a property")
public class InquiryController {

    private final InquiryService service;
    private final InquiryLeaseService tenancies;
    private final CurrentUser currentUser;

    public InquiryController(
            InquiryService service,
            InquiryLeaseService tenancies,
            CurrentUser currentUser) {
        this.service = service;
        this.tenancies = tenancies;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(operationId = "listMyInquiries", summary = "My conversations",
            description = "Both sides: threads I started, and threads about places I let. "
                    + "Most recently spoken in first.")
    @ApiResponse(responseCode = "200", description = "The list",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = InquirySummary.class))))
    public List<InquirySummary> list() {
        return service.listMine(currentUser.requireId());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "startInquiry", summary = "Ask about a place",
            description = "Starts the conversation, or reopens the one that already "
                    + "exists with this landlord about this property. Needs a contact "
                    + "number, so they can ring back.")
    @ApiResponse(responseCode = "201", description = "The conversation",
            content = @Content(schema = @Schema(implementation = InquiryThread.class)))
    @ApiResponse(responseCode = "409", description = "No contact number yet",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public InquiryThread start(@Valid @RequestBody StartInquiry command) {
        return service.start(currentUser.requireId(), command);
    }

    @GetMapping("/{id}")
    @Operation(operationId = "readInquiry", summary = "One conversation",
            description = "Everything said in it. Reading it marks it seen for whoever "
                    + "asked.")
    @ApiResponse(responseCode = "200", description = "The conversation",
            content = @Content(schema = @Schema(implementation = InquiryThread.class)))
    @ApiResponse(responseCode = "404", description = "Not yours, or not there",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public InquiryThread read(@PathVariable UUID id) {
        return service.thread(id, currentUser.requireId());
    }

    @PostMapping("/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "sendInquiryMessage", summary = "Say something")
    @ApiResponse(responseCode = "201", description = "What was said",
            content = @Content(schema = @Schema(implementation = InquiryMessageResponse.class)))
    @ApiResponse(responseCode = "400", description = "Empty, too long, or closed",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public InquiryMessageResponse send(
            @PathVariable UUID id, @Valid @RequestBody NewMessage command) {
        return service.send(id, currentUser.requireId(), command);
    }

    @PostMapping("/{id}/read")
    @Operation(operationId = "markInquiryRead", summary = "Mark it seen",
            description = "For a list the reader has been through without opening "
                    + "every thread.")
    @ApiResponse(responseCode = "204", description = "Marked")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markRead(@PathVariable UUID id) {
        service.markRead(id, currentUser.requireId());
    }

    @PostMapping("/{id}/lease")
    @Operation(operationId = "startLeaseFromInquiry",
            summary = "Write the tenancy they agreed on",
            description = "The landlord, from inside the conversation. The room has to "
                    + "be named here: the tenant was never shown which rooms exist. "
                    + "Everything else defaults to the asking rent, today, and the day "
                    + "of the month they move in.")
    @ApiResponse(responseCode = "200", description = "The new tenancy",
            content = @Content(schema = @Schema(implementation = LeaseResponse.class)))
    @ApiResponse(responseCode = "409",
            description = "The room has gone, or the tenant is not ready",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    @ApiResponse(responseCode = "404", description = "Not your property",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public LeaseResponse startLease(
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) AcceptRequest terms) {
        return tenancies.start(id, currentUser.requireId(), terms);
    }

    @PostMapping("/{id}/close")
    @Operation(operationId = "closeInquiry", summary = "End it",
            description = "From either side. Asking about the place again reopens it.")
    @ApiResponse(responseCode = "200", description = "The closed conversation",
            content = @Content(schema = @Schema(implementation = InquirySummary.class)))
    public InquirySummary close(@PathVariable UUID id) {
        return service.close(id, currentUser.requireId());
    }
}
