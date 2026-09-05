package app.lizmo.rental.dto;

import app.lizmo.rental.RentalRequest;
import app.lizmo.rental.RentalRequestStatus;
import app.lizmo.user.IdType;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.User;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * A request as the landlord deciding on it sees it.
 *
 * <p>Carries enough to judge a stranger and no more. Ariel's call, and worth
 * restating because it is the whole shape of this record: the ID <em>type</em>
 * is here, the ID <em>number</em> and both photographs are not. Neither is the
 * emergency contact. They unlock on acceptance.
 *
 * <p>The reason is that anyone can create a property, generate a code, and
 * collect whatever a request carries. A tenant consents by sending, so this is
 * not a leak — but a fake listing should harvest as little as possible, and a
 * landlord who genuinely needs to see a face can accept and then look.
 *
 * <p>The emergency contact is a third person who never used Lizmo and never
 * agreed to anything. Their name and number belong to the tenancy, not to the
 * application for one: a landlord deciding whether to let a room has no use
 * for who to ring if something happens to somebody who does not live there
 * yet. What the landlord does need is the applicant's own number, to arrange a
 * viewing, and that is here.
 *
 * @param tenantName who they are, from the account rather than the profile: a
 *                   landlord recognises a person by name, and it is the one
 *                   thing every account has.
 * @param idType what they carry, without the number. Enough to know a lease can
 *               be signed against it.
 * @param askingRent what this slot is advertised at — the bed's own price if it
 *                   has one, otherwise the unit's. The same number the accept
 *                   endpoint falls back to, so the landlord is shown the figure
 *                   they are about to commit to rather than the words "the
 *                   asking rent".
 * @param age worked out here rather than in the app. A birthday is a date and
 *            an age is a subtraction that goes wrong quietly -- leap years,
 *            time zones, a phone whose clock is a day out -- and the landlord
 *            reads the answer, not the sum. Null when no birthday was given.
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
        Integer age,
        IdType idType,
        BigDecimal askingRent) {

    public static RentalRequestForLandlord of(
            RentalRequest request,
            User tenant,
            TenantProfile profile,
            String unitNumber,
            String bedLabel,
            LocalDate today,
            BigDecimal askingRent) {
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
                ageOn(profile == null ? null : profile.getBirthdate(), today),
                profile == null ? null : profile.getIdType(),
                askingRent);
    }

    /**
     * Years completed, not years begun.
     *
     * <p>Period rather than a subtraction of years: somebody born on the 30th
     * of December is not a year older on the 1st of January, and that is the
     * mistake the arithmetic version makes for two days out of every 365.
     */
    private static Integer ageOn(LocalDate birthdate, LocalDate today) {
        if (birthdate == null || today == null || birthdate.isAfter(today)) {
            return null;
        }
        return java.time.Period.between(birthdate, today).getYears();
    }
}
