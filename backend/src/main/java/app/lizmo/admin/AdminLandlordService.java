package app.lizmo.admin;

import app.lizmo.admin.dto.AdminPropertySummary;
import app.lizmo.admin.dto.LandlordDetail;
import app.lizmo.admin.dto.LandlordSummary;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
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
 * <p>Deliberately narrow about people. An admin sees how many slots a property
 * has occupied, because that is what Lizmo bills for, and never who occupies
 * them: a tenant's name, ID photograph and emergency contact are between them
 * and their landlord. Nothing here joins through to a tenant.
 */
@Service
public class AdminLandlordService {

    private final LandlordProfileRepository landlords;
    private final UserRepository users;
    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;
    private final BillableSlots slots;

    public AdminLandlordService(
            LandlordProfileRepository landlords,
            UserRepository users,
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            BillableSlots slots) {
        this.landlords = landlords;
        this.users = users;
        this.properties = properties;
        this.units = units;
        this.beds = beds;
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
