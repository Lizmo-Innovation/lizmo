package app.lizmo.inquiry.dto;

import app.lizmo.inquiry.InquiryStatus;
import app.lizmo.user.IdType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * What a conversation looks like over the wire, to whichever side is asking.
 *
 * <p>Held together in one file because they are one thing read four ways, and
 * springdoc names nested records by their simple name — which is also why each
 * carries a schema name a client can live with.
 */
public final class InquiryDtos {

    private InquiryDtos() {
    }

    /**
     * A thread in a list.
     *
     * @param withName who the other side is: the person asking, read by the
     *                 landlord, or the landlord, read by them. A list of
     *                 property names tells a landlord nothing — three threads
     *                 on one building would be three identical rows.
     * @param lastMessage the opening of the latest message, or null when
     *                    nobody has said anything yet.
     * @param unread whether this side has something they have not seen.
     */
    @Schema(description = "A conversation, as it appears in a list")
    public record InquirySummary(
            UUID id,
            UUID propertyId,
            String propertyName,
            String withName,
            InquiryStatus status,
            String lastMessage,
            Instant lastMessageAt,
            boolean unread,
            Instant createdAt) {
    }

    /**
     * One message.
     *
     * @param mine whether the person reading it wrote it. Resolved here rather
     *             than handing out the sender's id, which the phone would only
     *             compare against its own.
     */
    @Schema(description = "Something somebody said")
    public record InquiryMessageResponse(
            UUID id,
            String body,
            Instant sentAt,
            boolean mine) {
    }

    /**
     * What the landlord is told about the person asking.
     *
     * <p>Carried only to them, and carrying what the request card used to: the
     * ID <em>type</em> and not its number, no photographs, no emergency
     * contact. Anyone can put a code on a gate; a thread should harvest no
     * more than the old form did.
     *
     * @param stillNeeds what is missing before a lease can exist, in words a
     *                   landlord can act on rather than "profile incomplete".
     */
    @Schema(description = "The person asking, as the landlord sees them")
    public record Applicant(
            UUID tenantId,
            String name,
            String phone,
            Integer age,
            String occupation,
            String permanentAddress,
            IdType idType,
            List<String> stillNeeds) {
    }

    /**
     * A thread with everything said in it.
     *
     * @param applicant null for the tenant reading their own thread: they know
     *                  who they are, and it is the landlord who is judging.
     */
    @Schema(description = "A conversation and its messages")
    public record InquiryThread(
            InquirySummary inquiry,
            List<InquiryMessageResponse> messages,
            Applicant applicant) {
    }

    /**
     * Starting one, or picking an old one back up.
     *
     * @param message optional. The button that starts a thread can carry the
     *                first thing the tenant wanted to say, so asking is one
     *                round trip rather than two.
     */
    @Schema(description = "Asking about a property")
    public record StartInquiry(
            @NotNull UUID propertyId,
            @Size(max = 2000) String message) {
    }

    @Schema(description = "Something to say")
    public record NewMessage(
            @NotBlank @Size(max = 2000)
            @Schema(example = "Is the bed on the second floor still free?")
            String body) {
    }
}
