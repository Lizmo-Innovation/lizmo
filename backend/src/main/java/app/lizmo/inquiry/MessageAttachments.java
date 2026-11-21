package app.lizmo.inquiry;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.DocumentType;
import app.lizmo.document.ImageNormaliser;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.inquiry.dto.InquiryDtos.AttachmentKind;
import app.lizmo.inquiry.dto.InquiryDtos.MessageAttachment;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.property.UnitRepository;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * Photos and PDFs sent in a conversation.
 *
 * <p>A tenant shows the leak; a landlord sends the house rules. Up to four
 * photos in a message, or one PDF. A photo is re-encoded like every other
 * upload, so no GPS or camera details leave the phone, and gets a small
 * preview so the thread loads quickly on mobile data. A PDF is checked to be
 * one by what is in it, not what it is called.
 *
 * <p>Only the two people in the conversation can open them, through links
 * that last an hour. They go when the tenancy's papers would -- a year after
 * it ends, or a year after a conversation that never became one was closed
 * -- and at once when whoever sent them closes their account.
 */
@Service
public class MessageAttachments {

    private static final Logger log = LoggerFactory.getLogger(MessageAttachments.class);

    static final int MAX_PHOTOS = 4;
    static final long MAX_BYTES = 10L * 1024 * 1024;
    static final Duration LINK_LASTS = Duration.ofHours(1);
    static final int PREVIEW_EDGE = 480;
    static final int RETENTION_DAYS = 365;

    private static final String PDF = "application/pdf";

    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;
    private final InquiryMessageRepository messages;
    private final InquiryRepository inquiries;
    private final LeaseRepository leases;
    private final UnitRepository units;

    public MessageAttachments(
            StoredDocumentRepository documents,
            DocumentStore store,
            ImageNormaliser normaliser,
            InquiryMessageRepository messages,
            InquiryRepository inquiries,
            LeaseRepository leases,
            UnitRepository units) {
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
        this.messages = messages;
        this.inquiries = inquiries;
        this.leases = leases;
        this.units = units;
    }

    // ---- sending ------------------------------------------------------------

    /** A file as it arrived, read once and checked. */
    record Upload(String name, byte[] bytes, boolean pdf) {
    }

    /**
     * Checks what was sent before anything is saved, so a refused file never
     * leaves a message behind without it.
     */
    List<Upload> read(List<MultipartFile> files) {
        List<MultipartFile> sent = files == null
                ? List.of()
                : files.stream().filter(Objects::nonNull).filter(file -> !file.isEmpty()).toList();
        List<Upload> read = new ArrayList<>();
        for (MultipartFile file : sent) {
            if (file.getSize() > MAX_BYTES) {
                throw new ApiException(ErrorCode.VALIDATION_FAILED,
                        "That file is larger than 10MB. Send a smaller one.");
            }
            byte[] bytes;
            try {
                bytes = file.getBytes();
            } catch (IOException e) {
                throw new ApiException(ErrorCode.VALIDATION_FAILED,
                        "That upload did not arrive in one piece. Please try again.");
            }
            read.add(new Upload(nameOf(file), bytes, isPdf(bytes)));
        }

        long pdfs = read.stream().filter(Upload::pdf).count();
        if (pdfs > 0 && read.size() > 1) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Send a PDF on its own, in a message of its own.");
        }
        if (read.size() > MAX_PHOTOS) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Up to " + MAX_PHOTOS + " photos in one message.");
        }
        return read;
    }

    /** Stores what {@link #read} accepted, against the message it came with. */
    void attach(UUID messageId, UUID senderId, List<Upload> uploads) {
        int order = 0;
        for (Upload upload : uploads) {
            if (upload.pdf()) {
                String key = "messages/%s/%s.pdf".formatted(messageId, UUID.randomUUID());
                store.put(key, upload.bytes(), PDF);
                StoredDocument file = new StoredDocument(DocumentOwnerType.INQUIRY_MESSAGE,
                        messageId, senderId, DocumentType.MESSAGE_FILE, key, PDF,
                        upload.bytes().length);
                file.relabel(upload.name());
                file.movedTo(order);
                documents.save(file);
            } else {
                // Refuses anything that is not a picture, in its own words.
                byte[] photo = normaliser.normalise(upload.bytes());
                byte[] preview = normaliser.normalise(upload.bytes(), PREVIEW_EDGE);
                String base = "messages/%s/%s".formatted(messageId, UUID.randomUUID());
                store.put(base + ".jpg", photo, ImageNormaliser.OUTPUT_CONTENT_TYPE);
                store.put(base + "-preview.jpg", preview, ImageNormaliser.OUTPUT_CONTENT_TYPE);
                StoredDocument full = new StoredDocument(DocumentOwnerType.INQUIRY_MESSAGE,
                        messageId, senderId, DocumentType.MESSAGE_PHOTO, base + ".jpg",
                        ImageNormaliser.OUTPUT_CONTENT_TYPE, photo.length);
                full.movedTo(order);
                documents.save(full);
                StoredDocument small = new StoredDocument(DocumentOwnerType.INQUIRY_MESSAGE,
                        messageId, senderId, DocumentType.MESSAGE_PREVIEW, base + "-preview.jpg",
                        ImageNormaliser.OUTPUT_CONTENT_TYPE, preview.length);
                small.movedTo(order);
                documents.save(small);
            }
            order++;
        }
    }

    // ---- reading ------------------------------------------------------------

    /** What each message carries, in the order it was sent. */
    @Transactional(readOnly = true)
    public Map<UUID, List<MessageAttachment>> of(Collection<UUID> messageIds) {
        Map<UUID, List<MessageAttachment>> found = new HashMap<>();
        if (messageIds.isEmpty()) {
            return found;
        }
        Map<UUID, List<StoredDocument>> byMessage = new HashMap<>();
        for (StoredDocument document : documents.findByOwnerTypeAndOwnerIdIn(
                DocumentOwnerType.INQUIRY_MESSAGE, messageIds)) {
            byMessage.computeIfAbsent(document.getOwnerId(), id -> new ArrayList<>()).add(document);
        }
        for (Map.Entry<UUID, List<StoredDocument>> entry : byMessage.entrySet()) {
            Map<Integer, String> previews = new HashMap<>();
            for (StoredDocument document : entry.getValue()) {
                if (document.getDocType() == DocumentType.MESSAGE_PREVIEW) {
                    previews.put(order(document), link(document));
                }
            }
            List<MessageAttachment> shown = new ArrayList<>();
            entry.getValue().stream()
                    .filter(document -> document.getDocType() != DocumentType.MESSAGE_PREVIEW)
                    .sorted(Comparator.comparingInt(MessageAttachments::order))
                    .forEach(document -> {
                        boolean photo = document.getDocType() == DocumentType.MESSAGE_PHOTO;
                        String url = link(document);
                        shown.add(new MessageAttachment(
                                document.getId(),
                                photo ? AttachmentKind.PHOTO : AttachmentKind.PDF,
                                photo ? null : document.getLabel(),
                                document.getByteSize(),
                                url,
                                photo ? previews.getOrDefault(order(document), url) : null));
                    });
            found.put(entry.getKey(), shown);
        }
        return found;
    }

    /**
     * What a list says about a message that is only attachments: "Photo",
     * "3 photos", or the PDF's name.
     */
    @Transactional(readOnly = true)
    public String describe(UUID messageId) {
        List<StoredDocument> sent = documents.findByOwnerTypeAndOwnerId(
                DocumentOwnerType.INQUIRY_MESSAGE, messageId);
        long photos = sent.stream().filter(d -> d.getDocType() == DocumentType.MESSAGE_PHOTO).count();
        if (photos > 0) {
            return photos == 1 ? "Photo" : photos + " photos";
        }
        return sent.stream()
                .filter(d -> d.getDocType() == DocumentType.MESSAGE_FILE)
                .map(d -> d.getLabel() == null ? "A PDF" : d.getLabel())
                .findFirst()
                .orElse(null);
    }

    // ---- removing -----------------------------------------------------------

    /** Everything this person sent, for closing their account. */
    @Transactional
    public void forget(UUID userId) {
        remove(documents.findByOwnerTypeAndUploadedBy(DocumentOwnerType.INQUIRY_MESSAGE, userId));
    }

    /**
     * Attachments whose conversation is past keeping.
     *
     * <p>With a tenancy at this place: when none is current and the last one
     * ended over a year ago. Without one: a year after the conversation was
     * closed. One that is still open is kept, however quiet.
     *
     * @return how many files were removed
     */
    @Transactional
    public int purgeAsOf(LocalDate today) {
        LocalDate cutoff = today.minusDays(RETENTION_DAYS);
        List<StoredDocument> all = documents.findByOwnerType(DocumentOwnerType.INQUIRY_MESSAGE);
        if (all.isEmpty()) {
            return 0;
        }
        Set<UUID> messageIds = new HashSet<>();
        for (StoredDocument document : all) {
            messageIds.add(document.getOwnerId());
        }
        Map<UUID, UUID> inquiryOf = new HashMap<>();
        for (InquiryMessage message : messages.findAllById(messageIds)) {
            inquiryOf.put(message.getId(), message.getInquiryId());
        }
        Map<UUID, Boolean> expired = new HashMap<>();
        for (Inquiry inquiry : inquiries.findAllById(new HashSet<>(inquiryOf.values()))) {
            expired.put(inquiry.getId(), isPast(inquiry, cutoff));
        }

        List<StoredDocument> going = new ArrayList<>();
        for (StoredDocument document : all) {
            UUID inquiry = inquiryOf.get(document.getOwnerId());
            // A message that no longer exists keeps nothing alive.
            if (inquiry == null || expired.getOrDefault(inquiry, false)) {
                going.add(document);
            }
        }
        remove(going);
        return going.size();
    }

    private boolean isPast(Inquiry inquiry, LocalDate cutoff) {
        List<Lease> here = new ArrayList<>();
        for (Lease lease : leases.findByTenantIdOrderByStartDateDesc(inquiry.getTenantId())) {
            units.findById(lease.getUnitId())
                    .filter(unit -> unit.getPropertyId().equals(inquiry.getPropertyId()))
                    .ifPresent(unit -> here.add(lease));
        }
        if (here.isEmpty()) {
            return inquiry.getStatus() == InquiryStatus.CLOSED
                    && inquiry.getClosedAt() != null
                    && inquiry.getClosedAt().atZone(ZoneId.systemDefault()).toLocalDate().isBefore(cutoff);
        }
        LocalDate latest = null;
        for (Lease lease : here) {
            if (lease.isActive() || lease.getEndDate() == null) {
                return false;
            }
            if (latest == null || lease.getEndDate().isAfter(latest)) {
                latest = lease.getEndDate();
            }
        }
        return latest.isBefore(cutoff);
    }

    /** The object first, then the row: never a row pointing at nothing kept. */
    private void remove(List<StoredDocument> going) {
        for (StoredDocument document : going) {
            try {
                store.delete(document.getStorageKey());
            } catch (RuntimeException e) {
                log.error("Could not delete {}", document.getStorageKey(), e);
            }
            documents.delete(document);
        }
    }

    // ---- small things -------------------------------------------------------

    private String link(StoredDocument document) {
        return store.presignedUrl(document.getStorageKey(), LINK_LASTS);
    }

    private static int order(StoredDocument document) {
        return document.getSortOrder() == null ? 0 : document.getSortOrder();
    }

    /** "%PDF-" in the first bytes is what makes a PDF, whatever it is called. */
    static boolean isPdf(byte[] bytes) {
        if (bytes.length < 5) {
            return false;
        }
        return new String(bytes, 0, 5, StandardCharsets.US_ASCII).equals("%PDF-");
    }

    /** The name it had on the phone, trimmed of any folder and kept short. */
    private static String nameOf(MultipartFile file) {
        String name = file.getOriginalFilename();
        if (name == null || name.isBlank()) {
            return null;
        }
        name = name.replace('\\', '/');
        name = name.substring(name.lastIndexOf('/') + 1).trim();
        return name.length() <= 120 ? name : name.substring(0, 120);
    }
}
