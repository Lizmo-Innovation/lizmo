package app.lizmo.admin.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

/**
 * One row of the console's landlord list.
 *
 * <p>Counts, not people. Lizmo bills on occupied slots and never needs to know
 * who sleeps in them — seeing "12 occupied beds" is billing, seeing the twelve
 * names is surveillance, and it is access nobody could justify after a leak.
 *
 * @param lockedProperties how many of their properties are locked, rather than
 *                         a single status: a landlord with three buildings and
 *                         one unpaid invoice is not simply "locked".
 */
@Schema(description = "A landlord, as the console lists them")
public record LandlordSummary(
        UUID userId,
        String name,
        String email,
        String phone,
        int properties,
        int lockedProperties,
        int occupiedUnits,
        int occupiedBeds,
        Instant joinedAt) {
}
