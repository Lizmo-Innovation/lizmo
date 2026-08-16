package app.lizmo.property;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.property.dto.BedRequest;
import app.lizmo.property.dto.BedResponse;
import app.lizmo.property.dto.PropertyRequest;
import app.lizmo.property.dto.PropertyResponse;
import app.lizmo.property.dto.UnitRequest;
import app.lizmo.property.dto.UnitResponse;
import java.util.List;
import java.util.UUID;
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
    private final PropertyAccess access;

    public PropertyService(
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            PropertyAccess access) {
        this.properties = properties;
        this.units = units;
        this.beds = beds;
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

    @Transactional(readOnly = true)
    public List<UnitResponse> listUnits(UUID propertyId, UUID userId) {
        access.readable(propertyId, userId);
        return units.findByPropertyIdOrderByUnitNumberAsc(propertyId).stream()
                .map(unit -> UnitResponse.of(unit, beds.countByUnitId(unit.getId())))
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

        return UnitResponse.of(unit, 0);
    }

    @Transactional(readOnly = true)
    public UnitResponse getUnit(UUID unitId, UUID userId) {
        Unit unit = requireReadableUnit(unitId, userId);
        return UnitResponse.of(unit, beds.countByUnitId(unitId));
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

        long bedCount = beds.countByUnitId(unitId);
        if (unit.isBedspace() && request.effectiveCapacity() < bedCount) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Capacity cannot be lower than the %d beds already defined.".formatted(bedCount));
        }

        unit.update(unitNumber, trimToNull(request.floor()), request.sizeSqm(),
                request.effectiveCapacity(), request.rent());
        return UnitResponse.of(units.save(unit), bedCount);
    }

    @Transactional
    public void deleteUnit(UUID unitId, UUID userId) {
        Unit unit = requireWritableUnit(unitId, userId);

        if (beds.countByUnitId(unitId) > 0) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Remove this unit's beds before deleting it.");
        }
        units.delete(unit);
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

        if (beds.countByUnitId(unitId) >= unit.getCapacity()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This unit's capacity is %d. Raise it before adding another bed."
                            .formatted(unit.getCapacity()));
        }

        return BedResponse.of(beds.save(new Bed(unitId, label)));
    }

    @Transactional
    public void deleteBed(UUID bedId, UUID userId) {
        Bed bed = beds.findById(bedId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such bed."));
        requireWritableUnit(bed.getUnitId(), userId);

        // An occupied bed has a live lease behind it; deleting it would strand
        // that tenant's billing history.
        if (bed.isOccupied()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "This bed is occupied. End the lease before removing it.");
        }
        beds.delete(bed);
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
