package app.lizmo.lease.dto;

import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * A lease, as both sides see it.
 *
 * @param dueDateDay day of the month rent falls due. A 31 here is legitimate
 *                   and is clamped when a billing period is generated.
 */
@Schema(description = "A tenant attached to a bed or a unit")
public record LeaseResponse(
        UUID id,
        UUID tenantId,
        String tenantName,
        UUID propertyId,
        String propertyName,
        UUID unitId,
        String unitNumber,
        UUID bedId,
        String bedLabel,
        BigDecimal rentAmount,

        /* Two different kinds of money. See the Lease entity. */
        BigDecimal depositAmount,
        BigDecimal advanceAmount,
        BigDecimal depositReturned,
        String depositSettlement,

        short dueDateDay,
        LocalDate startDate,
        LocalDate endDate,
        LeaseStatus status,

        /* When it is meant to end, if it was agreed for a term. Not endDate,
           which is when it did. */
        LocalDate termEndsOn) {

    public static LeaseResponse of(
            Lease lease,
            String tenantName,
            UUID propertyId,
            String propertyName,
            String unitNumber,
            String bedLabel) {
        return new LeaseResponse(
                lease.getId(),
                lease.getTenantId(),
                tenantName,
                propertyId,
                propertyName,
                lease.getUnitId(),
                unitNumber,
                lease.getBedId(),
                bedLabel,
                lease.getRentAmount(),
                lease.getDepositAmount(),
                lease.getAdvanceAmount(),
                lease.getDepositReturned(),
                lease.getDepositSettlement(),
                lease.getDueDateDay(),
                lease.getStartDate(),
                lease.getEndDate(),
                lease.getStatus(),
                lease.getTermEndsOn());
    }
}
