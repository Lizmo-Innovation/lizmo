package app.lizmo.lease;

import app.lizmo.lease.dto.TenantForLandlord;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.TenantProfileRepository;
import app.lizmo.user.User;
import app.lizmo.user.UserRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Who is living in the room, in full.
 *
 * <p>Gated by {@link LeaseHolderAccess}, the same rule that governs the ID
 * photographs: through a live lease, on the caller's own property, and not one
 * day longer than the tenancy.
 */
@Service
public class TenantDetailsService {

    private final LeaseHolderAccess access;
    private final UserRepository users;
    private final TenantProfileRepository profiles;
    private final Clock clock;

    public TenantDetailsService(
            LeaseHolderAccess access,
            UserRepository users,
            TenantProfileRepository profiles,
            Clock clock) {
        this.access = access;
        this.users = users;
        this.profiles = profiles;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public TenantForLandlord forLease(UUID leaseId, UUID landlordId) {
        Lease lease = access.requireLive(leaseId, landlordId);

        User tenant = users.findById(lease.getTenantId()).orElse(null);
        TenantProfile profile = profiles.findById(lease.getTenantId()).orElse(null);

        // Nulls rather than a 404 if either is missing. The lease is real and
        // the landlord is entitled to it; a profile that has been scrubbed by
        // account deletion should read as blank fields, not as a lease that
        // suddenly does not exist.
        return TenantForLandlord.of(lease.getId(), tenant, profile, LocalDate.now(clock));
    }
}
