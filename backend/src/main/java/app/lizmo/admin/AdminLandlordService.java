package app.lizmo.admin;

import app.lizmo.admin.dto.AdminPropertyDetail;
import app.lizmo.admin.dto.AdminPropertySummary;
import app.lizmo.admin.dto.LandlordDetail;
import app.lizmo.admin.dto.LandlordSummary;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.platform.billing.BillableSlots;
import app.lizmo.property.Bed;
import app.lizmo.property.BedRepository;
import app.lizmo.property.BedStatus;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.property.UnitStatus;
import app.lizmo.user.LandlordProfile;
import app.lizmo.user.LandlordProfileRepository;
import app.lizmo.user.User;
import app.lizmo.user.UserRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * What Lizmo's own staff can see and do about landlords.
 *
 * <p>Narrow about people. The landlord list and a landlord's page count
 * occupied slots, because that is what Lizmo bills for, and name no tenant.
 *
 * <p>Opening one property is the exception, by decision: it names the tenants
 * leasing each unit and bed right now, with their phone and email, so support
 * can reach them. Never their ID photographs, emergency contact or anything
 * else from their profile, and never anybody who has moved out.
 */
@Service
public class AdminLandlordService {

    private final LandlordProfileRepository landlords;
    private final UserRepository users;
    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;
    private final LeaseRepository leases;
    private final BillableSlots slots;

    public AdminLandlordService(
            LandlordProfileRepository landlords,
            UserRepository users,
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            LeaseRepository leases,
            BillableSlots slots) {
        this.landlords = landlords;
        this.users = users;
        this.properties = properties;
        this.units = units;
        this.beds = beds;
        this.leases = leases;
        this.slots = slots;
    }

    /** Every landlord, with enough to decide who needs chasing. */
    @Transactional(readOnly = true)
    public List<LandlordSummary> all() {
        List<LandlordProfile> profiles = landlords.findAll();
        if (profiles.isEmpty()) {
            return List.of();
        }

        // One query for the people rather than one per landlord: this list is
        // the console's home screen, and an N+1 here is felt on every visit.
        Map<UUID, User> accounts = users
                .findAllById(profiles.stream().map(LandlordProfile::getUserId).toList())
                .stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));

        return profiles.stream()
                .map(profile -> summarise(profile, accounts.get(profile.getUserId())))
                .sorted((a, b) -> a.name().compareToIgnoreCase(b.name()))
                .toList();
    }

    /** One landlord, with their properties and each property's own standing. */
    @Transactional(readOnly = true)
    public LandlordDetail one(UUID landlordId) {
        LandlordProfile profile = landlords.findById(landlordId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such landlord."));
        User account = users.findById(landlordId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such landlord."));

        List<AdminPropertySummary> owned = properties.findByLandlordIdOrderByNameAsc(landlordId).stream()
                .map(this::describe)
                .sorted((a, b) -> a.name().compareToIgnoreCase(b.name()))
                .toList();

        return new LandlordDetail(summarise(profile, account), owned);
    }

    /**
     * One property opened up: every unit and bed, and who leases which now.
     *
     * <p>Where a unit or bed stands is decided by its tenancy first. Something
     * with a tenancy running is leased whatever flag it carries; only something
     * with nobody in it can be out of service. So the two never contradict each
     * other, and "leased" counts exactly what a statement bills.
     *
     * <p>A handful of queries for the whole property, not one per bed: a
     * boarding house with forty beds should not mean forty trips.
     */
    @Transactional(readOnly = true)
    public AdminPropertyDetail property(UUID propertyId) {
        Property property = require(propertyId);
        List<Unit> owned = units.findByPropertyIdOrderByUnitNumberAsc(propertyId);
        List<UUID> unitIds = owned.stream().map(Unit::getId).toList();

        Map<UUID, List<Bed>> bedsByUnit = unitIds.isEmpty() ? Map.of()
                : beds.findByUnitIdInOrderByBedLabelAsc(unitIds).stream()
                        .collect(Collectors.groupingBy(Bed::getUnitId));

        List<Lease> running = unitIds.isEmpty() ? List.of()
                : leases.findByUnitIdInAndStatus(unitIds, LeaseStatus.ACTIVE);
        Map<UUID, Lease> byBed = running.stream()
                .filter(lease -> lease.getBedId() != null)
                .collect(Collectors.toMap(Lease::getBedId, Function.identity(), (a, b) -> a));
        Map<UUID, Lease> byWholeUnit = running.stream()
                .filter(lease -> lease.getBedId() == null)
                .collect(Collectors.toMap(Lease::getUnitId, Function.identity(), (a, b) -> a));
        Map<UUID, User> tenants = running.isEmpty() ? Map.of()
                : users.findAllById(running.stream().map(Lease::getTenantId).distinct().toList())
                        .stream()
                        .collect(Collectors.toMap(User::getId, Function.identity()));

        int leased = 0;
        int outOfService = 0;
        int bedCount = 0;
        List<AdminPropertyDetail.Unit> described = new ArrayList<>();

        for (Unit unit : owned) {
            boolean unitOff = unit.getStatus() == UnitStatus.MAINTENANCE;

            if (unit.isBedspace()) {
                List<Bed> room = bedsByUnit.getOrDefault(unit.getId(), List.of());
                bedCount += room.size();

                int bedsLeased = 0;
                int bedsOff = 0;
                List<AdminPropertyDetail.Bed> bedRows = new ArrayList<>();
                for (Bed bed : room) {
                    Lease lease = byBed.get(bed.getId());
                    AdminPropertyDetail.Occupancy occupancy = lease != null
                            ? AdminPropertyDetail.Occupancy.LEASED
                            : unitOff || bed.getStatus() == BedStatus.MAINTENANCE
                                    ? AdminPropertyDetail.Occupancy.OUT_OF_SERVICE
                                    : AdminPropertyDetail.Occupancy.VACANT;
                    if (occupancy == AdminPropertyDetail.Occupancy.LEASED) {
                        bedsLeased++;
                    } else if (occupancy == AdminPropertyDetail.Occupancy.OUT_OF_SERVICE) {
                        bedsOff++;
                    }
                    bedRows.add(new AdminPropertyDetail.Bed(
                            bed.getId(), bed.getBedLabel(), bed.getRent(), occupancy,
                            tenancy(lease, tenants)));
                }
                leased += bedsLeased;
                outOfService += bedsOff;

                // A room reads by its beds: every lettable bed taken is leased,
                // some taken is partly leased, none taken is vacant -- unless
                // there is nothing lettable in it at all.
                AdminPropertyDetail.Occupancy roomOccupancy;
                if (bedsLeased == 0) {
                    roomOccupancy = unitOff || (!room.isEmpty() && bedsOff == room.size())
                            ? AdminPropertyDetail.Occupancy.OUT_OF_SERVICE
                            : AdminPropertyDetail.Occupancy.VACANT;
                } else {
                    roomOccupancy = bedsLeased + bedsOff == room.size()
                            ? AdminPropertyDetail.Occupancy.LEASED
                            : AdminPropertyDetail.Occupancy.PARTLY_LEASED;
                }

                described.add(new AdminPropertyDetail.Unit(
                        unit.getId(), unit.getUnitNumber(), unit.getFloor(), unit.getRentalMode(),
                        unit.getCapacity(), unit.getRent(), roomOccupancy, null, bedRows));
            } else {
                Lease lease = byWholeUnit.get(unit.getId());
                AdminPropertyDetail.Occupancy occupancy = lease != null
                        ? AdminPropertyDetail.Occupancy.LEASED
                        : unitOff
                                ? AdminPropertyDetail.Occupancy.OUT_OF_SERVICE
                                : AdminPropertyDetail.Occupancy.VACANT;
                if (occupancy == AdminPropertyDetail.Occupancy.LEASED) {
                    leased++;
                } else if (occupancy == AdminPropertyDetail.Occupancy.OUT_OF_SERVICE) {
                    outOfService++;
                }
                described.add(new AdminPropertyDetail.Unit(
                        unit.getId(), unit.getUnitNumber(), unit.getFloor(), unit.getRentalMode(),
                        unit.getCapacity(), unit.getRent(), occupancy,
                        tenancy(lease, tenants), List.of()));
            }
        }

        return new AdminPropertyDetail(
                property.getId(),
                property.getName(),
                property.getAddress(),
                property.getType(),
                property.getUsage(),
                property.getCode(),
                property.getAccountStatus().name(),
                property.getLandlordId(),
                users.findById(property.getLandlordId()).map(User::getName).orElse(null),
                owned.size(),
                bedCount,
                leased,
                outOfService,
                described);
    }

    /** The tenancy and how to reach its tenant, or null when nobody is in it. */
    private static AdminPropertyDetail.Tenancy tenancy(Lease lease, Map<UUID, User> tenants) {
        if (lease == null) {
            return null;
        }
        User tenant = tenants.get(lease.getTenantId());
        return new AdminPropertyDetail.Tenancy(
                lease.getId(),
                tenant == null ? null : tenant.getName(),
                tenant == null ? null : tenant.getPhone(),
                tenant == null ? null : tenant.getEmail(),
                lease.getStartDate(),
                lease.getEndDate(),
                lease.getRentAmount());
    }

    /**
     * Stops a property being added to, until its invoice is settled.
     *
     * <p>Manual as well as automatic on purpose. The enforcement job will do
     * this on a schedule, but an admin needs to be able to lock a property
     * that is abusing the platform, and to unlock one whose landlord has
     * plainly paid while the payment is still being verified.
     */
    @Transactional
    public AdminPropertySummary lock(UUID propertyId) {
        Property property = require(propertyId);
        property.lock();
        properties.save(property);
        return describe(property);
    }

    @Transactional
    public AdminPropertySummary unlock(UUID propertyId) {
        Property property = require(propertyId);
        property.unlock();
        properties.save(property);
        return describe(property);
    }

    private Property require(UUID propertyId) {
        return properties.findById(propertyId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such property."));
    }

    private LandlordSummary summarise(LandlordProfile profile, User account) {
        List<Property> owned = properties.findByLandlordIdOrderByNameAsc(profile.getUserId());

        int occupiedUnits = 0;
        int occupiedBeds = 0;
        for (Property property : owned) {
            Occupancy occupancy = occupancyOf(property.getId());
            occupiedUnits += occupancy.occupiedUnits();
            occupiedBeds += occupancy.occupiedBeds();
        }

        return new LandlordSummary(
                profile.getUserId(),
                account == null ? "(unknown)" : account.getName(),
                account == null ? null : account.getEmail(),
                account == null ? null : account.getPhone(),
                owned.size(),
                (int) owned.stream().filter(Property::isLocked).count(),
                occupiedUnits,
                occupiedBeds,
                profile.getCreatedAt());
    }

    private AdminPropertySummary describe(Property property) {
        List<Unit> owned = units.findByPropertyIdOrderByUnitNumberAsc(property.getId());
        Occupancy occupancy = occupancyOf(property.getId());

        int bedCount = owned.stream()
                .mapToInt(unit -> (int) beds.countByUnitId(unit.getId()))
                .sum();

        return new AdminPropertySummary(
                property.getId(),
                property.getName(),
                property.getAddress(),
                property.getCode(),
                property.getAccountStatus().name(),
                owned.size(),
                occupancy.occupiedUnits(),
                bedCount,
                occupancy.occupiedBeds());
    }

    /**
     * What this property is charged for.
     *
     * <p>Counted the way the invoice will count it: a whole unit that is let,
     * and a bed that is let. A bedspace unit is never counted as an occupied
     * unit as well as its beds, or the landlord pays twice for one room.
     */
    private Occupancy occupancyOf(UUID propertyId) {
        BillableSlots.Count count = slots.of(propertyId);
        return new Occupancy(count.units(), count.beds());
    }

    private record Occupancy(int occupiedUnits, int occupiedBeds) {
    }
}
