package app.lizmo.platform.billing;

import app.lizmo.billing.PaymentMethod;
import app.lizmo.billing.PaymentStatus;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.DocumentType;
import app.lizmo.document.ImageNormaliser;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformInvoiceResponse;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentForAdmin;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentRequest;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentResponse;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.user.UserRepository;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * Lizmo billing landlords, and being paid.
 *
 * <p>Product spec §3, per property since V16: on the 1st, count what each
 * property has let and raise one invoice for it, due that day. Vacant slots
 * are never billed, and a property with nothing let gets no invoice at all.
 *
 * <p>Enforcement is Ariel's call on the spec's seven days: thirty. The day after
 * the due date the landlord is warned, once. Thirty days after it, the property
 * locks -- which stops it growing and touches nothing else: rent, repairs and
 * ending tenancies all go on, because the tenants are not Lizmo's debtors.
 *
 * <p>Paying works like a tenant paying rent. The landlord sends proof, an admin
 * confirms or refuses it, and only confirmation moves the invoice. Paying in
 * full lifts the lock this invoice caused, and never a lock an admin placed by
 * hand for some other reason.
 */
@Service
public class PlatformBillingService {

    /** A let whole unit, a month. Stored on each invoice, so it can change later. */
    static final BigDecimal UNIT_RATE = new BigDecimal("150.00");

    /** A let bed, a month. */
    static final BigDecimal BED_RATE = new BigDecimal("50.00");

    /** Days after the due date that an unpaid invoice locks its property. */
    static final int GRACE_DAYS = 30;

    private static final Duration URL_LIFETIME = Duration.ofMinutes(10);

    private static final long MAX_UPLOAD_BYTES = 10L * 1024 * 1024;

    private final PlatformInvoiceRepository invoices;
    private final PlatformPaymentRepository payments;
    private final PropertyRepository properties;
    private final BillableSlots slots;
    private final UserRepository users;
    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final ImageNormaliser normaliser;
    private final NotificationService notifications;
    private final Clock clock;

    public PlatformBillingService(
            PlatformInvoiceRepository invoices,
            PlatformPaymentRepository payments,
            PropertyRepository properties,
            BillableSlots slots,
            UserRepository users,
            StoredDocumentRepository documents,
            DocumentStore store,
            ImageNormaliser normaliser,
            NotificationService notifications,
            Clock clock) {
        this.invoices = invoices;
        this.payments = payments;
        this.properties = properties;
        this.slots = slots;
        this.users = users;
        this.documents = documents;
        this.store = store;
        this.normaliser = normaliser;
        this.notifications = notifications;
        this.clock = clock;
    }

    // ---- the jobs ------------------------------------------------------------

    /**
     * Raises this month's invoices.
     *
     * <p>Dated the 1st whatever day it runs, so a job that fires late or is
     * retried still bills the month it is for -- and a second run raises
     * nothing, because each property has at most one invoice a month.
     *
     * @return how many were raised
     */
    @Transactional
    public int snapshot() {
        LocalDate billingDate = LocalDate.now(clock).withDayOfMonth(1);
        int raised = 0;

        for (Property property : properties.findAll()) {
            if (invoices.existsByPropertyIdAndBillingDate(property.getId(), billingDate)) {
                continue;
            }
            BillableSlots.Count count = slots.of(property.getId());
            if (count.isEmpty()) {
                // Vacant inventory costs nothing, and an invoice for nothing is
                // just a notification to ignore.
                continue;
            }

            PlatformInvoice invoice = invoices.save(new PlatformInvoice(
                    property.getId(), billingDate, count.units(), count.beds(),
                    UNIT_RATE, BED_RATE));

            notifications.raise(
                    property.getLandlordId(),
                    NotificationType.PLATFORM_INVOICE_ISSUED,
                    "Your Lizmo invoice for " + property.getName(),
                    "P%s for %s, for %s.".formatted(
                            plain(invoice.getAmountDue()), slotsOf(invoice), label(invoice)),
                    NotificationEntityType.PLATFORM_INVOICE,
                    invoice.getId());
            raised++;
        }
        return raised;
    }

    /**
     * Warns about overdue invoices, once, and locks properties thirty days on.
     *
     * <p>Daily, and idempotent: what has already been done is recorded on the
     * invoice, so a second run the same day warns nobody and locks nothing.
     *
     * @return how many were warned and how many locked
     */
    @Transactional
    public Map<String, Integer> enforce() {
        LocalDate today = LocalDate.now(clock);
        Instant now = clock.instant();
        int warned = 0;
        int locked = 0;

        for (PlatformInvoice invoice : invoices.findByStatusNot(PlatformInvoiceStatus.PAID)) {
            if (!invoice.isOverdue(today)) {
                continue;
            }
            Property property = properties.findById(invoice.getPropertyId()).orElse(null);
            if (property == null) {
                continue;
            }

            if (invoice.getOverdueWarnedAt() == null) {
                notifications.raise(
                        property.getLandlordId(),
                        NotificationType.PLATFORM_INVOICE_OVERDUE,
                        "Your Lizmo invoice is overdue",
                        ("P%s for %s is still owed. If it is not paid by %s, %s stops "
                                + "taking new units, beds and tenants. Your tenants are "
                                + "not affected.").formatted(
                                plain(invoice.outstanding()), property.getName(),
                                spoken(locksOn(invoice)), property.getName()),
                        NotificationEntityType.PLATFORM_INVOICE,
                        invoice.getId());
                invoice.markOverdueWarned(now);
                warned++;
            }

            if (invoice.getLockedAt() == null && !today.isBefore(locksOn(invoice))
                    // A property an admin already locked by hand is left as it is,
                    // and not marked as this invoice's doing -- or paying this
                    // invoice would lift a lock placed for some other reason.
                    && !property.isLocked()) {
                property.lock();
                properties.save(property);
                invoice.markLocked(now);
                notifications.raise(
                        property.getLandlordId(),
                        NotificationType.PLATFORM_PROPERTY_LOCKED,
                        property.getName() + " is locked",
                        ("Its Lizmo invoice is unpaid, so it cannot take new units, beds or "
                                + "tenants until it is paid. Rent, repairs and your tenants "
                                + "are not affected."),
                        NotificationEntityType.PLATFORM_INVOICE,
                        invoice.getId());
                locked++;
            }

            invoices.save(invoice);
        }

        return Map.of("warned", warned, "locked", locked);
    }

    // ---- the landlord --------------------------------------------------------

    /** Every invoice on this landlord's properties, newest month first. */
    @Transactional(readOnly = true)
    public List<PlatformInvoiceResponse> forLandlord(UUID landlordId) {
        Map<UUID, Property> owned = new HashMap<>();
        for (Property property : properties.findByLandlordIdOrderByNameAsc(landlordId)) {
            owned.put(property.getId(), property);
        }
        if (owned.isEmpty()) {
            return List.of();
        }
        return invoices.findByPropertyIdInOrderByBillingDateDesc(owned.keySet()).stream()
                .map(invoice -> describe(invoice, owned.get(invoice.getPropertyId())))
                .toList();
    }

    /**
     * A landlord saying they have paid an invoice, with proof.
     *
     * <p>Proof is required here, unlike rent: nobody pays Lizmo in cash at the
     * door, and an admin matching a transfer to a landlord needs something to
     * match it against.
     */
    @Transactional
    public PlatformInvoiceResponse pay(
            UUID invoiceId, UUID landlordId, PlatformPaymentRequest command, MultipartFile proof) {
        PlatformInvoice invoice = invoices.findById(invoiceId)
                .orElseThrow(PlatformBillingService::notFound);
        Property property = properties.findById(invoice.getPropertyId())
                .filter(candidate -> candidate.isOwnedBy(landlordId))
                .orElseThrow(PlatformBillingService::notFound);

        if (invoice.isPaid()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "That invoice is already paid.");
        }
        if (command.amountPaid() == null || command.amountPaid().signum() <= 0) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "Enter how much you paid.");
        }
        if (proof == null || proof.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Attach a screenshot of the payment, so Lizmo can find it.");
        }
        if (proof.getSize() > MAX_UPLOAD_BYTES) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That file is larger than 10MB. Please upload a smaller photo.");
        }

        byte[] original;
        try {
            original = proof.getBytes();
        } catch (IOException e) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That upload did not arrive in one piece. Please try again.");
        }

        String remarks = command.remarks() == null || command.remarks().isBlank()
                ? null : command.remarks().trim();
        PlatformPayment payment = payments.save(new PlatformPayment(
                invoice.getId(),
                command.amountPaid(),
                command.paymentDate() == null ? LocalDate.now(clock) : command.paymentDate(),
                command.paymentMethod() == null ? PaymentMethod.OTHER : command.paymentMethod(),
                landlordId,
                remarks));

        // Re-encoded like every other photograph, so no EXIF and no location
        // leaves somebody's phone.
        byte[] normalised = normaliser.normalise(original);
        String key = "platform-payments/%s/%s.jpg".formatted(payment.getId(), UUID.randomUUID());
        store.put(key, normalised, ImageNormaliser.OUTPUT_CONTENT_TYPE);
        documents.save(new StoredDocument(
                DocumentOwnerType.PLATFORM_PAYMENT,
                payment.getId(),
                landlordId,
                DocumentType.RECEIPT,
                key,
                ImageNormaliser.OUTPUT_CONTENT_TYPE,
                normalised.length));

        return describe(invoice, property);
    }

    // ---- Lizmo's admins --------------------------------------------------------

    /** Payments waiting to be checked, oldest first. */
    @Transactional(readOnly = true)
    public List<PlatformPaymentForAdmin> queue() {
        return payments.findByStatusOrderByCreatedAtAsc(PaymentStatus.PENDING_VERIFICATION).stream()
                .map(this::forAdmin)
                .toList();
    }

    /**
     * An admin agreeing the money arrived.
     *
     * <p>Credits the invoice, and -- if that settles it -- lifts the lock it
     * caused, unless another unpaid invoice is still holding the same property.
     */
    @Transactional
    public PlatformPaymentForAdmin confirm(UUID paymentId, UUID adminId) {
        PlatformPayment payment = pending(paymentId);
        PlatformInvoice invoice = invoices.findById(payment.getInvoiceId())
                .orElseThrow(PlatformBillingService::notFound);
        Property property = properties.findById(invoice.getPropertyId()).orElse(null);

        payment.confirm(adminId, clock.instant());
        payments.save(payment);
        invoice.credit(payment.getAmountPaid());

        boolean unlocked = false;
        if (invoice.isPaid() && invoice.getLockedAt() != null) {
            invoice.clearLock();
            boolean stillHeld = property != null
                    && invoices.existsByPropertyIdAndLockedAtIsNotNullAndStatusNotAndIdNot(
                            property.getId(), PlatformInvoiceStatus.PAID, invoice.getId());
            if (property != null && property.isLocked() && !stillHeld) {
                property.unlock();
                properties.save(property);
                unlocked = true;
            }
        }
        invoices.save(invoice);

        if (property != null) {
            String settled = invoice.isPaid()
                    ? " The invoice is paid."
                    : " P%s is still owed.".formatted(plain(invoice.outstanding()));
            notifications.raise(
                    property.getLandlordId(),
                    NotificationType.PLATFORM_PAYMENT_CONFIRMED,
                    "Lizmo received your payment",
                    "P%s for %s, %s.%s%s".formatted(
                            plain(payment.getAmountPaid()), property.getName(), label(invoice),
                            settled,
                            unlocked ? " " + property.getName() + " is unlocked." : ""),
                    NotificationEntityType.PLATFORM_INVOICE,
                    invoice.getId());
        }
        return forAdmin(payment);
    }

    /** An admin saying it did not arrive. The landlord is told why. */
    @Transactional
    public PlatformPaymentForAdmin reject(UUID paymentId, UUID adminId, String why) {
        PlatformPayment payment = pending(paymentId);
        PlatformInvoice invoice = invoices.findById(payment.getInvoiceId())
                .orElseThrow(PlatformBillingService::notFound);

        payment.reject(adminId, clock.instant(), why);
        payments.save(payment);

        properties.findById(invoice.getPropertyId()).ifPresent(property -> notifications.raise(
                property.getLandlordId(),
                NotificationType.PLATFORM_PAYMENT_REJECTED,
                "Lizmo could not confirm your payment",
                "P%s for %s, %s, was not confirmed. %s".formatted(
                        plain(payment.getAmountPaid()), property.getName(), label(invoice),
                        why == null || why.isBlank() ? "Contact Lizmo support." : why.trim()),
                NotificationEntityType.PLATFORM_INVOICE,
                invoice.getId()));
        return forAdmin(payment);
    }

    // ---- shared ----------------------------------------------------------------

    private PlatformPayment pending(UUID paymentId) {
        PlatformPayment payment = payments.findById(paymentId)
                .orElseThrow(PlatformBillingService::notFound);
        if (!payment.isPending()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That payment has already been answered.");
        }
        return payment;
    }

    private PlatformInvoiceResponse describe(PlatformInvoice invoice, Property property) {
        LocalDate today = LocalDate.now(clock);
        List<PlatformPaymentResponse> sent = payments
                .findByInvoiceIdOrderByCreatedAtAsc(invoice.getId()).stream()
                .map(payment -> new PlatformPaymentResponse(
                        payment.getId(),
                        payment.getAmountPaid(),
                        payment.getPaymentDate(),
                        payment.getPaymentMethod(),
                        payment.getStatus(),
                        payment.getRemarks(),
                        proofUrl(payment),
                        URL_LIFETIME.toSeconds(),
                        payment.getCreatedAt()))
                .toList();

        return new PlatformInvoiceResponse(
                invoice.getId(),
                invoice.getPropertyId(),
                property == null ? null : property.getName(),
                label(invoice),
                invoice.getBillingDate(),
                invoice.getDueDate(),
                invoice.getOccupiedUnits(),
                invoice.getOccupiedBeds(),
                invoice.getUnitRate(),
                invoice.getBedRate(),
                invoice.getAmountDue(),
                invoice.getAmountPaid(),
                invoice.outstanding(),
                invoice.getStatus(),
                invoice.isOverdue(today),
                invoice.isPaid() || invoice.getLockedAt() != null ? null : locksOn(invoice),
                invoice.getLockedAt() != null,
                sent);
    }

    private PlatformPaymentForAdmin forAdmin(PlatformPayment payment) {
        PlatformInvoice invoice = invoices.findById(payment.getInvoiceId()).orElse(null);
        Property property = invoice == null ? null
                : properties.findById(invoice.getPropertyId()).orElse(null);
        String landlordName = property == null ? null
                : users.findById(property.getLandlordId()).map(user -> user.getName()).orElse(null);

        return new PlatformPaymentForAdmin(
                payment.getId(),
                payment.getInvoiceId(),
                property == null ? null : property.getLandlordId(),
                landlordName,
                property == null ? null : property.getName(),
                invoice == null ? null : label(invoice),
                invoice == null ? null : invoice.getAmountDue(),
                invoice == null ? null : invoice.outstanding(),
                payment.getAmountPaid(),
                payment.getPaymentDate(),
                payment.getPaymentMethod(),
                payment.getStatus(),
                payment.getRemarks(),
                proofUrl(payment),
                URL_LIFETIME.toSeconds(),
                payment.getCreatedAt());
    }

    private String proofUrl(PlatformPayment payment) {
        return documents.findByOwnerTypeAndOwnerId(DocumentOwnerType.PLATFORM_PAYMENT, payment.getId())
                .stream()
                .findFirst()
                .map(document -> store.presignedUrl(document.getStorageKey(), URL_LIFETIME))
                .orElse(null);
    }

    private static LocalDate locksOn(PlatformInvoice invoice) {
        return invoice.getDueDate().plusDays(GRACE_DAYS);
    }

    private static String label(PlatformInvoice invoice) {
        return DateTimeFormatter.ofPattern("MMMM yyyy", Locale.ENGLISH)
                .format(invoice.getBillingDate());
    }

    /** "31 October". */
    private static String spoken(LocalDate date) {
        return date.getDayOfMonth() + " "
                + date.getMonth().getDisplayName(TextStyle.FULL, Locale.ENGLISH);
    }

    /** "4 beds and 1 unit". */
    private static String slotsOf(PlatformInvoice invoice) {
        String beds = invoice.getOccupiedBeds() == 1 ? "1 bed" : invoice.getOccupiedBeds() + " beds";
        String units = invoice.getOccupiedUnits() == 1 ? "1 unit" : invoice.getOccupiedUnits() + " units";
        if (invoice.getOccupiedUnits() == 0) return beds;
        if (invoice.getOccupiedBeds() == 0) return units;
        return beds + " and " + units;
    }

    private static String plain(BigDecimal amount) {
        return amount.stripTrailingZeros().toPlainString();
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No such invoice or payment.");
    }
}
