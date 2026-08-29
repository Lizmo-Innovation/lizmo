package app.lizmo.user.dto;

import app.lizmo.user.IdType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

/**
 * Everything a tenant can say about themselves.
 *
 * <p>All optional. A tenant fills this in on a phone at move-in and skips
 * whatever they can; refusing a half-finished profile would leave nothing
 * saved at all. Whether it carries enough to sign a lease is asked separately,
 * where leases are created.
 */
@Schema(description = "A tenant's own details")
public record TenantProfileRequest(
        @Past
        @Schema(example = "1998-04-12") LocalDate birthdate,

        @Size(max = 500)
        @Schema(example = "Brgy. San Isidro, Naga City, Camarines Sur")
        String permanentAddress,

        @Size(max = 255)
        @Schema(example = "Nurse at Bicol Medical Center") String occupation,

        @Size(max = 255)
        @Schema(example = "Rosa Dela Cruz") String emergencyContactName,

        @Size(max = 100)
        @Schema(example = "Mother") String emergencyContactRelationship,

        @Size(max = 30)
        @Schema(example = "09171234567") String emergencyContactPhone,

        @Schema(example = "PHILSYS") IdType idType,

        @Size(max = 50)
        @Schema(example = "1234-5678-9012") String idNumber) {
}
