package app.lizmo.support;

import app.lizmo.security.JwtService;
import app.lizmo.user.LandlordProfile;
import app.lizmo.user.LandlordProfileRepository;
import app.lizmo.user.PlatformAdmin;
import app.lizmo.user.PlatformAdminRepository;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.TenantProfileRepository;
import app.lizmo.user.User;
import app.lizmo.user.UserRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Accounts for tests that need somebody to be signed in.
 *
 * <p>Every test that touches a property, a lease or a document needs a landlord
 * and a tenant before it can begin. They used to be made by posting to
 * {@code /auth/register} with {@code asLandlord}, which is gone: signing up is
 * now an emailed code, and a landlord is invited rather than self-declared.
 * Driving those two flows to arrive at a fixture would test registration in
 * every class in the suite and make each one slower for it.
 *
 * <p>So these are written straight to the tables and handed an access token.
 * Registration is tested where registration lives, and everywhere else starts
 * with somebody already signed in.
 */
public class Accounts {

    /** Meets the password rule, in case a test signs in as one of these. */
    public static final String PASSWORD = "Sunrise2Bed!";

    /**
     * Emails and phone numbers have to differ between accounts, and a random
     * one collides eventually. A counter that collides on the second run is a
     * flaky 409 in an unrelated test, which is a bad afternoon.
     */
    private static final AtomicInteger SEQUENCE = new AtomicInteger();

    private final UserRepository users;
    private final TenantProfileRepository tenantProfiles;
    private final LandlordProfileRepository landlordProfiles;
    private final PlatformAdminRepository platformAdmins;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwt;

    public Accounts(
            UserRepository users,
            TenantProfileRepository tenantProfiles,
            LandlordProfileRepository landlordProfiles,
            PlatformAdminRepository platformAdmins,
            PasswordEncoder passwordEncoder,
            JwtService jwt) {
        this.users = users;
        this.tenantProfiles = tenantProfiles;
        this.landlordProfiles = landlordProfiles;
        this.platformAdmins = platformAdmins;
        this.passwordEncoder = passwordEncoder;
        this.jwt = jwt;
    }

    /** Somebody who rents. */
    public Account tenant(String name) {
        return create(name, false);
    }

    /**
     * Somebody who lets rooms — and who also holds a tenant profile, because a
     * landlord may rent somewhere themselves. Landlord is additive, never a
     * replacement, which is what the old {@code asLandlord:true} did too.
     */
    public Account landlord(String name) {
        return create(name, true);
    }

    /**
     * Lizmo's own staff.
     *
     * <p>Made by writing the row, which is the only way one is ever made: there
     * is no endpoint that grants admin, so that a compromised API cannot mint
     * itself an administrator. A test doing it by hand is doing exactly what an
     * operator would.
     */
    public Account admin(String name) {
        Account account = create(name, false);
        platformAdmins.save(new PlatformAdmin(account.id()));
        // Re-issued: the profiles are baked into a token when it is made, and
        // the one above was made before the admin row existed.
        return new Account(account.id(), account.name(), account.email(), account.phone(),
                jwt.issueAccessToken(account.id(), List.of("TENANT", "ADMIN")));
    }

    private Account create(String name, boolean asLandlord) {
        int n = SEQUENCE.incrementAndGet();
        String email = "%s%d@example.com".formatted(name.toLowerCase(), n);
        String phone = "09%09d".formatted(n);

        User user = users.save(new User(name, email, phone, passwordEncoder.encode(PASSWORD)));
        user.markEmailVerified(Instant.now());
        users.save(user);

        tenantProfiles.save(new TenantProfile(user.getId()));
        if (asLandlord) {
            landlordProfiles.save(new LandlordProfile(user.getId()));
        }

        List<String> profiles = asLandlord ? List.of("TENANT", "LANDLORD") : List.of("TENANT");
        return new Account(user.getId(), name, email, phone,
                jwt.issueAccessToken(user.getId(), profiles));
    }

    /** A signed-in person, and the details a test may need to assert on. */
    public record Account(UUID id, String name, String email, String phone, String token) {
    }
}
