package app.lizmo.lease.dto;

import app.lizmo.user.Age;
import app.lizmo.user.IdType;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.User;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import java.util.UUID;

/**
 * The person living in the room, as their landlord sees them.
 *
 * <p>The other half of {@code RentalRequestForLandlord}, which says of the ID
 * number and the emergency contact: "they unlock on acceptance". Until this
 * existed they did not unlock anywhere. A tenant was required to supply an
 * emergency contact before they could so much as ask about a bed, and their
 * landlord — the one person the contact is for — had no way to read it.
 *
 * <p>So the two records are deliberately different shapes. A request carries
 * what is needed to judge a stranger; this carries what is needed to house
 * somebody, and the difference between them is the point.
 *
 * @param emergencyContactName a third person who never used Lizmo and never
 *                             agreed to anything. Shown only for the length of
 *                             the tenancy, to the one landlord it concerns,
 *                             because that is the only situation in which
 *                             somebody has a reason to ring them.
 * @param idNumber withheld while the request was pending, so a fake listing
 *                 could not harvest it, and released now that the two are in a
 *                 tenancy the number is written into.
 */
@Schema(description = "The tenant living under this lease")
public record TenantForLandlord(
        UUID leaseId,
        UUID tenantId,
        String name,
        String phone,
        String email,
        Integer age,
        LocalDate birthdate,
        String occupation,
        String permanentAddress,

        String emergencyContactName,
        String emergencyContactRelationship,
        String emergencyContactPhone,

        IdType idType,
        String idNumber) {

    public static TenantForLandlord of(
            UUID leaseId, User tenant, TenantProfile profile, LocalDate today) {
        return new TenantForLandlord(
                leaseId,
                tenant == null ? null : tenant.getId(),
                tenant == null ? null : tenant.getName(),
                tenant == null ? null : tenant.getPhone(),
                tenant == null ? null : tenant.getEmail(),
                Age.on(profile == null ? null : profile.getBirthdate(), today),
                profile == null ? null : profile.getBirthdate(),
                profile == null ? null : profile.getOccupation(),
                profile == null ? null : profile.getPermanentAddress(),
                profile == null ? null : profile.getEmergencyContactName(),
                profile == null ? null : profile.getEmergencyContactRelationship(),
                profile == null ? null : profile.getEmergencyContactPhone(),
                profile == null ? null : profile.getIdType(),
                profile == null ? null : profile.getIdNumber());
    }
}
