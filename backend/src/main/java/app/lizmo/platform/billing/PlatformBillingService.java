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
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformInvoiceLine;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentForAdmin;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentRequest;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformPaymentResponse;
import app.lizmo.platform.billing.dto.PlatformBillingDtos.PlatformStatementResponse;
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
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
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
 * <p>One statement a month per landlord, itemised by property: P50 for each let
 * bed, P150 for each let whole unit, nothing for anything empty. The statement
 * is what a landlord pays. When it is settled in full each line becomes an
 * invoice -- numbered and dated -- which is what they file against a building.
 *
 * <p>Enforcement is Ariel's thirty days, not the spec's seven. The day after
 * the statement falls due the landlord is warned, once. Thirty days after it,
 * every property they own locks, because the debt is the account's rather than
 * one building's. Locking stops a property growing and touches nothing else:
 * rent, repairs and ending tenancies all go on, since the tenants are not
 * Lizmo's debtors.
 */
@Service
public class PlatformBillingService {

    /** A let whole unit, a month. Stored on each line, so it can change later. */
    static final BigDecimal UNIT_RATE = new BigDecimal("150.00");

    /** A let bed, a month. */
    static final BigDecimal BED_RATE = new BigDecimal("50.00");

    /** Days after the due date that an unpaid statement locks the account. */
    static final int GRACE_DAYS = 30;

    private static final Duration URL_LIFETIME = Duration.ofMinutes(10);

    private static final long MAX_UPLOAD_BYTES = 10L * 1024 * 1024;

    private final PlatformStatementRepository statements;
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
            PlatformStatementRepository statements,
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
        this.statements = statements;
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
     * Raises this month's statements.
     *
     * <p>Dated the 1st whatever day it runs, so a job that fires late or is
     * retried still bills the month it is for -- and a second run raises
     * nothing, because a landlord has at most one statement a month.
     *
     * @return how many were raised
     */
    @Transactional
    public int snapshot() {
        LocalDate billingDate = LocalDate.now(clock).withDayOfMonth(1);

        Map<UUID, List<Property>> byLandlord = new LinkedHashMap<>();
        for (Property property : properties.findAll()) {
            byLandlord.computeIfAbsent(property.getLandlordId(), key -> new ArrayList<>())
                    .add(property);
        }

        int raised = 0;
        for (Map.Entry<UUID, List<Property>> entry : byLandlord.entrySet()) {
            UUID landlordId = entry.getKey();
            if (statements.existsByLandlordIdAndBillingDate(landlordId, billingDate)) {
                continue;
            }

            // Counted before anything is written, so a landlord with nothing
            // let gets no statement rather than one for zero.
            List<Billable> billable = new ArrayList<>();
            for (Property property : entry.getValue()) {
                BillableSlots.Count count = slots.of(property.getId());
                if (!count.isEmpty()) {
                    billable.add(new Billable(property, count));
                }
            }
            if (billable.isEmpty()) {
                continue;
            }
            billable.sort(Comparator.comparing(
                    row -> row.property().getName(),
                    Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER)));

            PlatformStatement statement =
                    statements.save(new PlatformStatement(landlordId, billingDate));

            BigDecimal total = BigDecimal.ZERO;
            for (Billable row : billable) {
                PlatformInvoice line = invoices.save(new PlatformInvoice(
                        statement.getId(),
                        row.property().getId(),
                        row.count().units(),
                        row.count().beds(),
                        UNIT_RATE,
                        BED_RATE));
                total = total.add(line.getAmountDue());
            }
            statement.total(total);
            statements.save(statement);

            notifications.raise(
                    landlordId,
                    NotificationType.PLATFORM_INVOICE_ISSUED,
                    "Your Lizmo statement for " + label(statement),
                    "P%s for %s, due today.".formatted(
                            plain(total), properties(billable.size())),
                    NotificationEntityType.PLATFORM_INVOICE,
                    statement.getId());
            raised++;
        }
        return raised;
    }

    /**
     * Warns about overdue statements, once, and locks the account thirty days on.
     *
     * <p>Daily, and idempotent: what has already been done is recorded on the
     * statement, so a second run the same day warns nobody and locks nothing.
     *
     * @return how many were warned, and how many properties locked
     */
    @Transactional
    public Map<String, Integer> enforce() {
        LocalDate today = LocalDate.now(clock);
        Instant now = clock.instant();
        int warned = 0;
        int locked = 0;

        for (PlatformStatement statement : statements.findByStatusNot(PlatformStatementStatus.PAID)) {
            if (!statement.isOverdue(today)) {
                continue;
            }
            List<Property> owned =
                    properties.findByLandlordIdOrderByNameAsc(statement.getLandlordId());

            if (statement.getOverdueWarnedAt() == null) {
                notifications.raise(
                        statement.getLandlordId(),
                        NotificationType.PLATFORM_INVOICE_OVERDUE,
                        "Your Lizmo statement is overdue",
                        ("P%s is still owed for %s. If it is not paid by %s, your "
                                + "properties stop taking new units, beds and tenants. "
                                + "Your tenants are not affected.").formatted(
                                plain(statement.outstanding()), label(statement),
                                spoken(locksOn(statement))),
                        NotificationEntityType.PLATFORM_INVOICE,
                        statement.getId());
                statement.markOverdueWarned(now);
                warned++;
            }

            if (statement.getLockedAt() == null && !today.isBefore(locksOn(statement))) {
                int lockedNow = 0;
                for (Property property : owned) {
                    // A property an admin locked by hand is left as it is, and
                    // not claimed by this statement -- or paying would lift a
                    // lock placed for some other reason.
                    if (!property.isLocked()) {
                        property.lockFor(statement.getId());
                        properties.save(property);
                        lockedNow++;
                    }
                }
                // Marked either way, so a daily job does not try again forever.
                statement.markLocked(now);
                if (lockedNow > 0) {
                    notifications.raise(
                            statement.getLandlordId(),
                            NotificationType.PLATFORM_PROPERTY_LOCKED,
                            lockedNow == 1 ? "A property is locked" : "Your properties are locked",
                            ("The Lizmo statement for %s is unpaid, so %s cannot take new "
                                    + "units, beds or tenants until it is paid. Rent, repairs "
                                    + "and your tenants are not affected.").formatted(
                                    label(statement),
                                    lockedNow == 1 ? "one property" : "they"),
                            NotificationEntityType.PLATFORM_INVOICE,
                            statement.getId());
                }
                locked += lockedNow;
            }

            statements.save(statement);
        }

        return Map.of("warned", warned, "locked", locked);
    }

    // ---- the landlord --------------------------------------------------------

    /** Every statement of theirs, newest month first. */
    @Transactional(readOnly = true)
    public List<PlatformStatementResponse> forLandlord(UUID landlordId) {
        List<PlatformStatement> owned =
                statements.findByLandlordIdOrderByBillingDateDesc(landlordId);
        if (owned.isEmpty()) {
            return List.of();
        }
        List<UUID> ids = owned.stream().map(PlatformStatement::getId).toList();

        Map<UUID, List<PlatformInvoice>> lines = new HashMap<>();
        invoices.findByStatementIdIn(ids).forEach(line ->
                lines.computeIfAbsent(line.getStatementId(), key -> new ArrayList<>()).add(line));

        Map<UUID, List<PlatformPayment>> sent = new HashMap<>();
        payments.findByStatementIdIn(ids).forEach(payment ->
                sent.computeIfAbsent(payment.getStatementId(), key -> new ArrayList<>())
                        .add(payment));

        Map<UUID, String> names = propertyNames(lines.values().stream()
                .flatMap(List::stream)
                .map(PlatformInvoice::getPropertyId)
                .distinct()
                .toList());

        LocalDate today = LocalDate.now(clock);
        return owned.stream()
                .map(statement -> describe(
                        statement,
                        lines.getOrDefault(statement.getId(), List.of()),
                        sent.getOrDefault(statement.getId(), List.of()),
                        names,
                        today))
                .toList();
    }

    /**
     * A landlord saying they have paid a statement, with proof.
     *
     * <p>Proof is required, unlike rent: nobody pays Lizmo in cash at the door,
     * and an admin matching a transfer to a landlord needs something to match
     * it against.
     */
    @Transactional
    public PlatformStatementResponse pay(
            UUID statementId, UUID landlordId, PlatformPaymentRequest command,
            MultipartFile proof) {
        PlatformStatement statement = statements.findById(statementId)
                .filter(candidate -> candidate.getLandlordId().equals(landlordId))
                .orElseThrow(PlatformBillingService::notFound);

        if (statement.isPaid()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "That statement is already paid.");
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
                statement.getId(),
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

        return one(statement);
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
     * <p>Credits the statement. Settling it in full is the moment the invoices
     * are issued -- one per property, numbered and dated -- and the moment any
     * locks this statement placed are lifted. A part payment issues nothing:
     * "once paid" is Ariel's rule, and half an invoice is not a document.
     */
    @Transactional
    public PlatformPaymentForAdmin confirm(UUID paymentId, UUID adminId) {
        PlatformPayment payment = pending(paymentId);
        PlatformStatement statement = statements.findById(payment.getStatementId())
                .orElseThrow(PlatformBillingService::notFound);

        payment.confirm(adminId, clock.instant());
        payments.save(payment);
        statement.credit(payment.getAmountPaid());

        int issued = 0;
        int unlocked = 0;
        if (statement.isPaid()) {
            Instant now = clock.instant();
            for (PlatformInvoice line : invoices.findByStatementId(statement.getId())) {
                if (!line.isIssued()) {
                    line.issue(invoiceNumber(statement), now);
                    invoices.save(line);
                    issued++;
                }
            }
            for (Property property : properties.findByLockedByStatementId(statement.getId())) {
                property.unlock();
                properties.save(property);
                unlocked++;
            }
            statement.clearLock();
        }
        statements.save(statement);

        String settled = statement.isPaid()
                ? " The statement is paid, and your %s ready.".formatted(
                        issued == 1 ? "invoice is" : "invoices are")
                : " P%s is still owed.".formatted(plain(statement.outstanding()));
        notifications.raise(
                statement.getLandlordId(),
                NotificationType.PLATFORM_PAYMENT_CONFIRMED,
                "Lizmo received your payment",
                "P%s for %s.%s%s".formatted(
                        plain(payment.getAmountPaid()), label(statement), settled,
                        unlocked == 0 ? ""
                                : (unlocked == 1 ? " Your property is unlocked."
                                        : " Your properties are unlocked.")),
                NotificationEntityType.PLATFORM_INVOICE,
                statement.getId());

        return forAdmin(payment);
    }

    /** An admin saying it did not arrive. The landlord is told why. */
    @Transactional
    public PlatformPaymentForAdmin reject(UUID paymentId, UUID adminId, String why) {
        PlatformPayment payment = pending(paymentId);
        PlatformStatement statement = statements.findById(payment.getStatementId())
                .orElseThrow(PlatformBillingService::notFound);

        payment.reject(adminId, clock.instant(), why);
        payments.save(payment);

        notifications.raise(
                statement.getLandlordId(),
                NotificationType.PLATFORM_PAYMENT_REJECTED,
                "Lizmo could not confirm your payment",
                "P%s for %s was not confirmed. %s".formatted(
                        plain(payment.getAmountPaid()), label(statement),
                        why == null || why.isBlank() ? "Contact Lizmo support." : why.trim()),
                NotificationEntityType.PLATFORM_INVOICE,
                statement.getId());
        return forAdmin(payment);
    }

    // ---- shared ----------------------------------------------------------------

    private PlatformStatementResponse one(PlatformStatement statement) {
        List<PlatformInvoice> lines = invoices.findByStatementId(statement.getId());
        return describe(
                statement,
                lines,
                payments.findByStatementIdOrderByCreatedAtAsc(statement.getId()),
                propertyNames(lines.stream().map(PlatformInvoice::getPropertyId).toList()),
                LocalDate.now(clock));
    }

    private PlatformPayment pending(UUID paymentId) {
        PlatformPayment payment = payments.findById(paymentId)
                .orElseThrow(PlatformBillingService::notFound);
        if (!payment.isPending()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That payment has already been answered.");
        }
        return payment;
    }

    private Map<UUID, String> propertyNames(List<UUID> ids) {
        Map<UUID, String> names = new HashMap<>();
        if (!ids.isEmpty()) {
            properties.findAllById(ids).forEach(
                    property -> names.put(property.getId(), property.getName()));
        }
        return names;
    }

    private PlatformStatementResponse describe(
            PlatformStatement statement,
            List<PlatformInvoice> lines,
            List<PlatformPayment> sent,
            Map<UUID, String> names,
            LocalDate today) {

        List<PlatformInvoiceLine> itemised = lines.stream()
                .map(line -> new PlatformInvoiceLine(
                        line.getId(),
                        line.getPropertyId(),
                        names.get(line.getPropertyId()),
                        line.getOccupiedUnits(),
                        line.getOccupiedBeds(),
                        line.getUnitRate(),
                        line.getBedRate(),
                        line.getAmountDue(),
                        line.getInvoiceNumber(),
                        line.getIssuedAt()))
                .sorted(Comparator.comparing(
                        PlatformInvoiceLine::propertyName,
                        Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER)))
                .toList();

        List<PlatformPaymentResponse> history = sent.stream()
                .sorted(Comparator.comparing(PlatformPayment::getCreatedAt))
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

        return new PlatformStatementResponse(
                statement.getId(),
                label(statement),
                statement.getBillingDate(),
                statement.getDueDate(),
                statement.getAmountDue(),
                statement.getAmountPaid(),
                statement.outstanding(),
                statement.getStatus(),
                statement.isOverdue(today),
                statement.isPaid() || statement.getLockedAt() != null ? null : locksOn(statement),
                statement.getLockedAt() != null,
                itemised,
                history);
    }

    private PlatformPaymentForAdmin forAdmin(PlatformPayment payment) {
        PlatformStatement statement = statements.findById(payment.getStatementId()).orElse(null);
        String landlordName = statement == null ? null
                : users.findById(statement.getLandlordId())
                        .map(user -> user.getName())
                        .orElse(null);

        return new PlatformPaymentForAdmin(
                payment.getId(),
                payment.getStatementId(),
                statement == null ? null : statement.getLandlordId(),
                landlordName,
                statement == null ? null : label(statement),
                statement == null ? 0 : invoices.findByStatementId(statement.getId()).size(),
                statement == null ? null : statement.getAmountDue(),
                statement == null ? null : statement.outstanding(),
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
        return documents
                .findByOwnerTypeAndOwnerId(DocumentOwnerType.PLATFORM_PAYMENT, payment.getId())
                .stream()
                .findFirst()
                .map(document -> store.presignedUrl(document.getStorageKey(), URL_LIFETIME))
                .orElse(null);
    }

    /** "LZM-2026-09-0007", from a sequence, so two never collide. */
    private String invoiceNumber(PlatformStatement statement) {
        return "LZM-%s-%04d".formatted(
                DateTimeFormatter.ofPattern("yyyy-MM", Locale.ENGLISH)
                        .format(statement.getBillingDate()),
                statements.nextInvoiceNumber());
    }

    private static LocalDate locksOn(PlatformStatement statement) {
        return statement.getDueDate().plusDays(GRACE_DAYS);
    }

    private static String label(PlatformStatement statement) {
        return DateTimeFormatter.ofPattern("MMMM yyyy", Locale.ENGLISH)
                .format(statement.getBillingDate());
    }

    /** "31 October". */
    private static String spoken(LocalDate date) {
        return date.getDayOfMonth() + " "
                + date.getMonth().getDisplayName(TextStyle.FULL, Locale.ENGLISH);
    }

    private static String properties(int count) {
        return count == 1 ? "1 property" : count + " properties";
    }

    private static String plain(BigDecimal amount) {
        return amount.stripTrailingZeros().toPlainString();
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No such statement or payment.");
    }

    /** A property with something let, before its line is written. */
    private record Billable(Property property, BillableSlots.Count count) {
    }
}
