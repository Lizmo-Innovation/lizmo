package app.lizmo.inquiry.dto;

import app.lizmo.inquiry.InquiryStatus;
import app.lizmo.user.IdType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
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
     * @param tenancy the tenancy these two have, or had, at this property:
     *                the current one if there is one, otherwise the latest.
     *                Null for somebody who only ever asked.
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
            Instant createdAt,
            Tenancy tenancy) {
    }

    /**
     * The tenancy a conversation belongs to.
     *
     * <p>Carried on the conversation so a screen can say "Renting Bed 1, 2B
     * since 1 Aug", or mark where in the thread the tenancy began and ended,
     * without a second request per row.
     *
     * @param place  how both sides name the room: "Bed 1, 2B" for a bedspace,
     *               "Unit 101" for a whole unit.
     * @param active false once it has ended. The conversation outlives it:
     *               the deposit is usually still being talked about.
     */
    @Schema(description = "The tenancy a conversation belongs to")
    public record Tenancy(
            UUID leaseId,
            String place,
            LocalDate startDate,
            LocalDate endDate,
            boolean active) {
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
            boolean mine,
            // Photos and PDFs sent with it, in the order sent. Empty for words
            // alone; the body is empty for a photo sent on its own.
            List<MessageAttachment> attachments) {
    }

    /** A photo or a PDF. */
    @Schema(description = "What kind of file")
    public enum AttachmentKind {
        PHOTO,
        PDF
    }

    /**
     * A file sent in a conversation.
     *
     * @param name       the PDF's name as it was on the phone; null for a photo.
     * @param url        the file, for an hour. Read again for a fresh one.
     * @param previewUrl a small copy of a photo, for the thread; null for a PDF.
     */
    @Schema(description = "A photo or PDF sent in a conversation")
    public record MessageAttachment(
            UUID id,
            AttachmentKind kind,
            String name,
            Long byteSize,
            String url,
            String previewUrl) {
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
            Applicant applicant,
            // What changed the tenancy, oldest first, to sit between what was
            // said. Empty for a stranger asking with no ID shared yet.
            List<ThreadEvent> events,
            // The month to settle next, while a tenancy is current. Null when
            // nothing is owed: the panel at the top then has nothing to say.
            app.lizmo.billing.TenancyRent.RentOwed rent) {
    }

    /** What changed the tenancy, as a card in its conversation. */
    @Schema(description = "What kind of thing happened")
    public enum ThreadEventKind {
        /** The photo of their ID: what makes them somebody to let to. */
        ID_SHARED,
        /** The tenant said they had paid. {@code state} says what came of it. */
        PAYMENT_REPORTED,
        /** Confirmed, or recorded by the landlord; carries the receipt number. */
        PAYMENT_CONFIRMED,
        /** The landlord said it did not arrive. */
        PAYMENT_REJECTED,
        /** A repair, with its status in {@code state}. */
        REPAIR_REPORTED,
        LEASE_STARTED,
        /** A fixed term within a month of its end; {@code label} is the date. */
        LEASE_ENDING,
        MOVED_OUT
    }

    /**
     * One thing that happened.
     *
     * @param entityId the payment, repair or lease it is about, for "View".
     * @param label    the month for money, the description for a repair, the
     *                 end date for a lease ending.
     * @param state    where it stands now: a payment's or a repair's status.
     */
    @Schema(description = "Something that changed the tenancy")
    public record ThreadEvent(
            ThreadEventKind kind,
            Instant at,
            UUID entityId,
            java.math.BigDecimal amount,
            String label,
            String receiptNumber,
            String state) {
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
