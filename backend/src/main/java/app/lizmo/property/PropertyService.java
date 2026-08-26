package app.lizmo.property;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.property.dto.BedRequest;
import app.lizmo.property.dto.MaintenanceRequest;
import app.lizmo.property.dto.BedResponse;
import app.lizmo.property.dto.PropertyRequest;
import app.lizmo.property.dto.PropertyResponse;
import app.lizmo.property.dto.UnitRequest;
import app.lizmo.property.dto.UnitResponse;
import app.lizmo.property.dto.UtilityRequest;
import app.lizmo.property.dto.UtilityResponse;
import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Property, unit and bed management for a landlord.
 *
 * <p>Every method takes the caller's id and passes it through
 * {@link PropertyAccess}. Nothing here loads a property by id alone, which is
 * what keeps one landlord's portfolio out of another's reach.
 */
@Service
public class PropertyService {

    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;
    private final UnitUtilityRepository utilities;
    private final PropertyAccess access;

    public PropertyService(
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            UnitUtilityRepository utilities,
            PropertyAccess access) {
        this.properties = properties;
        this.units = units;
        this.beds = beds;
        this.utilities = utilities;
        this.access = access;
    }

    // ---------- Properties ----------

    @Transactional(readOnly = true)
    public List<PropertyResponse> listProperties(UUID userId) {
        return properties.findByLandlordIdOrderByNameAsc(userId).stream()
                .map(property -> PropertyResponse.of(property, units.countByPropertyId(property.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public PropertyResponse getProperty(UUID propertyId, UUID userId) {
        Property property = access.readable(propertyId, userId);
        return PropertyResponse.of(property, units.countByPropertyId(propertyId));
    }

    @Transactional
    public PropertyResponse createProperty(PropertyRequest request, UUID userId) {
        access.requireActiveLandlord(userId);

        requireTypeMatchesUsage(request);

        Property property = properties.save(new Property(
                userId, request.name().trim(), request.address().trim(),
                request.type(), request.usage()));

        return PropertyResponse.of(property, 0);
    }

    @Transactional
    public PropertyResponse updateProperty(UUID propertyId, PropertyRequest request, UUID userId) {
        Property property = access.writable(propertyId, userId);

        // A landlord may convert a property between residential and commercial —
        // it happens — so this is not locked the way a unit's rental mode is.
        // The type has to move with it, which the check below enforces.
        requireTypeMatchesUsage(request);

        // Commercial properties hold no bedspaces, and a unit's rental mode
        // cannot be changed after creation. Converting a property that still has
        // bedspace units would therefore strand them in a state the rest of the
        // system says is impossible, with no way for the landlord to fix it.
        if (request.usage() == PropertyUsage.COMMERCIAL
                && units.existsByPropertyIdAndRentalMode(propertyId, RentalMode.BEDSPACE)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This property has bedspace units, which a commercial property "
                            + "cannot hold. Delete them before converting it.");
        }

        property.update(request.name().trim(), request.address().trim(),
                request.type(), request.usage());
        return PropertyResponse.of(properties.save(property), units.countByPropertyId(propertyId));
    }

    /**
     * Rejects a type that does not belong to the chosen usage — a commercial
     * boarding house, say. The database enforces this too; checked here so the
     * caller gets a message naming both values instead of a constraint violation.
     */
    private void requireTypeMatchesUsage(PropertyRequest request) {
        if (!request.usage().allows(request.type())) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "%s is not a %s property type.".formatted(
                            request.type(), request.usage().name().toLowerCase()));
        }
    }

    /**
     * Refuses while the property still holds units.
     *
     * <p>A property is the root of leases, billing periods and payments. Deleting
     * one with units would either cascade that history away or leave it
     * orphaned, and both are worse than making the landlord clear it first.
     */
    @Transactional
    public void deleteProperty(UUID propertyId, UUID userId) {
        Property property = access.writable(propertyId, userId);

        if (units.countByPropertyId(propertyId) > 0) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Remove this property's units before deleting it.");
        }
        properties.delete(property);
    }

    // ---------- Units ----------

    /**
     * Builds a unit's response, deriving every bed-based figure from one read.
     *
     * <p>Three numbers came from three queries before; the beds have to be
     * loaded anyway to total their rents, so they now come from one.
     */
    private UnitResponse unitResponse(Unit unit) {
        // Out of service: nothing here can be let, so there is nothing to
        // total. Null rather than zero — the same distinction as an unset rent.
        boolean closed = unit.getStatus() == UnitStatus.MAINTENANCE;

        if (!unit.isBedspace()) {
            // One tenancy, so the unit's own rent is the whole of it.
            return UnitResponse.of(unit, 0, 0, closed ? null : unit.getRent(),
                    monthlyUtilities(unit.getId()));
        }

        List<Bed> unitBeds = beds.findByUnitIdOrderByBedLabelAsc(unit.getId());
        long maintenance = unitBeds.stream().filter(
                bed -> bed.getStatus() == BedStatus.MAINTENANCE).count();

        BigDecimal potential = null;
        for (Bed bed : unitBeds) {
            if (bed.getStatus() == BedStatus.MAINTENANCE) {
                continue;
            }
            // A bed with no rent of its own is let at the unit's rate.
            BigDecimal effective = bed.getRent() != null ? bed.getRent() : unit.getRent();
            if (effective == null) {
                // Nothing is known about this bed's price. It contributes
                // nothing rather than zero, which would be a claim.
                continue;
            }
            potential = potential == null ? effective : potential.add(effective);
        }

        return UnitResponse.of(unit, unitBeds.size(), maintenance,
                closed ? null : potential, monthlyUtilities(unit.getId()));
    }

    @Transactional(readOnly = true)
    public List<UnitResponse> listUnits(UUID propertyId, UUID userId) {
        access.readable(propertyId, userId);
        return units.findByPropertyIdOrderByUnitNumberAsc(propertyId).stream()
                .map(this::unitResponse)
                .toList();
    }

    @Transactional
    public UnitResponse createUnit(UUID propertyId, UnitRequest request, UUID userId) {
        Property property = access.writable(propertyId, userId);

        String unitNumber = request.unitNumber().trim();
        // Checked here as well as by the unique index, so the caller gets a
        // useful message instead of a constraint violation.
        if (units.existsByPropertyIdAndUnitNumberIgnoreCase(propertyId, unitNumber)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A unit with that number already exists in this property.");
        }

        // Bedspace is letting individual beds in a shared room, which a shop or a
        // warehouse cannot be. Coerced rather than refused, matching the way a
        // whole unit's capacity is forced to 1 whatever the caller sent: the
        // request is answerable, so answering it beats an error the landlord can
        // do nothing useful with.
        RentalMode mode = property.getUsage() == PropertyUsage.COMMERCIAL
                ? RentalMode.WHOLE_UNIT
                : request.rentalMode();

        int capacity = mode == RentalMode.WHOLE_UNIT ? 1 : request.effectiveCapacity();

        Unit unit = units.save(new Unit(
                propertyId,
                unitNumber,
                trimToNull(request.floor()),
                request.sizeSqm(),
                mode,
                capacity,
                request.rent()));

        // Capacity is the bed count — the form asks "How many beds?" — so the
        // beds are created with the unit rather than left as a second job the
        // landlord has to remember.
        int created = mode == RentalMode.BEDSPACE ? fillBedsTo(unit.getId(), capacity) : 0;

        return unitResponse(unit);
    }

    @Transactional(readOnly = true)
    public UnitResponse getUnit(UUID unitId, UUID userId) {
        Unit unit = requireReadableUnit(unitId, userId);
        return unitResponse(unit);
    }

    @Transactional
    public UnitResponse updateUnit(UUID unitId, UnitRequest request, UUID userId) {
        Unit unit = requireWritableUnit(unitId, userId);

        String unitNumber = request.unitNumber().trim();
        if (!unit.getUnitNumber().equalsIgnoreCase(unitNumber)
                && units.existsByPropertyIdAndUnitNumberIgnoreCase(unit.getPropertyId(), unitNumber)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A unit with that number already exists in this property.");
        }

        // Rental mode is not applied: it is fixed at creation.
        if (request.rentalMode() != unit.getRentalMode()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A unit's rental mode cannot be changed. Create a new unit instead.");
        }

        int capacity = request.effectiveCapacity();

        // Beds follow capacity rather than constraining it: the landlord sets
        // how many beds the room has, and the beds themselves are reconciled to
        // match. Lowering capacity therefore removes beds.
        if (unit.isBedspace()) {
            reconcileBeds(unitId, capacity);
        }

        unit.update(unitNumber, trimToNull(request.floor()), request.sizeSqm(),
                capacity, request.rent());
        return unitResponse(units.save(unit));
    }

    /**
     * Takes a whole unit out of service, or puts it back.
     *
     * <p>The unit-level counterpart of taking one bed out. A room being
     * repainted is not rentable however many beds it holds, and marking each
     * bed one at a time would be both tedious and easy to leave half done.
     *
     * <p>Refused while occupied, for the same reason a bed is: the tenant is
     * still there and still paying, so hiding the space from the rentable
     * count would make occupancy lie.
     */
    @Transactional
    public UnitResponse setUnitMaintenance(UUID unitId, boolean underMaintenance, UUID userId) {
        Unit unit = requireWritableUnit(unitId, userId);

        if (unit.getStatus() == UnitStatus.OCCUPIED
                || unit.getStatus() == UnitStatus.PARTIALLY_OCCUPIED) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This unit is occupied. End its leases before taking it out of service.");
        }

        unit.markMaintenance(underMaintenance);
        return unitResponse(units.save(unit));
    }

    @Transactional
    public void deleteUnit(UUID unitId, UUID userId) {
        Unit unit = requireWritableUnit(unitId, userId);

        // Beds are no longer something the landlord manages by hand — a bedspace
        // unit always has them — so refusing while any exist would make such a
        // unit undeletable. Only a live tenancy is a real obstacle.
        List<Bed> existing = beds.findByUnitIdOrderByBedLabelAsc(unitId);
        long occupied = existing.stream().filter(Bed::isOccupied).count();
        if (occupied > 0) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "%d of this unit's beds are occupied. End those leases before deleting it."
                            .formatted(occupied));
        }
        beds.deleteAll(existing);
        units.delete(unit);
    }

    // ---------- Utilities ----------

    /**
     * Every utility a unit could charge, whether or not it has been set up.
     *
     * <p>All three kinds come back every time, unconfigured ones included.
     * Returning only the rows that exist would leave the client to decide what
     * absence means, and a screen with three switches wants three answers.
     */
    @Transactional(readOnly = true)
    public List<UtilityResponse> listUtilities(UUID unitId, UUID userId) {
        requireReadableUnit(unitId, userId);
        return utilitiesFor(unitId);
    }

    /**
     * Applies utility settings to a unit.
     *
     * <p>Only the kinds named are touched, so a client may send one switch
     * without restating the others.
     */
    @Transactional
    public List<UtilityResponse> setUtilities(
            UUID unitId, List<UtilityRequest> requests, UUID userId) {
        requireWritableUnit(unitId, userId);

        for (UtilityRequest request : requests) {
            UnitUtility utility = utilities.findByUnitIdAndKind(unitId, request.kind())
                    .orElseGet(() -> new UnitUtility(unitId, request.kind()));

            // Switching one on without ever saying what it costs would store a
            // charge of nothing, which the database refuses anyway.
            if (request.enabled() && request.amount() == null && utility.getAmount() == null) {
                throw new ApiException(ErrorCode.VALIDATION_FAILED,
                        "Set an amount for %s before switching it on."
                                .formatted(request.kind().name().toLowerCase(Locale.ROOT)));
            }

            utility.set(request.enabled(), request.amount());
            utilities.save(utility);
        }

        return utilitiesFor(unitId);
    }

    private List<UtilityResponse> utilitiesFor(UUID unitId) {
        List<UnitUtility> configured = utilities.findByUnitIdOrderByKindAsc(unitId);
        return Arrays.stream(UtilityKind.values())
                .map(kind -> configured.stream()
                        .filter(utility -> utility.getKind() == kind)
                        .findFirst()
                        .map(UtilityResponse::of)
                        .orElseGet(() -> UtilityResponse.unset(kind)))
                .toList();
    }

    /** What a unit's switched-on utilities add to a month, or null if none are. */
    private BigDecimal monthlyUtilities(UUID unitId) {
        BigDecimal total = utilities.findByUnitIdOrderByKindAsc(unitId).stream()
                .map(UnitUtility::monthlyAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        // Null rather than zero, as everywhere else money is reported: nothing
        // switched on is not the same statement as a charge of nothing.
        return total.signum() == 0 ? null : total;
    }

    // ---------- Beds ----------

    @Transactional(readOnly = true)
    public List<BedResponse> listBeds(UUID unitId, UUID userId) {
        requireReadableUnit(unitId, userId);
        return beds.findByUnitIdOrderByBedLabelAsc(unitId).stream().map(BedResponse::of).toList();
    }

    @Transactional
    public BedResponse createBed(UUID unitId, BedRequest request, UUID userId) {
        Unit unit = requireWritableUnit(unitId, userId);

        // A bed in a whole unit has no meaning: the unit itself is the lettable
        // thing, and a lease against it would compete with the unit's own.
        if (!unit.isBedspace()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Beds can only be added to bedspace units.");
        }

        String label = request.bedLabel().trim();
        if (beds.existsByUnitIdAndBedLabelIgnoreCase(unitId, label)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A bed with that label already exists in this unit.");
        }

        Bed bed = new Bed(unitId, label);
        bed.update(label, request.rent());
        Bed created = beds.save(bed);

        // Capacity is the bed count, so adding a bed raises it rather than being
        // refused for exceeding it. Without this the two could disagree, and
        // the next edit of the unit would silently delete the bed again.
        syncCapacityToBeds(unit);

        return BedResponse.of(created);
    }

    /**
     * Renames a bed.
     *
     * <p>Labels are generated as "Bed 1", "Bed 2" and so on, which is enough to
     * tell them apart but says nothing useful about the room. A landlord who
     * lets bunks knows the difference between the upper and the lower one, and
     * so does the tenant paying for it.
     */
    @Transactional
    public BedResponse updateBed(UUID bedId, BedRequest request, UUID userId) {
        Bed bed = beds.findById(bedId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such bed."));
        requireWritableUnit(bed.getUnitId(), userId);

        String label = request.bedLabel().trim();

        // Compared against the current label first, so saving a bed without
        // changing its name is not treated as a clash with itself.
        if (!bed.getBedLabel().equalsIgnoreCase(label)
                && beds.existsByUnitIdAndBedLabelIgnoreCase(bed.getUnitId(), label)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A bed with that label already exists in this unit.");
        }

        // Label and rent are the two things a landlord edits about a bed, so
        // they move together: a PUT carries the whole bed, and omitting the
        // rent means it is let at the unit's rate again.
        bed.update(label, request.rent());
        return BedResponse.of(beds.save(bed));
    }

    /**
     * Takes a bed out of service, or puts it back.
     *
     * <p>Independent of tenancy: a landlord fixing a broken bunk has not ended
     * anyone's lease. An occupied bed is refused all the same — the tenant is
     * still there and still paying, and hiding the bed from the rentable count
     * while that is true would make occupancy lie.
     */
    @Transactional
    public BedResponse setBedMaintenance(UUID bedId, boolean underMaintenance, UUID userId) {
        Bed bed = beds.findById(bedId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such bed."));
        requireWritableUnit(bed.getUnitId(), userId);

        // Checked here so the caller gets a message. Bed.markMaintenance guards
        // the same rule, but as an IllegalStateException — a 500, not an answer.
        if (bed.isOccupied()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This bed is occupied. End the lease before taking it out of service.");
        }

        bed.markMaintenance(underMaintenance);
        return BedResponse.of(beds.save(bed));
    }

    @Transactional
    public void deleteBed(UUID bedId, UUID userId) {
        Bed bed = beds.findById(bedId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such bed."));
        Unit unit = requireWritableUnit(bed.getUnitId(), userId);

        // An occupied bed has a live lease behind it; deleting it would strand
        // that tenant's billing history.
        if (bed.isOccupied()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This bed is occupied. End the lease before removing it.");
        }
        beds.delete(bed);

        // The unit is one bed smaller, so its capacity is too.
        syncCapacityToBeds(unit);
    }

    /**
     * Pulls a unit's capacity to whatever its bed count now is.
     *
     * <p>Only for the endpoints that change beds directly. Capacity and bed
     * count are two views of the same number, so whichever end the landlord
     * moves, the other follows.
     */
    private void syncCapacityToBeds(Unit unit) {
        long count = beds.countByUnitId(unit.getId());
        // A unit holds at least one lettable space even with no beds set up.
        int capacity = (int) Math.max(1, count);

        if (unit.isBedspace() && unit.getCapacity() != capacity) {
            unit.update(unit.getUnitNumber(), unit.getFloor(), unit.getSizeSqm(),
                    capacity, unit.getRent());
            units.save(unit);
        }
    }

    // ---------- Bed reconciliation ----------

    /**
     * Brings a unit's beds to exactly {@code capacity}, and returns how many it
     * ends up with.
     *
     * <p>Growing adds beds; shrinking removes them. Occupied beds are never
     * removed — a live lease sits behind each one — so shrinking below the
     * number occupied is refused rather than partially applied.
     */
    private long reconcileBeds(UUID unitId, int capacity) {
        List<Bed> existing = beds.findByUnitIdOrderByBedLabelAsc(unitId);

        if (existing.size() == capacity) {
            return capacity;
        }

        if (existing.size() < capacity) {
            fillBedsTo(unitId, capacity);
            return capacity;
        }

        // Shrinking. Only vacant beds can go, and still-default names go before
        // renamed ones: a landlord who bothered to call a bed "Upper bunk" has
        // told us it matters, where "Bed 4" is just the number we gave it.
        // Within the defaults, the highest number goes first.
        List<Bed> removable = existing.stream()
                .filter(bed -> !bed.isOccupied())
                .sorted(Comparator
                        .comparing((Bed bed) -> defaultLabelNumber(bed.getBedLabel()) == null)
                        .thenComparing(
                                bed -> defaultLabelNumber(bed.getBedLabel()),
                                Comparator.nullsLast(Comparator.reverseOrder()))
                        .thenComparing(Comparator.comparing(Bed::getBedLabel).reversed()))
                .toList();

        int surplus = existing.size() - capacity;
        if (removable.size() < surplus) {
            long occupied = existing.size() - removable.size();
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    ("%d of this unit's beds are occupied, so it cannot hold fewer than %d. "
                            + "End those leases first.").formatted(occupied, occupied));
        }

        beds.deleteAll(removable.subList(0, surplus));
        return capacity;
    }

    /**
     * The number in a still-default "Bed 7" label, or null if it has been
     * renamed to anything else.
     */
    private static Integer defaultLabelNumber(String label) {
        var matcher = DEFAULT_LABEL.matcher(label.trim());
        return matcher.matches() ? Integer.valueOf(matcher.group(1)) : null;
    }

    private static final Pattern DEFAULT_LABEL =
            Pattern.compile("(?i)bed\\s+(\\d{1,9})");

    /**
     * Adds beds until the unit has {@code target} of them, and returns how many
     * it now has.
     *
     * <p>Labels are "Bed 1", "Bed 2" and so on, skipping any number already
     * taken — the unique index is case-insensitive, and a unit that has been
     * resized more than once can have gaps.
     */
    private int fillBedsTo(UUID unitId, int target) {
        Set<String> taken = beds.findByUnitIdOrderByBedLabelAsc(unitId).stream()
                .map(bed -> bed.getBedLabel().toLowerCase(Locale.ROOT))
                .collect(Collectors.toSet());

        int next = 1;
        while (taken.size() < target) {
            String label = "Bed " + next++;
            if (taken.add(label.toLowerCase(Locale.ROOT))) {
                beds.save(new Bed(unitId, label));
            }
        }
        return target;
    }

    // ---------- Shared ----------

    /**
     * A unit the caller may read, resolved through its property's owner.
     *
     * <p>Units carry no landlord id of their own, so authorisation always hops
     * via the property. Returning 404 rather than 403 for someone else's unit
     * avoids confirming that it exists.
     */
    private Unit requireReadableUnit(UUID unitId, UUID userId) {
        Unit unit = units.findById(unitId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such unit."));
        access.readable(unit.getPropertyId(), userId);
        return unit;
    }

    private Unit requireWritableUnit(UUID unitId, UUID userId) {
        Unit unit = units.findById(unitId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such unit."));
        access.writable(unit.getPropertyId(), userId);
        return unit;
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
