package app.lizmo.auth;

import app.lizmo.auth.dto.AuthResponse;
import app.lizmo.auth.dto.CompleteRegistrationRequest;
import app.lizmo.auth.dto.LoginRequest;
import app.lizmo.auth.dto.RegisterRequest;
import app.lizmo.auth.verification.EmailVerificationService;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.config.JwtProperties;
import app.lizmo.security.JwtService;
import app.lizmo.user.LandlordProfile;
import app.lizmo.user.LandlordProfileRepository;
import app.lizmo.user.PlatformAdminRepository;
import app.lizmo.user.TenantProfile;
import app.lizmo.user.TenantProfileRepository;
import app.lizmo.user.User;
import app.lizmo.user.UserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class AuthService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository users;
    private final TenantProfileRepository tenantProfiles;
    private final LandlordProfileRepository landlordProfiles;
    private final PlatformAdminRepository platformAdmins;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwt;
    private final JwtProperties jwtProps;
    private final LoginThrottle throttle;
    private final EmailVerificationService verifications;

    public AuthService(
            UserRepository users,
            TenantProfileRepository tenantProfiles,
            LandlordProfileRepository landlordProfiles,
            PlatformAdminRepository platformAdmins,
            RefreshTokenRepository refreshTokens,
            PasswordEncoder passwordEncoder,
            JwtService jwt,
            JwtProperties jwtProps,
            LoginThrottle throttle,
            EmailVerificationService verifications) {
        this.users = users;
        this.tenantProfiles = tenantProfiles;
        this.landlordProfiles = landlordProfiles;
        this.platformAdmins = platformAdmins;
        this.refreshTokens = refreshTokens;
        this.passwordEncoder = passwordEncoder;
        this.jwt = jwt;
        this.jwtProps = jwtProps;
        this.throttle = throttle;
        this.verifications = verifications;
    }

    /**
     * Turns a verified address into an account.
     *
     * <p>The only place a self-service account is created. Everything before it
     * — the code, the tries, the cooldown — leaves nothing behind, so somebody
     * who abandons a sign-up half way through has not taken the address with
     * them.
     */
    @Transactional
    public AuthResponse completeRegistration(CompleteRegistrationRequest request) {
        // Checked before the code is even looked at. A password that will be
        // refused anyway should not cost somebody their one working code.
        PasswordPolicy.require(request.password());

        // Expiry before correctness, five tries, single use — all of it lives
        // in the verification service, and this call is what spends the code.
        String email = verifications.consume(request.email(), request.code());

        // Between the code being issued and now, somebody could have registered
        // this address by another route. Rare, and a duplicate account is worse
        // than a confusing message.
        if (users.existsByEmail(email)) {
            throw new ApiException(ErrorCode.EMAIL_ALREADY_REGISTERED,
                    "That address already has an account. Sign in instead.");
        }

        User user = users.save(new User(
                request.name(), email, null, passwordEncoder.encode(request.password())));
        user.markEmailVerified(Instant.now());

        // A tenant profile and nothing else. Landlords are invited by an admin,
        // so nobody makes themselves one by ticking a box.
        tenantProfiles.save(new TenantProfile(user.getId()));

        return issueTokens(user);
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = normalise(request.email());
        String phone = normalise(request.phone());

        if (email == null && phone == null) {
            throw new ApiException(ErrorCode.CONTACT_REQUIRED,
                    "Provide an email address or a phone number.");
        }
        if (email != null && users.existsByEmail(email)) {
            throw new ApiException(ErrorCode.EMAIL_ALREADY_REGISTERED,
                    "That email address is already registered.");
        }
        if (phone != null && users.existsByPhone(phone)) {
            throw new ApiException(ErrorCode.PHONE_ALREADY_REGISTERED,
                    "That phone number is already registered.");
        }

        User user = users.save(
                new User(request.name(), email, phone, passwordEncoder.encode(request.password())));

        // Everyone gets a tenant profile: it is the baseline capability, and a
        // landlord may also rent elsewhere. Landlord is additive, never a
        // replacement.
        tenantProfiles.save(new TenantProfile(user.getId()));
        if (request.asLandlord()) {
            landlordProfiles.save(new LandlordProfile(user.getId()));
        }

        return issueTokens(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request, String clientAddress) {
        String identifier = normalise(request.identifier());

        // Checked before touching the password: a throttled caller should cost
        // us nothing, and bcrypt verification is deliberately expensive.
        if (throttle.isThrottled(identifier, clientAddress)) {
            throw new ThrottledException(throttle.retryAfterSeconds(identifier, clientAddress));
        }

        User user = findByIdentifier(identifier).orElse(null);

        // Same error whether the account is missing, the password is wrong, or
        // the account is inactive — distinguishing them tells an attacker which
        // accounts exist.
        if (user == null
                || !passwordEncoder.matches(request.password(), user.getPasswordHash())
                || !user.isActive()) {
            throttle.recordFailure(identifier, clientAddress);
            throw new ApiException(ErrorCode.INVALID_CREDENTIALS,
                    "Email, phone or password is incorrect.");
        }

        throttle.recordSuccess(identifier);
        return issueTokens(user);
    }

    @Transactional
    public AuthResponse refresh(String rawToken) {
        RefreshToken stored = refreshTokens.findByTokenHash(hash(rawToken))
                .orElseThrow(() -> new ApiException(ErrorCode.REFRESH_TOKEN_INVALID,
                        "Please sign in again."));

        if (!stored.isUsable(Instant.now())) {
            throw new ApiException(ErrorCode.REFRESH_TOKEN_INVALID, "Please sign in again.");
        }

        User user = users.findById(stored.getUserId())
                .orElseThrow(() -> new ApiException(ErrorCode.REFRESH_TOKEN_INVALID,
                        "Please sign in again."));

        if (!user.isActive()) {
            throw new ApiException(ErrorCode.REFRESH_TOKEN_INVALID, "Please sign in again.");
        }

        // Rotate: the presented token is spent, so a stolen copy cannot be
        // replayed after the legitimate client refreshes.
        stored.revoke();
        refreshTokens.save(stored);

        return issueTokens(user);
    }

    @Transactional
    public void logout(String rawToken) {
        // Absent or already-revoked tokens are not an error — logging out twice
        // should succeed, and reporting "no such token" leaks nothing useful.
        refreshTokens.findByTokenHash(hash(rawToken)).ifPresent(token -> {
            token.revoke();
            refreshTokens.save(token);
        });
    }

    private Optional<User> findByIdentifier(String identifier) {
        if (identifier == null) {
            return Optional.empty();
        }
        return identifier.contains("@")
                ? users.findByEmail(identifier)
                : users.findByPhone(identifier);
    }

    private AuthResponse issueTokens(User user) {
        List<String> profiles = profilesOf(user);
        String accessToken = jwt.issueAccessToken(user.getId(), profiles);

        String rawRefresh = randomToken();
        refreshTokens.save(new RefreshToken(
                user.getId(),
                hash(rawRefresh),
                Instant.now().plus(jwtProps.refreshTokenTtl())));

        return new AuthResponse(
                accessToken,
                rawRefresh,
                jwtProps.accessTokenTtl().toSeconds(),
                user.getId(),
                user.getName(),
                profiles);
    }

    private List<String> profilesOf(User user) {
        List<String> profiles = new ArrayList<>(3);
        if (tenantProfiles.existsById(user.getId())) {
            profiles.add("TENANT");
        }
        if (landlordProfiles.existsById(user.getId())) {
            profiles.add("LANDLORD");
        }
        // Internal Lizmo staff. Included so the admin console can refuse a
        // non-admin at sign-in rather than showing them a console whose every
        // request will be rejected. It remains a claim about identity, not a
        // grant: /admin routes must still check server-side.
        if (platformAdmins.existsById(user.getId())) {
            profiles.add("ADMIN");
        }
        return profiles;
    }

    private static String randomToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /**
     * Plain SHA-256, not bcrypt: these are 256 bits of random already, so there
     * is nothing to brute-force and no need for a slow hash on every refresh.
     */
    private static String hash(String raw) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(raw.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    private static String normalise(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim().toLowerCase();
    }
}
