package app.lizmo.auth.invitation;

import app.lizmo.auth.AuthService;
import app.lizmo.auth.PasswordPolicy;
import app.lizmo.auth.dto.AuthResponse;
import app.lizmo.admin.dto.PendingInvitation;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.config.AppProperties;
import app.lizmo.mail.Mailer;
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
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/**
 * Inviting somebody to be a landlord, and their accepting.
 *
 * <p>The only way a landlord profile comes into existence. Sign-up makes
 * tenants and nothing else, so this is the whole of the answer to "how does
 * someone become a landlord": Lizmo asks them.
 */
@Service
public class LandlordInvitationService {

    /** Long enough to survive a weekend and a forwarded email. */
    static final Duration LIFETIME = Duration.ofDays(7);

    /** 256 bits. Guessing one is not a thing anybody is going to do. */
    private static final int TOKEN_BYTES = 32;

    private final LandlordInvitationRepository invitations;
    private final UserRepository users;
    private final TenantProfileRepository tenantProfiles;
    private final LandlordProfileRepository landlordProfiles;
    private final PasswordEncoder passwordEncoder;
    private final Mailer mailer;
    private final AuthService auth;
    private final AppProperties app;
    private final Clock clock;

    private final SecureRandom random = new SecureRandom();

    public LandlordInvitationService(
            LandlordInvitationRepository invitations,
            UserRepository users,
            TenantProfileRepository tenantProfiles,
            LandlordProfileRepository landlordProfiles,
            PasswordEncoder passwordEncoder,
            Mailer mailer,
            AuthService auth,
            AppProperties app,
            Clock clock) {
        this.invitations = invitations;
        this.users = users;
        this.tenantProfiles = tenantProfiles;
        this.landlordProfiles = landlordProfiles;
        this.passwordEncoder = passwordEncoder;
        this.mailer = mailer;
        this.auth = auth;
        this.app = app;
        this.clock = clock;
    }

    /**
     * Sends an invitation, and returns when it runs out.
     *
     * @param invitedBy the admin doing the inviting, recorded on the row
     */
    @Transactional
    public Instant invite(String rawEmail, String rawName, UUID invitedBy) {
        String email = normalise(rawEmail);
        String name = StringUtils.hasText(rawName) ? rawName.trim() : null;

        users.findByEmail(email).ifPresent(this::requireInvitable);

        // Any live invitation for this address stops working now. Two valid
        // links at once means revoking one is not revoking anything.
        invitations.findByEmailAndAcceptedAtIsNull(email).ifPresent(previous -> {
            previous.accept(clock.instant());
            invitations.saveAndFlush(previous);
        });

        String token = randomToken();
        Instant now = clock.instant();
        Instant expiresAt = now.plus(LIFETIME);
        invitations.save(new LandlordInvitation(email, hash(token), invitedBy, expiresAt, now));

        // Sent after the row is written, so a failure to send leaves an
        // invitation nobody was told about rather than a link with nothing
        // behind it.
        mailer.sendLandlordInvitation(
                email, name, app.inviteLink(token), token, (int) LIFETIME.toDays());

        return expiresAt;
    }

    /**
     * Whether this account can become a landlord at all.
     *
     * <p>A landlord is not a tenant. One account is one side of the
     * arrangement, so somebody who rents through Lizmo cannot also let rooms
     * through the same account -- they need a second address, which is a real
     * cost and a deliberate one.
     *
     * <p>Checked when the invitation is sent and again when it is accepted:
     * seven days pass in between, and sign-up is open, so an invited address
     * can become a tenant before anybody clicks the link.
     */
    private void requireInvitable(User existing) {
        if (landlordProfiles.existsById(existing.getId())) {
            throw new ApiException(ErrorCode.ALREADY_A_LANDLORD,
                    "That address is already a landlord on Lizmo.");
        }
        if (tenantProfiles.existsById(existing.getId())) {
            throw new ApiException(ErrorCode.ALREADY_A_TENANT,
                    "That address rents through Lizmo, and a landlord account "
                            + "cannot also be a tenant. Invite a different address.");
        }
    }

    /**
     * Everything sent and not yet taken up, expired ones included.
     *
     * <p>Expired invitations stay on the list rather than vanishing: somebody
     * has to notice that a landlord never signed up, and an invitation that
     * silently disappears after seven days is one nobody follows up.
     */
    @Transactional(readOnly = true)
    public List<PendingInvitation> pending() {
        Instant now = clock.instant();
        return invitations.findByAcceptedAtIsNullOrderByCreatedAtDesc().stream()
                .map(invitation -> new PendingInvitation(
                        invitation.getId(),
                        invitation.getEmail(),
                        invitation.getCreatedAt(),
                        invitation.getExpiresAt(),
                        invitation.hasExpired(now)))
                .toList();
    }

    /**
     * Withdraws an invitation that has not been accepted.
     *
     * <p>Marked spent rather than deleted. The row is the record that somebody
     * was invited at all, and a wrong address that quietly disappears is a
     * mistake nobody can later explain.
     */
    @Transactional
    public void revoke(UUID invitationId) {
        LandlordInvitation invitation = invitations.findById(invitationId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND,
                        "No such invitation."));

        if (invitation.isSpent()) {
            throw new ApiException(ErrorCode.INVITATION_INVALID,
                    "That invitation has already been used or withdrawn.");
        }

        invitation.accept(clock.instant());
        invitations.save(invitation);
    }

    /**
     * What an invitation is for, so the screen knows what to ask.
     *
     * <p>Whether the address already has an account decides the whole of that
     * screen: somebody new is choosing a password, somebody who already rents
     * through Lizmo is confirming the one they have.
     */
    @Transactional(readOnly = true)
    public InvitationDetails describe(String rawToken) {
        LandlordInvitation invitation = requireUsable(rawToken);
        return new InvitationDetails(
                invitation.getEmail(),
                users.findByEmail(invitation.getEmail()).isPresent(),
                invitation.getExpiresAt());
    }

    /**
     * Takes the invitation up, and signs the landlord in.
     *
     * <p>Two cases behind one call. A new person is creating their account, so
     * the password is the one they are choosing. Somebody who already has a
     * Lizmo account is having a landlord profile added to it, so the password
     * is proof the account is theirs — a link forwarded to the wrong person
     * must not hand them somebody else's tenancies.
     */
    @Transactional
    public AuthResponse accept(String rawToken, String rawName, String password) {
        LandlordInvitation invitation = requireUsable(rawToken);
        User user = users.findByEmail(invitation.getEmail()).orElse(null);

        if (user == null) {
            // Checked before the invitation is spent, as at sign-up: a password
            // that will be refused anyway should not cost somebody their link.
            PasswordPolicy.require(password);
            if (!StringUtils.hasText(rawName)) {
                throw new ApiException(ErrorCode.VALIDATION_FAILED,
                        "Enter the name your tenants will see.");
            }

            user = users.save(new User(
                    rawName.trim(), invitation.getEmail(), null,
                    passwordEncoder.encode(password)));
            // The invitation went to that address and somebody read it, which
            // is the same proof the sign-up code gives.
            user.markEmailVerified(clock.instant());

            // No tenant profile. A landlord is not a tenant, and an account
            // that holds both is an account that can rent to itself.
        } else {
            // Checked again here, not only when the invitation was sent: seven
            // days pass in between and sign-up is open, so this address may
            // have become a tenant since.
            requireInvitable(user);

            if (!passwordEncoder.matches(password, user.getPasswordHash())
                    || !user.isActive()) {
                throw new ApiException(ErrorCode.INVALID_CREDENTIALS,
                        "That is not the password for this Lizmo account.");
            }
        }

        if (!landlordProfiles.existsById(user.getId())) {
            landlordProfiles.save(new LandlordProfile(user.getId()));
        }

        invitation.accept(clock.instant());
        invitations.save(invitation);

        // Fresh tokens: the profiles are baked into an access token when it is
        // issued, so an existing tenant's old token would say TENANT until it
        // expired and the app would keep hiding the landlord side.
        return auth.startSession(user);
    }

    private LandlordInvitation requireUsable(String rawToken) {
        LandlordInvitation invitation = invitations
                .findByTokenHash(hash(rawToken == null ? "" : rawToken.trim()))
                .orElseThrow(() -> new ApiException(ErrorCode.INVITATION_INVALID,
                        "This invitation link is not valid. Ask Lizmo for a new one."));

        // Expiry before spentness, deliberately: an old link that was also used
        // should read as expired, which is the state that explains itself.
        if (invitation.hasExpired(clock.instant())) {
            throw new ApiException(ErrorCode.INVITATION_EXPIRED,
                    "This invitation has expired. Ask Lizmo for a new one.");
        }
        if (invitation.isSpent()) {
            throw new ApiException(ErrorCode.INVITATION_INVALID,
                    "This invitation has already been used. Sign in instead.");
        }
        return invitation;
    }

    private String randomToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /**
     * Plain SHA-256, not bcrypt: the token is 256 bits of randomness already,
     * so there is nothing to brute-force — and bcrypt would truncate it at 72
     * bytes besides, which is the kind of thing that is fine until it is not.
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
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "Enter an email address.");
        }
        return value.trim().toLowerCase();
    }

    /** What an invitation is for. */
    public record InvitationDetails(String email, boolean hasAccount, Instant expiresAt) {
    }
}
