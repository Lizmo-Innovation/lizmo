package app.lizmo.auth;

import app.lizmo.auth.dto.AuthResponse;
import app.lizmo.auth.dto.LoginRequest;
import app.lizmo.auth.dto.RegisterRequest;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.config.JwtProperties;
import app.lizmo.security.JwtService;
import app.lizmo.user.LandlordProfile;
import app.lizmo.user.LandlordProfileRepository;
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
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwt;
    private final JwtProperties jwtProps;

    public AuthService(
            UserRepository users,
            TenantProfileRepository tenantProfiles,
            LandlordProfileRepository landlordProfiles,
            RefreshTokenRepository refreshTokens,
            PasswordEncoder passwordEncoder,
            JwtService jwt,
            JwtProperties jwtProps) {
        this.users = users;
        this.tenantProfiles = tenantProfiles;
        this.landlordProfiles = landlordProfiles;
        this.refreshTokens = refreshTokens;
        this.passwordEncoder = passwordEncoder;
        this.jwt = jwt;
        this.jwtProps = jwtProps;
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
    public AuthResponse login(LoginRequest request) {
        String identifier = normalise(request.identifier());

        User user = findByIdentifier(identifier)
                // Same error whether the account is missing or the password is
                // wrong — distinguishing them tells an attacker which accounts
                // exist.
                .orElseThrow(() -> new ApiException(ErrorCode.INVALID_CREDENTIALS,
                        "Email, phone or password is incorrect."));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ApiException(ErrorCode.INVALID_CREDENTIALS,
                    "Email, phone or password is incorrect.");
        }
        if (!user.isActive()) {
            throw new ApiException(ErrorCode.INVALID_CREDENTIALS,
                    "Email, phone or password is incorrect.");
        }

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
        List<String> profiles = new ArrayList<>(2);
        if (tenantProfiles.existsById(user.getId())) {
            profiles.add("TENANT");
        }
        if (landlordProfiles.existsById(user.getId())) {
            profiles.add("LANDLORD");
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
