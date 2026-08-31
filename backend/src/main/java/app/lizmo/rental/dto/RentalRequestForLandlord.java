package app.lizmo.rental.dto;

import app.lizmo.rental.RentalRequest;
import app.lizmo.rental.RentalRequestStatus;
import app.lizmo.user.IdType;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.User;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * A request as the landlord deciding on it sees it.
 *
 * <p>Carries enough to judge a stranger and no more. Ariel's call, and worth
 * restating because it is the whole shape of this record: the ID <em>type</em>
 * is here, the ID <em>number</em> and both photographs are not. They unlock on
 * acceptance.
 *
 * <p>The reason is that anyone can create a property, generate a code, and
 * collect whatever a request carries. A tenant consents by sending, so this is
 * not a leak — but a fake listing should harvest as little as possible, and a
 * landlord who genuinely needs to see a face can accept and then look.
 *
 * @param tenantName who they are, from the account rather than the profile: a
 *                   landlord recognises a person by name, and it is the one
 *                   thing every account has.
 * @param idType what they carry, without the number. Enough to know a lease can
 *               be signed against it.
 */
@Schema(description = "A request waiting on the landlord")
public record RentalRequestForLandlord(
        UUID id,
        UUID propertyId,
        UUID unitId,
        String unitNumber,
        UUID bedId,
        String bedLabel,
        RentalRequestStatus status,
        Instant createdAt,
        Instant decidedAt,

        UUID tenantId,
        String tenantName,
        String tenantPhone,
        LocalDate birthdate,
        String occupation,
        String permanentAddress,
        String emergencyContactName,
        String emergencyContactRelationship,
        String emergencyContactPhone,
        IdType idType) {

    public static RentalRequestForLandlord of(
            RentalRequest request,
            User tenant,
            TenantProfile profile,
            String unitNumber,
            String bedLabel) {
        return new RentalRequestForLandlord(
                request.getId(),
                request.getPropertyId(),
                request.getUnitId(),
                unitNumber,
                request.getBedId(),
                bedLabel,
                request.getStatus(),
                request.getCreatedAt(),
                request.getDecidedAt(),
                request.getTenantId(),
                tenant == null ? null : tenant.getName(),
                // How the landlord will actually reach them to arrange a
                // viewing. Withheld would make the request unanswerable except
                // through the app.
                tenant == null ? null : tenant.getPhone(),
                profile == null ? null : profile.getBirthdate(),
                profile == null ? null : profile.getOccupation(),
                profile == null ? null : profile.getPermanentAddress(),
                profile == null ? null : profile.getEmergencyContactName(),
                profile == null ? null : profile.getEmergencyContactRelationship(),
                profile == null ? null : profile.getEmergencyContactPhone(),
                profile == null ? null : profile.getIdType());
    }
}
