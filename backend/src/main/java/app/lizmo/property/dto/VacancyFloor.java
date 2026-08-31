package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

/**
 * What is free on one floor.
 *
 * <p>The floor is the grouping rather than a filter because "is there anything
 * on the second floor?" is the question people actually ask in a boarding
 * house.
 *
 * <p>A top-level record rather than one nested in a container, because springdoc
 * flattens nested records to their simple name — this would have entered the
 * shared schema namespace, and the generated client, as "Floor".
 *
 * @param floor as the landlord wrote it — "2", "Ground", "Mezzanine". Null when
 *              they never said, which is normal for a single-storey house and
 *              is shown last rather than as floor zero.
 */
@Schema(description = "What is free on one floor")
public record VacancyFloor(
        String floor,
        List<VacantUnit> wholeUnits,
        List<VacantBed> bedspaces) {

    /** So a screen can show "3 free" without counting the lists itself. */
    public int vacantCount() {
        return wholeUnits.size() + bedspaces.size();
    }
}
