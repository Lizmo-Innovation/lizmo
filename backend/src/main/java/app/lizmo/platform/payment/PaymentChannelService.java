package app.lizmo.platform.payment;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.DocumentType;
import app.lizmo.document.ImageNormaliser;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.platform.PlatformSettingsService;
import app.lizmo.platform.payment.dto.PaymentChannelDtos.PaymentChannelForLandlord;
import app.lizmo.platform.payment.dto.PaymentChannelDtos.PaymentChannelRequest;
import app.lizmo.platform.payment.dto.PaymentChannelDtos.PaymentChannelResponse;
import app.lizmo.platform.payment.dto.PaymentChannelDtos.PaymentDetails;
import app.lizmo.user.LandlordProfileRepository;
import java.io.IOException;
import java.time.Duration;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * The ways to pay Lizmo: kept by admins, read by landlords.
 *
 * <p>A landlord sees only the visible channels, in the order an admin set,
 * with the free-text note underneath. An admin sees everything, hidden
 * channels included, so one taken down for the month can be brought back.
 */
@Service
public class PaymentChannelService {

    private static final Duration URL_LIFETIME = Duration.ofMinutes(10);

    private static final long MAX_UPLOAD_BYTES = 10L * 1024 * 1024;

    private final PaymentChannelRepository channels;
    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;
    private final PlatformSettingsService settings;
    private final LandlordProfileRepository landlords;

    public PaymentChannelService(
            PaymentChannelRepository channels,
            StoredDocumentRepository documents,
            DocumentStore store,
            ImageNormaliser normaliser,
            PlatformSettingsService settings,
            LandlordProfileRepository landlords) {
        this.channels = channels;
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
        this.settings = settings;
        this.landlords = landlords;
    }

    // ---- landlords ------------------------------------------------------------

    /**
     * For a landlord, and nobody else.
     *
     * <p>Tenants never pay Lizmo, so there is nothing here for them. Not found
     * rather than forbidden, like anything else that is not somebody's.
     */
    @Transactional(readOnly = true)
    public PaymentDetails forLandlord(UUID userId) {
        if (!landlords.existsById(userId)) {
            throw new ApiException(ErrorCode.NOT_FOUND, "Nothing to see here.");
        }
        List<PaymentChannelForLandlord> shown = channels.findByVisibleTrueOrderBySortOrderAsc()
                .stream()
                .map(channel -> new PaymentChannelForLandlord(
                        channel.getId(),
                        channel.getChannel(),
                        channel.getAccountName(),
                        channel.getAccountNumber(),
                        qrUrl(channel),
                        URL_LIFETIME.toSeconds()))
                .toList();
        return new PaymentDetails(shown, settings.paymentInstructions());
    }

    // ---- admins ---------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<PaymentChannelResponse> forAdmin() {
        return channels.findAllByOrderBySortOrderAsc().stream().map(this::describe).toList();
    }

    /** Added at the bottom, and shown unless the admin says otherwise. */
    @Transactional
    public PaymentChannelResponse add(PaymentChannelRequest request, UUID admin) {
        PaymentChannel channel = new PaymentChannel(
                filled(request.channel(), "the channel"),
                filled(request.accountName(), "the account name"),
                filled(request.accountNumber(), "the account number"),
                channels.lastSortOrder() + 1,
                admin);
        if (Boolean.FALSE.equals(request.visible())) {
            channel.showToLandlords(false, admin);
        }
        return describe(channels.save(channel));
    }

    @Transactional
    public PaymentChannelResponse change(UUID id, PaymentChannelRequest request, UUID admin) {
        PaymentChannel channel = find(id);
        channel.describe(
                filled(request.channel(), "the channel"),
                filled(request.accountName(), "the account name"),
                filled(request.accountNumber(), "the account number"),
                admin);
        if (request.visible() != null) {
            channel.showToLandlords(request.visible(), admin);
        }
        return describe(channels.save(channel));
    }

    /** Gone, with its QR. Hiding is the way to keep one for later. */
    @Transactional
    public void remove(UUID id) {
        PaymentChannel channel = find(id);
        qrOf(channel).ifPresent(this::discard);
        channels.delete(channel);
    }

    /**
     * Sets or replaces the QR.
     *
     * <p>Replaced in place, so a channel has one QR and "which code do I scan"
     * has one answer. Re-encoded like every other image: a screenshot of a QR
     * carries whatever the phone that took it put in the EXIF.
     */
    @Transactional
    public PaymentChannelResponse attachQr(UUID id, MultipartFile file, UUID admin) {
        PaymentChannel channel = find(id);

        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "That image was empty.");
        }
        if (file.getSize() > MAX_UPLOAD_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file is larger than 10MB. Please upload a smaller image.");
        }
        byte[] original;
        try {
            original = file.getBytes();
        } catch (IOException e) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That upload did not arrive in one piece. Please try again.");
        }

        byte[] normalised = normaliser.normalise(original);
        String key = "payment-channels/%s/%s.jpg".formatted(channel.getId(), UUID.randomUUID());
        store.put(key, normalised, ImageNormaliser.OUTPUT_CONTENT_TYPE);

        Optional<StoredDocument> existing = qrOf(channel);
        if (existing.isPresent()) {
            StoredDocument qr = existing.get();
            String previous = qr.getStorageKey();
            qr.replaceWith(key, ImageNormaliser.OUTPUT_CONTENT_TYPE, normalised.length, admin);
            documents.save(qr);
            store.delete(previous);
        } else {
            documents.save(new StoredDocument(
                    DocumentOwnerType.PLATFORM_PAYMENT_CHANNEL,
                    channel.getId(),
                    admin,
                    DocumentType.OTHER,
                    key,
                    ImageNormaliser.OUTPUT_CONTENT_TYPE,
                    normalised.length));
        }

        channel.touchedBy(admin);
        return describe(channels.save(channel));
    }

    @Transactional
    public PaymentChannelResponse removeQr(UUID id, UUID admin) {
        PaymentChannel channel = find(id);
        qrOf(channel).ifPresent(this::discard);
        channel.touchedBy(admin);
        return describe(channels.save(channel));
    }

    /**
     * Puts the channels in the order given.
     *
     * <p>The whole list or nothing: a partial order would leave the ones left
     * out at positions that collide with the ones moved, and "which comes
     * first" would depend on the database's mood.
     */
    @Transactional
    public List<PaymentChannelResponse> reorder(List<UUID> ids, UUID admin) {
        List<PaymentChannel> all = channels.findAllByOrderBySortOrderAsc();
        boolean everyOnceExactly = ids.size() == all.size()
                && new HashSet<>(ids).size() == ids.size()
                && all.stream().allMatch(channel -> ids.contains(channel.getId()));
        if (!everyOnceExactly) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Send every channel exactly once, in the order to show them.");
        }
        for (PaymentChannel channel : all) {
            channel.moveTo(ids.indexOf(channel.getId()), admin);
        }
        channels.saveAll(all);
        return forAdmin();
    }

    // ---- shared -----------------------------------------------------------------

    private PaymentChannel find(UUID id) {
        return channels.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such payment channel."));
    }

    private PaymentChannelResponse describe(PaymentChannel channel) {
        return new PaymentChannelResponse(
                channel.getId(),
                channel.getChannel(),
                channel.getAccountName(),
                channel.getAccountNumber(),
                channel.isVisible(),
                channel.getSortOrder(),
                qrUrl(channel),
                URL_LIFETIME.toSeconds());
    }

    private Optional<StoredDocument> qrOf(PaymentChannel channel) {
        return documents
                .findByOwnerTypeAndOwnerId(DocumentOwnerType.PLATFORM_PAYMENT_CHANNEL, channel.getId())
                .stream()
                .findFirst();
    }

    private String qrUrl(PaymentChannel channel) {
        return qrOf(channel)
                .map(qr -> store.presignedUrl(qr.getStorageKey(), URL_LIFETIME))
                .orElse(null);
    }

    private void discard(StoredDocument qr) {
        documents.delete(qr);
        store.delete(qr.getStorageKey());
    }

    /** Trimmed, and refused when there is nothing left. */
    private static String filled(String value, String what) {
        String trimmed = value == null ? "" : value.trim();
        if (trimmed.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "Enter " + what + ".");
        }
        return trimmed;
    }
}
