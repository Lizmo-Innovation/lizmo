package app.lizmo.admin.dto;

import app.lizmo.property.PropertyType;
import app.lizmo.property.PropertyUsage;
import app.lizmo.property.RentalMode;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * One property as Lizmo's staff see it: every unit and bed, and who leases
 * which right now.
 *
 * @param leased       whole units and beds with a tenancy running now. Counted
 *                     the way a statement bills, so it matches the landlord
 *                     page's occupied figures.
 * @param outOfService whole units and beds taken out of letting, with nobody in
 *                     them.
 */
@Schema(description = "A property's units, beds and current tenancies, for Lizmo's staff")
public record AdminPropertyDetail(
        UUID id,
        String name,
        String address,
        PropertyType type,
        PropertyUsage usage,
        String code,
        String accountStatus,
        UUID landlordId,
        String landlordName,
        int unitCount,
        int bedCount,
        int leased,
        int outOfService,
        List<Unit> units) {

    /**
     * Where a unit or bed stands.
     *
     * <p>PARTLY_LEASED is only ever a bedspace unit: some beds taken, some not,
     * which "vacant" would misreport.
     */
    public enum Occupancy {
        LEASED,
        PARTLY_LEASED,
        VACANT,
        OUT_OF_SERVICE
    }

    /**
     * One unit.
     *
     * @param tenancy who leases it, for a whole unit. Null for a bedspace unit,
     *                whose tenancies are on its beds, and for anything empty.
     */
    @Schema(name = "AdminPropertyUnit", description = "A unit, and its beds when it is a bedspace")
    public record Unit(
            UUID id,
            String unitNumber,
            String floor,
            RentalMode rentalMode,
            int capacity,
            BigDecimal rent,
            Occupancy occupancy,
            Tenancy tenancy,
            List<Bed> beds) {
    }

    @Schema(name = "AdminPropertyBed", description = "A bed in a bedspace unit")
    public record Bed(
            UUID id,
            String label,
            BigDecimal rent,
            Occupancy occupancy,
            Tenancy tenancy) {
    }

    /**
     * The tenancy running on a unit or bed now, and how to reach the tenant.
     *
     * <p>Name and contact only, by decision: never their ID photographs, their
     * emergency contact or anything else from their profile.
     */
    @Schema(name = "AdminPropertyTenancy", description = "A tenancy running now")
    public record Tenancy(
            UUID leaseId,
            String tenantName,
            String tenantPhone,
            String tenantEmail,
            LocalDate startDate,
            LocalDate endDate,
            BigDecimal rent) {
    }
}
