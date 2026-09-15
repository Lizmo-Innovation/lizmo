package app.lizmo.billing.channel;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeasePaperworkAccess;
import app.lizmo.paymentchannel.ChannelQrCodes;
import app.lizmo.paymentchannel.ChannelRules;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelRequest;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelResponse;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentChannelView;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentDetails;
import app.lizmo.paymentchannel.dto.PaymentChannelDtos.PaymentNote;
import app.lizmo.user.LandlordProfile;
import app.lizmo.user.LandlordProfileRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * How a landlord is paid rent: kept by the landlord, read by their tenants.
 *
 * <p>One list per landlord, covering every property they own. A tenant sees
 * the visible channels of whoever owns the property their lease is on --
 * after moving out too, since some people leave owing a month.
 *
 * <p>Nothing here checks whether a property is locked for an unpaid Lizmo
 * statement, on purpose. A lock stops a landlord growing; it must never stop
 * a tenant finding out how to pay.
 */
@Service
public class LandlordPaymentChannelService {

    private static final DocumentOwnerType OWNER = DocumentOwnerType.LANDLORD_PAYMENT_CHANNEL;

    private final LandlordPaymentChannelRepository channels;
    private final LandlordProfileRepository landlords;
    private final LeasePaperworkAccess leases;
    private final ChannelQrCodes qr;

    public LandlordPaymentChannelService(
            LandlordPaymentChannelRepository channels,
            LandlordProfileRepository landlords,
            LeasePaperworkAccess leases,
            ChannelQrCodes qr) {
        this.channels = channels;
        this.landlords = landlords;
        this.leases = leases;
        this.qr = qr;
    }

    // ---- the landlord's own list ---------------------------------------------------

    @Transactional(readOnly = true)
    public List<PaymentChannelResponse> mine(UUID landlordId) {
        requireLandlord(landlordId);
        return channels.findByLandlordIdOrderBySortOrderAsc(landlordId).stream()
                .map(this::describe)
                .toList();
    }

    /** Added at the bottom, and shown unless the landlord says otherwise. */
    @Transactional
    public PaymentChannelResponse add(UUID landlordId, PaymentChannelRequest request) {
        requireLandlord(landlordId);
        LandlordPaymentChannel channel = new LandlordPaymentChannel(
                landlordId,
                ChannelRules.filled(request.channel(), "the channel"),
                ChannelRules.filled(request.accountName(), "the account name"),
                ChannelRules.filled(request.accountNumber(), "the account number"),
                channels.lastSortOrder(landlordId) + 1);
        if (Boolean.FALSE.equals(request.visible())) {
            channel.showToTenants(false);
        }
        return describe(channels.save(channel));
    }

    @Transactional
    public PaymentChannelResponse change(UUID landlordId, UUID id, PaymentChannelRequest request) {
        LandlordPaymentChannel channel = find(landlordId, id);
        channel.describe(
                ChannelRules.filled(request.channel(), "the channel"),
                ChannelRules.filled(request.accountName(), "the account name"),
                ChannelRules.filled(request.accountNumber(), "the account number"));
        if (request.visible() != null) {
            channel.showToTenants(request.visible());
        }
        return describe(channels.save(channel));
    }

    /**
     * Gone, with its QR. Past payments that named it keep what they said,
     * because they hold the words rather than a link.
     */
    @Transactional
    public void remove(UUID landlordId, UUID id) {
        LandlordPaymentChannel channel = find(landlordId, id);
        qr.remove(OWNER, channel.getId());
        channels.delete(channel);
    }

    @Transactional
    public PaymentChannelResponse attachQr(UUID landlordId, UUID id, MultipartFile file) {
        LandlordPaymentChannel channel = find(landlordId, id);
        qr.attach(OWNER, channel.getId(), file, landlordId);
        channel.touch();
        return describe(channels.save(channel));
    }

    @Transactional
    public PaymentChannelResponse removeQr(UUID landlordId, UUID id) {
        LandlordPaymentChannel channel = find(landlordId, id);
        qr.remove(OWNER, channel.getId());
        channel.touch();
        return describe(channels.save(channel));
    }

    @Transactional
    public List<PaymentChannelResponse> reorder(UUID landlordId, List<UUID> ids) {
        requireLandlord(landlordId);
        List<LandlordPaymentChannel> all = channels.findByLandlordIdOrderBySortOrderAsc(landlordId);
        ChannelRules.requireWholeOrder(ids, all.stream().map(LandlordPaymentChannel::getId).toList());
        for (LandlordPaymentChannel channel : all) {
            channel.moveTo(ids.indexOf(channel.getId()));
        }
        channels.saveAll(all);
        return mine(landlordId);
    }

    @Transactional(readOnly = true)
    public PaymentNote note(UUID landlordId) {
        return new PaymentNote(requireLandlord(landlordId).getPaymentNote());
    }

    /** Blank clears it. */
    @Transactional
    public PaymentNote changeNote(UUID landlordId, String note) {
        LandlordProfile landlord = requireLandlord(landlordId);
        String text = note == null ? "" : note.trim();
        if (text.length() > 500) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Keep the note under 500 characters.");
        }
        landlord.notePayments(text.isEmpty() ? null : text);
        landlords.save(landlord);
        return new PaymentNote(landlord.getPaymentNote());
    }

    // ---- a tenant paying ----------------------------------------------------------------

    /**
     * How to pay the landlord behind this lease: their visible channels, in
     * order, and their note.
     */
    @Transactional(readOnly = true)
    public PaymentDetails forTenant(UUID leaseId, UUID tenantId) {
        Lease lease = leases.requireTenant(leaseId, tenantId);
        UUID landlordId = leases.landlordOf(lease);

        List<PaymentChannelView> shown = landlordId == null ? List.of()
                : channels.findByLandlordIdAndVisibleTrueOrderBySortOrderAsc(landlordId).stream()
                        .map(channel -> new PaymentChannelView(
                                channel.getId(),
                                channel.getChannel(),
                                channel.getAccountName(),
                                channel.getAccountNumber(),
                                qr.url(OWNER, channel.getId()),
                                ChannelQrCodes.URL_LIFETIME.toSeconds()))
                        .toList();
        String note = landlordId == null ? null
                : landlords.findById(landlordId).map(LandlordProfile::getPaymentNote).orElse(null);

        return new PaymentDetails(shown, note);
    }

    /**
     * What a payment should say about where it went, or null when nobody chose.
     *
     * <p>The channel must be this lease's landlord's and visible: a tenant picks
     * from the list they were shown, and the words are written here rather than
     * taken from them, so nobody can type their own account into a record.
     */
    @Transactional(readOnly = true)
    public String sentTo(Lease lease, UUID channelId) {
        if (channelId == null) {
            return null;
        }
        UUID landlordId = leases.landlordOf(lease);
        return channels.findByIdAndLandlordId(channelId, landlordId)
                .filter(LandlordPaymentChannel::isVisible)
                .map(LandlordPaymentChannel::label)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.NOT_FOUND, "No such payment channel."));
    }

    // ---- closing an account ------------------------------------------------------------

    /**
     * A landlord's account numbers and QR codes, gone when they close their
     * account. They are personal details, like a tenant's ID photograph.
     */
    @Transactional
    public void forget(UUID landlordId) {
        for (LandlordPaymentChannel channel : channels.findByLandlordIdOrderBySortOrderAsc(landlordId)) {
            qr.remove(OWNER, channel.getId());
            channels.delete(channel);
        }
        landlords.findById(landlordId).ifPresent(landlord -> {
            landlord.notePayments(null);
            landlords.save(landlord);
        });
    }

    // ---- shared -----------------------------------------------------------------------

    /** Not a landlord reads as not found, like anything else that is not somebody's. */
    private LandlordProfile requireLandlord(UUID userId) {
        return landlords.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "Nothing to see here."));
    }

    private LandlordPaymentChannel find(UUID landlordId, UUID id) {
        requireLandlord(landlordId);
        return channels.findByIdAndLandlordId(id, landlordId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such payment channel."));
    }

    private PaymentChannelResponse describe(LandlordPaymentChannel channel) {
        return new PaymentChannelResponse(
                channel.getId(),
                channel.getChannel(),
                channel.getAccountName(),
                channel.getAccountNumber(),
                channel.isVisible(),
                channel.getSortOrder(),
                qr.url(OWNER, channel.getId()),
                ChannelQrCodes.URL_LIFETIME.toSeconds());
    }
}
