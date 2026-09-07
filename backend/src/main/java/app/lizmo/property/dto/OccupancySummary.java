package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.util.List;

/**
 * How much of a portfolio is earning, and how much is standing empty.
 *
 * <p>Counted in lettable slots rather than in units, because a boarding house
 * does not let units. A four-bed room with one tenant is one slot let and three
 * empty; calling that "one unit occupied" would tell a landlord their building
 * was full.
 *
 * <p>Out-of-service slots are counted apart from empty ones. A bed a landlord
 * has taken off the market on purpose is not a vacancy they need to fill, and
 * folding the two together would make a refurbishment look like a failure to
 * let.
 *
 * @param emptyRent what the empty slots would bring in at their asking price.
 *                  The figure that turns "three beds free" into a reason to do
 *                  something about it.
 */
@Schema(description = "How much of a portfolio is let")
public record OccupancySummary(
        int lettable,
        int occupied,
        int empty,
        int outOfService,
        BigDecimal earningRent,
        BigDecimal emptyRent,
        List<VacancyRow> vacancies) {

    /**
     * One property, and how it is doing.
     *
     * <p>Per property rather than one number for everything: a landlord with a
     * full boarding house and an empty apartment block is not "half let", they
     * have one problem in one place.
     */
    @Schema(description = "Vacancy in one property")
    public record VacancyRow(
            java.util.UUID propertyId,
            String propertyName,
            int lettable,
            int occupied,
            int empty,
            BigDecimal emptyRent) {
    }
}
