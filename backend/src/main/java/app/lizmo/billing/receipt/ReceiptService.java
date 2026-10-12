package app.lizmo.billing.receipt;

import app.lizmo.billing.BillingPeriod;
import app.lizmo.billing.Payment;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeasePaperworkAccess;
import app.lizmo.property.BedRepository;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.user.UserRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Issuing acknowledgement receipts, and handing them back.
 *
 * <p>Every confirmed payment has exactly one: issued in the same transaction
 * that confirms or records it, so there is never a confirmed payment without
 * a receipt, nor a receipt for money that was then not confirmed after all.
 */
@Service
public class ReceiptService {

    /** Whose year a receipt is numbered in: the landlord's, here. */
    private static final ZoneId PHILIPPINES = ZoneId.of("Asia/Manila");

    private final ReceiptRepository receipts;
    private final UnitRepository units;
    private final BedRepository beds;
    private final PropertyRepository properties;
    private final UserRepository users;
    private final LeasePaperworkAccess access;
    private final JdbcTemplate jdbc;
    private final Clock clock;

    public ReceiptService(
            ReceiptRepository receipts,
            UnitRepository units,
            BedRepository beds,
            PropertyRepository properties,
            UserRepository users,
            LeasePaperworkAccess access,
            JdbcTemplate jdbc,
            Clock clock) {
        this.receipts = receipts;
        this.units = units;
        this.beds = beds;
        this.properties = properties;
        this.users = users;
        this.access = access;
        this.jdbc = jdbc;
        this.clock = clock;
    }

    /**
     * Issues the receipt for a payment just confirmed or recorded.
     *
     * <p>Call after the period has been credited with it, so what is still
     * owed is what is left once this payment counts.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public Receipt issue(Lease lease, BillingPeriod period, Payment payment) {
        Unit unit = units.findById(lease.getUnitId()).orElseThrow();
        Property property = properties.findById(unit.getPropertyId()).orElseThrow();
        UUID landlord = property.getLandlordId();

        Instant now = clock.instant();
        int year = now.atZone(PHILIPPINES).getYear();

        return receipts.save(new Receipt(
                payment.getId(),
                lease.getId(),
                landlord,
                lease.getTenantId(),
                (short) year,
                next(landlord, year),
                now,
                nameOf(lease.getTenantId()),
                nameOf(landlord),
                property.getName(),
                place(lease, unit),
                period.getPeriodLabel(),
                period.getKind(),
                payment.getAmountPaid(),
                payment.getPaymentMethod(),
                payment.getSentTo(),
                payment.getPaymentDate(),
                period.outstanding().max(BigDecimal.ZERO)));
    }

    /**
     * The next number in this landlord's year.
     *
     * <p>One row per landlord and year, bumped in place: the database orders
     * two confirmations at the same moment, so neither can take a number the
     * other already has.
     */
    private int next(UUID landlord, int year) {
        Integer number = jdbc.queryForObject("""
                INSERT INTO receipt_counters (landlord_id, year, last_number)
                VALUES (?, ?, 1)
                ON CONFLICT (landlord_id, year)
                DO UPDATE SET last_number = receipt_counters.last_number + 1
                RETURNING last_number
                """, Integer.class, landlord, (short) year);
        return number == null ? 1 : number;
    }

    /** The tenant's own receipts on one tenancy, newest first. */
    @Transactional(readOnly = true)
    public List<ReceiptResponse> forTenant(UUID leaseId, UUID tenantId) {
        access.requireTenant(leaseId, tenantId);
        return describe(leaseId);
    }

    /** Everything a landlord has acknowledged on one tenancy, newest first. */
    @Transactional(readOnly = true)
    public List<ReceiptResponse> forLandlord(UUID leaseId, UUID landlordId) {
        access.requireLandlord(leaseId, landlordId);
        return describe(leaseId);
    }

    /** The receipt for a payment, if it has one. */
    @Transactional(readOnly = true)
    public Receipt ofPayment(UUID paymentId) {
        return receipts.findByPaymentId(paymentId).orElse(null);
    }

    /** Takes a closed account's name off every receipt that carries it. */
    @Transactional(propagation = Propagation.MANDATORY)
    public void forget(UUID userId, String replacement) {
        receipts.renameTenant(userId, replacement);
        receipts.renameLandlord(userId, replacement);
    }

    private List<ReceiptResponse> describe(UUID leaseId) {
        return receipts.findByLeaseIdOrderByIssuedAtDescSequenceDesc(leaseId).stream()
                .map(ReceiptResponse::of)
                .toList();
    }

    private String nameOf(UUID userId) {
        return users.findById(userId).map(user -> user.getName()).orElse("—");
    }

    /** "Bed 1, 2B" or "Unit 101": how both sides name the room. */
    private String place(Lease lease, Unit unit) {
        if (lease.getBedId() == null) {
            return "Unit " + unit.getUnitNumber();
        }
        return beds.findById(lease.getBedId())
                .map(bed -> bed.getBedLabel() + ", " + unit.getUnitNumber())
                .orElse("Unit " + unit.getUnitNumber());
    }
}
