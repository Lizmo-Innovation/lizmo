package app.lizmo.rental.dto;

import app.lizmo.rental.RentalRequest;
import app.lizmo.rental.RentalRequestStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

/**
 * A request as the tenant who sent it sees it.
 *
 * <p>Carries the names of the place, not only its ids: a tenant who has asked
 * about three rooms in two buildings needs to tell them apart, and should not
 * have to fetch each property to do it.
 */
@Schema(description = "A request a tenant has sent")
public record RentalRequestResponse(
        UUID id,
        UUID propertyId,
        String propertyName,
        UUID unitId,
        String unitNumber,
        UUID bedId,
        String bedLabel,
        RentalRequestStatus status,
        Instant createdAt,
        Instant decidedAt) {

    public static RentalRequestResponse of(
            RentalRequest request, String propertyName, String unitNumber, String bedLabel) {
        return new RentalRequestResponse(
                request.getId(),
                request.getPropertyId(),
                propertyName,
                request.getUnitId(),
                unitNumber,
                request.getBedId(),
                bedLabel,
                request.getStatus(),
                request.getCreatedAt(),
                request.getDecidedAt());
    }
}
