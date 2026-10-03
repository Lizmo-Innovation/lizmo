package app.lizmo.property;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.property.dto.PropertyByCodeResponse;
import app.lizmo.property.dto.VacancyFloor;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Finding a property by the code on the gate, and seeing what is free in it.
 *
 * <p>Serves a signed-in person who has no relationship to the landlord, so
 * everything here is deliberately narrow: what is vacant, what it costs, and
 * nothing about the parts already let or what the building earns.
 */
@Service
public class PropertyDiscoveryService {

    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;
    private final UnitUtilityRepository utilities;

    public PropertyDiscoveryService(
            PropertyRepository properties,
            UnitRepository units,
            BedRepository beds,
            UnitUtilityRepository utilities) {
        this.properties = properties;
        this.units = units;
        this.beds = beds;
        this.utilities = utilities;
    }

    @Transactional(readOnly = true)
    public PropertyByCodeResponse findByCode(String typed) {
        String code = PropertyCodes.normalise(typed);
        if (code == null) {
            throw notFound();
        }
        Property property = properties.findByCode(code).orElseThrow(
                PropertyDiscoveryService::notFound);

        return PropertyByCodeResponse.of(property, vacanciesIn(property.getId()));
    }

    /**
     * What is free, grouped by floor.
     *
     * <p>A unit appears in one list or the other, never both: a whole unit is
     * let entire, a bedspace unit is let bed by bed, and the unit's rental mode
     * is what decides which question a tenant is even being asked.
     */
    private List<VacancyFloor> vacanciesIn(UUID propertyId) {
        Map<String, Tally> byFloor = new LinkedHashMap<>();

        for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(propertyId)) {
            // Out of service is not on offer. A room being repainted should not
            // bring somebody across town to look at it.
            if (unit.getStatus() == UnitStatus.MAINTENANCE) {
                continue;
            }

            String floor = unit.getFloor();
            BigDecimal monthlyUtilities = monthlyUtilities(unit.getId());
            boolean included = unit.getUtilityBilling() == UtilityBilling.COMBINED;

            boolean onTop = !included
                    && monthlyUtilities != null
                    && monthlyUtilities.signum() > 0;

            if (unit.getRentalMode() == RentalMode.WHOLE_UNIT) {
                if (unit.getStatus() != UnitStatus.VACANT) {
                    continue;
                }
                byFloor.computeIfAbsent(floor, key -> new Tally())
                        .wholeUnit(unit.getRent(), onTop);
                continue;
            }

            // A bedspace unit is never offered whole, even when every bed in it
            // is free — the landlord chose to let it bed by bed.
            for (Bed bed : beds.findByUnitIdOrderByBedLabelAsc(unit.getId())) {
                if (bed.getStatus() != BedStatus.VACANT) {
                    continue;
                }
                byFloor.computeIfAbsent(floor, key -> new Tally())
                        // A bed with no price of its own asks its unit's.
                        // Null would read as free to anyone who does not know
                        // the fallback rule.
                        .bed(bed.getRent() != null ? bed.getRent() : unit.getRent(), onTop);
            }
        }

        List<String> floors = new ArrayList<>(byFloor.keySet());
        floors.sort(floorOrder());

        List<VacancyFloor> grouped = new ArrayList<>();
        for (String floor : floors) {
            Tally tally = byFloor.get(floor);
            if (tally.vacantCount() == 0) {
                continue;
            }
            grouped.add(tally.on(floor));
        }
        return grouped;
    }

    /** What is free on one floor, while it is being counted. */
    private static final class Tally {
        private int wholeUnits;
        private int beds;
        private BigDecimal cheapest;
        private BigDecimal dearest;
        private boolean utilitiesOnTop;

        void wholeUnit(BigDecimal rent, boolean onTop) {
            wholeUnits++;
            price(rent, onTop);
        }

        void bed(BigDecimal rent, boolean onTop) {
            beds++;
            price(rent, onTop);
        }

        private void price(BigDecimal rent, boolean onTop) {
            utilitiesOnTop |= onTop;
            if (rent == null) {
                return;
            }
            cheapest = cheapest == null || rent.compareTo(cheapest) < 0 ? rent : cheapest;
            dearest = dearest == null || rent.compareTo(dearest) > 0 ? rent : dearest;
        }

        int vacantCount() {
            return wholeUnits + beds;
        }

        VacancyFloor on(String floor) {
            return new VacancyFloor(floor, wholeUnits, beds, cheapest, dearest, utilitiesOnTop);
        }
    }

    /**
     * Numbered floors in numeric order, then everything else alphabetically,
     * then the ones with no floor at all.
     *
     * <p>Sorting these as strings puts floor 10 between 1 and 2, which reads as
     * a bug to anyone with a ten-storey building — and named floors like
     * "Ground" and "Mezzanine" have to go somewhere sensible rather than
     * wherever the alphabet drops them.
     */
    private static Comparator<String> floorOrder() {
        return Comparator
                .comparingInt((String floor) -> floor == null ? 2 : (isNumeric(floor) ? 0 : 1))
                .thenComparingInt(floor -> isNumeric(floor) ? Integer.parseInt(floor.trim()) : 0)
                .thenComparing(floor -> floor == null ? "" : floor);
    }

    private static boolean isNumeric(String floor) {
        if (floor == null) {
            return false;
        }
        String trimmed = floor.trim();
        if (trimmed.isEmpty() || trimmed.length() > 3) {
            return false;
        }
        return trimmed.chars().allMatch(Character::isDigit);
    }

    /** What a unit's switched-on utilities add to a month, or null if none are. */
    private BigDecimal monthlyUtilities(UUID unitId) {
        BigDecimal total = utilities.findByUnitIdOrderByKindAsc(unitId).stream()
                .map(UnitUtility::monthlyAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return total.signum() == 0 ? null : total;
    }

    /**
     * The same answer for a malformed code, an unused one, and one that is
     * merely someone else's. Saying "that code is not in use" would turn this
     * endpoint into a way to test codes one at a time and learn which exist.
     */
    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No property uses that code.");
    }
}
