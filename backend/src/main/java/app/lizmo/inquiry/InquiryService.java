package app.lizmo.inquiry;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.inquiry.dto.InquiryDtos.Applicant;
import app.lizmo.inquiry.dto.InquiryDtos.InquiryMessageResponse;
import app.lizmo.inquiry.dto.InquiryDtos.InquirySummary;
import app.lizmo.inquiry.dto.InquiryDtos.InquiryThread;
import app.lizmo.inquiry.dto.InquiryDtos.NewMessage;
import app.lizmo.inquiry.dto.InquiryDtos.StartInquiry;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.user.Age;
import app.lizmo.user.LeaseReadiness;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.TenantProfileRepository;
import app.lizmo.user.User;
import app.lizmo.user.UserRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Conversations between somebody asking about a place and its landlord.
 *
 * <p>This is what the first contact is now. It used to be a form: a button, a
 * card of facts, and two buttons back. Nobody could ask when a room would be
 * free, or whether a visit on Saturday suited, so every real exchange happened
 * on the phone and nothing about it was written down.
 *
 * <p>Who may see a thread is settled in one place, {@link #reachable}: the
 * tenant it belongs to, or whoever owns the property now.
 */
@Service
public class InquiryService {

    /** How much of a message a list row carries. */
    private static final int PREVIEW = 140;

    private final InquiryRepository inquiries;
    private final InquiryMessageRepository messages;
    private final PropertyRepository properties;
    private final UserRepository users;
    private final TenantProfileRepository profiles;
    private final LeaseReadiness readiness;
    private final NotificationService notifications;
    private final Clock clock;

    public InquiryService(
            InquiryRepository inquiries,
            InquiryMessageRepository messages,
            PropertyRepository properties,
            UserRepository users,
            TenantProfileRepository profiles,
            LeaseReadiness readiness,
            NotificationService notifications,
            Clock clock) {
        this.inquiries = inquiries;
        this.messages = messages;
        this.properties = properties;
        this.users = users;
        this.profiles = profiles;
        this.readiness = readiness;
        this.notifications = notifications;
        this.clock = clock;
    }

    /**
     * Starts a conversation about a property, or picks up the one that exists.
     *
     * <p>A phone number is still the price of asking: the landlord's first
     * instinct is to ring, and a thread they cannot answer any other way is
     * worse than no thread. Nothing else is wanted yet — the ID and the rest
     * belong to signing a lease, not to asking a question.
     */
    @Transactional
    public InquiryThread start(UUID tenantId, StartInquiry command) {
        Property property = properties.findById(command.propertyId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such property."));

        // Before the profile gate: a landlord who scans their own gate code
        // should be told what the matter is, not sent to finish a tenant
        // profile they are never going to have.
        if (property.isOwnedBy(tenantId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This is your own property.");
        }

        readiness.requireEnoughToAsk(tenantId);

        Inquiry inquiry = inquiries
                .findByTenantIdAndPropertyId(tenantId, command.propertyId())
                .orElseGet(() -> inquiries.save(
                        new Inquiry(command.propertyId(), tenantId)));

        // A thread that ended months ago is picked back up rather than
        // duplicated: it is the same two people, and what was said last time
        // is worth having in front of them.
        if (inquiry.getStatus() == InquiryStatus.CLOSED) {
            inquiry.reopen();
            inquiries.save(inquiry);
        }

        if (command.message() != null && !command.message().isBlank()) {
            say(inquiry, tenantId, command.message(), property);
        }

        return thread(inquiry.getId(), tenantId);
    }

    /**
     * Every thread this person is a part of, whichever side they are on.
     *
     * <p>One endpoint for both: a landlord's inbox and a tenant's are the same
     * question asked from opposite ends, and splitting them would mean the
     * phone deciding which to call before it knows what the account is.
     */
    @Transactional(readOnly = true)
    public List<InquirySummary> listMine(UUID userId) {
        Map<UUID, String> owned = new HashMap<>();
        for (Property property : properties.findByLandlordIdOrderByNameAsc(userId)) {
            owned.put(property.getId(), property.getName());
        }

        List<Inquiry> found = new ArrayList<>(
                inquiries.findByTenantIdOrderByLastMessageAtDescCreatedAtDesc(userId));
        if (!owned.isEmpty()) {
            found.addAll(inquiries
                    .findByPropertyIdInOrderByLastMessageAtDescCreatedAtDesc(owned.keySet()));
        }
        if (found.isEmpty()) {
            return List.of();
        }

        Map<UUID, InquiryMessage> latest = latestMessages(found);

        List<InquirySummary> described = new ArrayList<>();
        for (Inquiry inquiry : found) {
            described.add(summarise(inquiry, userId, latest.get(inquiry.getId())));
        }
        // Most recently spoken in first, with threads nobody has written in
        // ordered by when they were started.
        described.sort((a, b) -> when(b).compareTo(when(a)));
        return described;
    }

    /** One thread, with everything said in it. Marks it read for whoever asked. */
    @Transactional
    public InquiryThread thread(UUID inquiryId, UUID userId) {
        Inquiry inquiry = reachable(inquiryId, userId);
        boolean asTenant = inquiry.getTenantId().equals(userId);

        List<InquiryMessageResponse> said = new ArrayList<>();
        InquiryMessage last = null;
        for (InquiryMessage message : messages.findByInquiryIdOrderBySentAtAsc(inquiryId)) {
            said.add(new InquiryMessageResponse(
                    message.getId(),
                    message.getBody(),
                    message.getSentAt(),
                    message.getSenderId().equals(userId)));
            last = message;
        }

        markRead(inquiry, asTenant);

        return new InquiryThread(
                summarise(inquiry, userId, last),
                said,
                asTenant ? null : applicant(inquiry.getTenantId()));
    }

    /** Says something, and tells the other side it was said. */
    @Transactional
    public InquiryMessageResponse send(UUID inquiryId, UUID userId, NewMessage command) {
        Inquiry inquiry = reachable(inquiryId, userId);

        if (inquiry.getStatus() == InquiryStatus.CLOSED) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This conversation is closed. Ask about the place again to reopen it.");
        }

        String body = command.body() == null ? "" : command.body().trim();
        if (body.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "Write something first.");
        }

        Property property = properties.findById(inquiry.getPropertyId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such property."));

        InquiryMessage saved = say(inquiry, userId, body, property);
        return new InquiryMessageResponse(
                saved.getId(), saved.getBody(), saved.getSentAt(), true);
    }

    /** Ends it, from either side. */
    @Transactional
    public InquirySummary close(UUID inquiryId, UUID userId) {
        Inquiry inquiry = reachable(inquiryId, userId);

        if (inquiry.getStatus() == InquiryStatus.LEASED) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "There is a tenancy from this conversation. End that instead.");
        }
        if (inquiry.getStatus() == InquiryStatus.OPEN) {
            inquiry.close(clock.instant());
            inquiries.save(inquiry);
        }

        return summarise(inquiry, userId, latestMessage(inquiry.getId()));
    }

    /** Marks a thread seen without reading it, for a list that was scrolled past. */
    @Transactional
    public void markRead(UUID inquiryId, UUID userId) {
        Inquiry inquiry = reachable(inquiryId, userId);
        markRead(inquiry, inquiry.getTenantId().equals(userId));
    }

    // ---- the parts -----------------------------------------------------------------

    /**
     * The thread, if this person is in it.
     *
     * <p>The tenant it belongs to, or whoever owns the property <em>now</em> —
     * read each time rather than stored, so a building that changes hands
     * takes its conversations with it.
     */
    private Inquiry reachable(UUID inquiryId, UUID userId) {
        Inquiry inquiry = inquiries.findById(inquiryId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.NOT_FOUND, "No such conversation."));

        if (inquiry.getTenantId().equals(userId)) {
            return inquiry;
        }

        boolean theirs = properties.findById(inquiry.getPropertyId())
                .map(property -> property.isOwnedBy(userId))
                .orElse(false);
        if (theirs) {
            return inquiry;
        }

        // Not found rather than forbidden: whether a conversation exists
        // between two other people is itself none of the asker's business.
        throw new ApiException(ErrorCode.NOT_FOUND, "No such conversation.");
    }

    private InquiryMessage say(Inquiry inquiry, UUID senderId, String body, Property property) {
        Instant now = clock.instant();

        InquiryMessage saved = messages.save(new InquiryMessage(
                inquiry.getId(), senderId, body.trim(), now));

        inquiry.spoke(inquiry.getTenantId().equals(senderId), now);
        inquiries.save(inquiry);

        tell(inquiry, senderId, property);
        return saved;
    }

    /**
     * Tells whoever did not write it.
     *
     * <p>No names and no quoting the message: a notification is read on a lock
     * screen, and what somebody said about where they want to live is not for
     * whoever is holding the phone.
     */
    private void tell(Inquiry inquiry, UUID senderId, Property property) {
        boolean fromTenant = inquiry.getTenantId().equals(senderId);
        UUID recipient = fromTenant ? property.getLandlordId() : inquiry.getTenantId();

        notifications.raise(
                recipient,
                NotificationType.INQUIRY_MESSAGE,
                fromTenant ? "Somebody is asking about your place" : "A landlord replied",
                fromTenant
                        ? "There is a new message about %s.".formatted(property.getName())
                        : "There is a new message about %s.".formatted(property.getName()),
                NotificationEntityType.INQUIRY,
                inquiry.getId());
    }

    private void markRead(Inquiry inquiry, boolean asTenant) {
        inquiry.read(asTenant);
        inquiries.save(inquiry);
    }

    private InquirySummary summarise(Inquiry inquiry, UUID userId, InquiryMessage last) {
        boolean asTenant = inquiry.getTenantId().equals(userId);

        Property property = properties.findById(inquiry.getPropertyId()).orElse(null);
        String propertyName = property == null ? null : property.getName();

        UUID otherSide = asTenant
                ? (property == null ? null : property.getLandlordId())
                : inquiry.getTenantId();

        return new InquirySummary(
                inquiry.getId(),
                inquiry.getPropertyId(),
                propertyName,
                nameOf(otherSide),
                inquiry.getStatus(),
                last == null ? null : preview(last.getBody()),
                inquiry.getLastMessageAt(),
                inquiry.unreadFor(asTenant),
                inquiry.getCreatedAt());
    }

    private static String preview(String body) {
        String flat = body.replaceAll("\\s+", " ").trim();
        return flat.length() <= PREVIEW ? flat : flat.substring(0, PREVIEW) + "…";
    }

    private String nameOf(UUID userId) {
        return userId == null
                ? null
                : users.findById(userId).map(User::getName).orElse(null);
    }

    /** What the request card used to carry, and no more. */
    private Applicant applicant(UUID tenantId) {
        User tenant = users.findById(tenantId).orElse(null);
        TenantProfile profile = profiles.findById(tenantId).orElse(null);
        LocalDate today = LocalDate.now(clock.withZone(ZoneId.systemDefault()));

        return new Applicant(
                tenantId,
                tenant == null ? null : tenant.getName(),
                phoneOf(tenant, profile),
                Age.on(profile == null ? null : profile.getBirthdate(), today),
                profile == null ? null : profile.getOccupation(),
                profile == null ? null : profile.getPermanentAddress(),
                profile == null ? null : profile.getIdType(),
                readiness.whatIsMissing(tenantId));
    }

    private static String phoneOf(User tenant, TenantProfile profile) {
        if (profile != null && profile.getContactPhone() != null
                && !profile.getContactPhone().isBlank()) {
            return profile.getContactPhone();
        }
        return tenant == null ? null : tenant.getPhone();
    }

    private Map<UUID, InquiryMessage> latestMessages(List<Inquiry> found) {
        List<UUID> ids = found.stream().map(Inquiry::getId).toList();
        Map<UUID, InquiryMessage> latest = new HashMap<>();
        // Ascending, so the last one written for each thread wins.
        for (InquiryMessage message : messages.findByInquiryIdInOrderBySentAtAsc(ids)) {
            latest.put(message.getInquiryId(), message);
        }
        return latest;
    }

    private InquiryMessage latestMessage(UUID inquiryId) {
        List<InquiryMessage> said = messages.findByInquiryIdOrderBySentAtAsc(inquiryId);
        return said.isEmpty() ? null : said.get(said.size() - 1);
    }

    private static Instant when(InquirySummary summary) {
        return Optional.ofNullable(summary.lastMessageAt()).orElse(summary.createdAt());
    }
}
