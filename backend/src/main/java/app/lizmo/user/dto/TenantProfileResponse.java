package app.lizmo.user.dto;

import app.lizmo.user.IdType;
import app.lizmo.user.TenantProfile;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

/**
 * @param readyForALease whether the profile carries what a lease needs. The
 *                       client shows what is missing rather than making the
 *                       tenant guess which blank field is the blocking one.
 */
@Schema(description = "A tenant's own details")
public record TenantProfileResponse(
        LocalDate birthdate,
        String permanentAddress,
        String occupation,
        String emergencyContactName,
        String emergencyContactRelationship,
        String emergencyContactPhone,
        IdType idType,
        String idNumber,
        boolean readyForALease) {

    public static TenantProfileResponse of(TenantProfile profile) {
        return new TenantProfileResponse(
                profile.getBirthdate(),
                profile.getPermanentAddress(),
                profile.getOccupation(),
                profile.getEmergencyContactName(),
                profile.getEmergencyContactRelationship(),
                profile.getEmergencyContactPhone(),
                profile.getIdType(),
                profile.getIdNumber(),
                profile.isReadyForALease());
    }
}
