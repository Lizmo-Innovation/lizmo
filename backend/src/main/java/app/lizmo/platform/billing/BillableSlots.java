package app.lizmo.platform.billing;

import app.lizmo.property.Bed;
import app.lizmo.property.BedRepository;
import app.lizmo.property.BedStatus;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import app.lizmo.property.UnitStatus;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * What a property is charged for: the whole units that are let, and the beds.
 *
 * <p>One place, used by the invoice and by the admin console's counts, so the
 * number an admin sees beside a landlord's name is the number that landlord is
 * billed for. It was a private method on the console's service; an invoice
 * counting it separately would have been a second answer waiting to drift.
 *
 * <p>A bedspace unit is never counted as an occupied unit as well as its beds,
 * or the landlord pays twice for one room.
 */
@Component
public class BillableSlots {

    private final UnitRepository units;
    private final BedRepository beds;

    public BillableSlots(UnitRepository units, BedRepository beds) {
        this.units = units;
        this.beds = beds;
    }

    /** Let whole units, and let beds. */
    public record Count(int units, int beds) {

        public boolean isEmpty() {
            return units == 0 && beds == 0;
        }
    }

    public Count of(UUID propertyId) {
        int occupiedUnits = 0;
        int occupiedBeds = 0;

        for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(propertyId)) {
            List<Bed> unitBeds = beds.findByUnitIdOrderByBedLabelAsc(unit.getId());
            if (unitBeds.isEmpty()) {
                if (unit.getStatus() == UnitStatus.OCCUPIED) {
                    occupiedUnits++;
                }
            } else {
                occupiedBeds += (int) unitBeds.stream()
                        .filter(bed -> bed.getStatus() == BedStatus.OCCUPIED)
                        .count();
            }
        }
        return new Count(occupiedUnits, occupiedBeds);
    }
}
