package app.lizmo.property;

import app.lizmo.property.dto.OccupancySummary;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * What is let, what is empty, and what the empty part is costing.
 *
 * <p>Counted in lettable slots, not units. A whole-unit rental is one slot; a
 * four-bed room is four. Counting units would tell a landlord with one tenant
 * in a four-bed room that their building was fully occupied.
 *
 * <p>Read from bed and unit status rather than from leases, deliberately.
 * Status is what the vacancy screens already show and what accepting or ending
 * a tenancy maintains, so occupancy on the dashboard cannot disagree with the
 * room list a landlord looks at next.
 */
@Service
public class OccupancyService {

    private final PropertyRepository properties;
    private final UnitRepository units;
    private final BedRepository beds;

    public OccupancyService(
            PropertyRepository properties, UnitRepository units, BedRepository beds) {
        this.properties = properties;
        this.units = units;
        this.beds = beds;
    }

    @Transactional(readOnly = true)
    public OccupancySummary forLandlord(UUID landlordId) {
        int lettable = 0;
        int occupied = 0;
        int empty = 0;
        int outOfService = 0;
        BigDecimal earning = BigDecimal.ZERO;
        BigDecimal idle = BigDecimal.ZERO;
        List<OccupancySummary.VacancyRow> rows = new ArrayList<>();

        for (Property property : properties.findByLandlordIdOrderByNameAsc(landlordId)) {
            Tally tally = new Tally();

            for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(property.getId())) {
                if (unit.getRentalMode() == RentalMode.BEDSPACE) {
                    countBeds(unit, tally);
                } else {
                    countWholeUnit(unit, tally);
                }
            }

            lettable += tally.lettable;
            occupied += tally.occupied;
            empty += tally.empty;
            outOfService += tally.outOfService;
            earning = earning.add(tally.earning);
            idle = idle.add(tally.idle);

            // Only properties with something free. A landlord scanning this is
            // looking for what to do next, and a list of full buildings is not
            // an answer to that.
            if (tally.empty > 0) {
                rows.add(new OccupancySummary.VacancyRow(
                        property.getId(),
                        property.getName(),
                        tally.lettable,
                        tally.occupied,
                        tally.empty,
                        tally.idle));
            }
        }

        // Most empty money first: that is the property costing the most to
        // leave alone.
        rows.sort(Comparator.comparing(
                OccupancySummary.VacancyRow::emptyRent, Comparator.reverseOrder()));

        return new OccupancySummary(
                lettable, occupied, empty, outOfService, earning, idle, rows);
    }

    /**
     * A room let by the bed.
     *
     * <p>The unit's own status is ignored here -- it is a roll-up of its beds,
     * and counting both would double what the room contributes.
     */
    private void countBeds(Unit unit, Tally tally) {
        for (Bed bed : beds.findByUnitIdOrderByBedLabelAsc(unit.getId())) {
            // A bed's own rent when it has one, otherwise the room's. The same
            // fallback the accept screen uses, so the figure a landlord sees
            // here is the one they would actually charge.
            BigDecimal rent = bed.getRent() == null ? unit.getRent() : bed.getRent();
            rent = rent == null ? BigDecimal.ZERO : rent;

            switch (bed.getStatus()) {
                case OCCUPIED -> {
                    tally.lettable++;
                    tally.occupied++;
                    tally.earning = tally.earning.add(rent);
                }
                case VACANT -> {
                    tally.lettable++;
                    tally.empty++;
                    tally.idle = tally.idle.add(rent);
                }
                // Off the market on purpose. Not a vacancy anybody needs to
                // fill, and not lettable while it is out.
                case MAINTENANCE -> tally.outOfService++;
            }
        }
    }

    /** A place let whole. One slot, however many rooms are in it. */
    private void countWholeUnit(Unit unit, Tally tally) {
        BigDecimal rent = unit.getRent() == null ? BigDecimal.ZERO : unit.getRent();

        switch (unit.getStatus()) {
            case OCCUPIED, PARTIALLY_OCCUPIED -> {
                tally.lettable++;
                tally.occupied++;
                tally.earning = tally.earning.add(rent);
            }
            case VACANT -> {
                tally.lettable++;
                tally.empty++;
                tally.idle = tally.idle.add(rent);
            }
            case MAINTENANCE -> tally.outOfService++;
        }
    }

    /** Running totals for one property. */
    private static final class Tally {
        int lettable;
        int occupied;
        int empty;
        int outOfService;
        BigDecimal earning = BigDecimal.ZERO;
        BigDecimal idle = BigDecimal.ZERO;
    }
}
