package app.lizmo.platform.payment;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.paymentchannel.ChannelQrCodes;
import app.lizmo.paymentchannel.ChannelRules;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelRequest;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelResponse;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelView;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentDetails;
import app.lizmo.platform.PlatformSettingsService;
import app.lizmo.user.LandlordProfileRepository;
import java.util.List;
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

    private static final DocumentOwnerType OWNER = DocumentOwnerType.PLATFORM_PAYMENT_CHANNEL;

    private final PaymentChannelRepository channels;
    private final ChannelQrCodes qr;
    private final PlatformSettingsService settings;
    private final LandlordProfileRepository landlords;

    public PaymentChannelService(
            PaymentChannelRepository channels,
            ChannelQrCodes qr,
            PlatformSettingsService settings,
            LandlordProfileRepository landlords) {
        this.channels = channels;
        this.qr = qr;
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
        List<PaymentChannelView> shown = channels.findByVisibleTrueOrderBySortOrderAsc()
                .stream()
                .map(channel -> new PaymentChannelView(
                        channel.getId(),
                        channel.getChannel(),
                        channel.getAccountName(),
                        channel.getAccountNumber(),
                        qr.url(OWNER, channel.getId()),
                        ChannelQrCodes.URL_LIFETIME.toSeconds()))
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
                ChannelRules.filled(request.channel(), "the channel"),
                ChannelRules.filled(request.accountName(), "the account name"),
                ChannelRules.filled(request.accountNumber(), "the account number"),
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
                ChannelRules.filled(request.channel(), "the channel"),
                ChannelRules.filled(request.accountName(), "the account name"),
                ChannelRules.filled(request.accountNumber(), "the account number"),
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
        qr.remove(OWNER, channel.getId());
        channels.delete(channel);
    }

    /** Sets or replaces the QR. */
    @Transactional
    public PaymentChannelResponse attachQr(UUID id, MultipartFile file, UUID admin) {
        PaymentChannel channel = find(id);
        qr.attach(OWNER, channel.getId(), file, admin);
        channel.touchedBy(admin);
        return describe(channels.save(channel));
    }

    @Transactional
    public PaymentChannelResponse removeQr(UUID id, UUID admin) {
        PaymentChannel channel = find(id);
        qr.remove(OWNER, channel.getId());
        channel.touchedBy(admin);
        return describe(channels.save(channel));
    }

    /** Puts the channels in the order given: every channel, exactly once. */
    @Transactional
    public List<PaymentChannelResponse> reorder(List<UUID> ids, UUID admin) {
        List<PaymentChannel> all = channels.findAllByOrderBySortOrderAsc();
        ChannelRules.requireWholeOrder(ids, all.stream().map(PaymentChannel::getId).toList());
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
                qr.url(OWNER, channel.getId()),
                ChannelQrCodes.URL_LIFETIME.toSeconds(),
                // Lizmo's own channels serve everybody; there are no
                // properties to apply them to.
                java.util.List.of());
    }
}
