package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;

/**
 * How much is free on one floor, and what it costs.
 *
 * <p>Counts rather than rooms. A stranger with the code used to be handed the
 * whole list -- every unit number, every bed label, each one's rent -- which is
 * more than anybody needs to decide whether to ask, and is the landlord's
 * business rather than a passer-by's. Which room they get is settled between
 * the two of them, and written down when the landlord accepts.
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
 * @param wholeUnits how many whole units are free here.
 * @param beds how many bedspaces are free here.
 * @param cheapestRent the least any free room here asks, and {@code dearestRent}
 *                     the most. Equal when there is one price, which is the
 *                     usual case for a floor of identical beds.
 * @param utilitiesOnTop whether any free room here charges its utilities
 *                       separately, so the rent shown is not the whole of what
 *                       a tenant will hand over each month.
 */
@Schema(description = "How much is free on one floor, and what it costs")
public record VacancyFloor(
        String floor,
        int wholeUnits,
        int beds,
        BigDecimal cheapestRent,
        BigDecimal dearestRent,
        boolean utilitiesOnTop) {

    /** So a screen can show "3 free" without adding the two itself. */
    public int vacantCount() {
        return wholeUnits + beds;
    }
}
