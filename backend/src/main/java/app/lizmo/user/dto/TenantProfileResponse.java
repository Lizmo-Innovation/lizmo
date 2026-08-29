package app.lizmo.user.dto;

import app.lizmo.user.IdType;
import app.lizmo.user.TenantProfile;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

/**
 * @param readyForALease whether the profile carries what a lease needs: the
 *                       details below, *and* both photographs. The
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

    /**
     * @param hasBothPhotographs whether the ID and the 1x1 are both uploaded.
     *                           Passed in rather than read here, because a
     *                           record is not the place to reach into another
     *                           table.
     */
    public static TenantProfileResponse of(TenantProfile profile, boolean hasBothPhotographs) {
        return new TenantProfileResponse(
                profile.getBirthdate(),
                profile.getPermanentAddress(),
                profile.getOccupation(),
                profile.getEmergencyContactName(),
                profile.getEmergencyContactRelationship(),
                profile.getEmergencyContactPhone(),
                profile.getIdType(),
                profile.getIdNumber(),
                profile.hasDetailsForALease() && hasBothPhotographs);
    }
}
