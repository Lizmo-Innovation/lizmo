package app.lizmo.user;

import app.lizmo.auth.RefreshTokenRepository;
import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentStore;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.property.Property;
import app.lizmo.property.PropertyRepository;
import app.lizmo.property.Unit;
import app.lizmo.property.UnitRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Closing an account, at the person's own request.
 *
 * <p>Required by Google Play, and the shape of it is a product decision rather
 * than a policy one: a tenancy is a record between two people. A lease, its
 * dates and its rent belong as much to the landlord as to the tenant, so
 * erasing a user row would quietly delete somebody else's history of their own
 * property.
 *
 * <p>So the account stops existing as an account — it cannot be signed into,
 * its address is released, and everything that identifies the person is
 * overwritten — while the record of what happened survives, attached to an id
 * that no longer names anybody.
 *
 * <p>The photographs are the exception, and are properly deleted: an ID and a
 * selfie are the most sensitive things Lizmo holds, and once somebody is gone
 * there is no reason to keep them at all.
 */
@Service
public class AccountDeletionService {

    private static final Logger log = LoggerFactory.getLogger(AccountDeletionService.class);

    /**
     * What the address becomes.
     *
     * <p>An address that is kept forever is one the person can never use to
     * come back, and it is still their email address sitting in a database
     * after they asked to be forgotten. .invalid is reserved by RFC 2606 and
     * can never be a real domain, so nothing will ever be sent to it.
     */
    private static final String RELEASED_DOMAIN = "@deleted.invalid";

    private final UserRepository users;
    private final TenantProfileRepository tenantProfiles;
    private final LandlordProfileRepository landlordProfiles;
    private final LeaseRepository leases;
    private final PropertyRepository properties;
    private final UnitRepository units;
    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder passwordEncoder;

    public AccountDeletionService(
            UserRepository users,
            TenantProfileRepository tenantProfiles,
            LandlordProfileRepository landlordProfiles,
            LeaseRepository leases,
            PropertyRepository properties,
            UnitRepository units,
            StoredDocumentRepository documents,
            DocumentStore store,
            RefreshTokenRepository refreshTokens,
            PasswordEncoder passwordEncoder) {
        this.users = users;
        this.tenantProfiles = tenantProfiles;
        this.landlordProfiles = landlordProfiles;
        this.leases = leases;
        this.properties = properties;
        this.units = units;
        this.documents = documents;
        this.store = store;
        this.refreshTokens = refreshTokens;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Whether this account can be closed, and why not.
     *
     * <p>Asked before the confirmation screen as well as during deletion, so
     * somebody is told the reason while they can still act on it rather than
     * after they have typed DELETE.
     */
    @Transactional(readOnly = true)
    public void requireDeletable(UUID userId) {
        if (!activeTenancies(userId).isEmpty()) {
            throw new ApiException(ErrorCode.ACCOUNT_HAS_ACTIVE_LEASE,
                    "You are renting through Lizmo at the moment. Your landlord "
                            + "has to end the tenancy before the account can be "
                            + "closed.");
        }

        if (landlordProfiles.existsById(userId) && !tenantsOf(userId).isEmpty()) {
            throw new ApiException(ErrorCode.ACCOUNT_HAS_ACTIVE_LEASE,
                    "People are still renting from you through Lizmo. End those "
                            + "tenancies before closing the account.");
        }
    }

    /**
     * Closes the account.
     *
     * <p>Order matters: the photographs go first. If the run fails halfway, an
     * account whose pictures are gone is a mess somebody can fix, and a
     * scrubbed account whose ID photograph survived is the one thing this
     * method exists to prevent.
     */
    @Transactional
    public void delete(UUID userId) {
        requireDeletable(userId);

        User user = users.findById(userId).orElseThrow(() -> new ApiException(
                ErrorCode.NOT_FOUND, "No such account."));

        deletePhotographs(userId);
        deleteLeasePaperwork(userId);

        // Every session ends now, including the one making this request and any
        // refresh token sitting in another device's storage.
        refreshTokens.deleteByUserId(userId);

        user.close(released(userId), passwordEncoder.encode(UUID.randomUUID().toString()));
        users.save(user);

        // The tenant profile is emptied rather than deleted. Leases point at it
        // by foreign key, and a past tenancy is the landlord's record of their
        // own property as much as it is the tenant's -- deleting the row would
        // take that with it, and would fail outright for anybody who has ever
        // rented. What goes is everything inside it: the birthdate, the
        // address, the ID number, the emergency contact.
        tenantProfiles.findById(userId).ifPresent(profile -> {
            profile.scrub();
            tenantProfiles.save(profile);
        });

        log.info("Closed account {}", userId);
    }

    /**
     * The pictures, out of storage as well as out of the database.
     *
     * <p>A row deleted while the object stays in a bucket is the failure this
     * is written to avoid: the photograph is the thing somebody wants gone.
     */
    private void deletePhotographs(UUID userId) {
        List<StoredDocument> owned =
                documents.findByOwnerTypeAndOwnerId(DocumentOwnerType.TENANT, userId);

        for (StoredDocument document : owned) {
            try {
                store.delete(document.getStorageKey());
            } catch (RuntimeException e) {
                // Logged and carried on: a storage object that refuses to go is
                // worth knowing about, and stopping here would leave the
                // account intact with its photographs still reachable.
                log.error("Could not delete {} while closing account {}",
                        document.getStorageKey(), userId, e);
            }
            documents.delete(document);
        }
    }

    /**
     * The landlord's own paperwork, filed against tenancies on their property.
     *
     * <p>Lease attachments outlive the tenancy on purpose -- a dispute is
     * usually after somebody has moved out -- so nothing else ever removes
     * them. This is the one thing that does: they are the landlord's records,
     * and they end when the landlord does.
     *
     * <p>Nothing here is the tenant's. A tenant closing their own account
     * leaves these standing, which is deliberate: a contract is an agreement
     * between two people and one of them cannot delete the other's copy.
     */
    private void deleteLeasePaperwork(UUID landlordId) {
        for (Property property : properties.findByLandlordIdOrderByNameAsc(landlordId)) {
            for (Unit unit : units.findByPropertyIdOrderByUnitNumberAsc(property.getId())) {
                for (Lease lease : leases.findByUnitId(unit.getId())) {
                    for (StoredDocument document : documents.findByOwnerTypeAndOwnerId(
                            DocumentOwnerType.LEASE, lease.getId())) {
                        try {
                            store.delete(document.getStorageKey());
                        } catch (RuntimeException e) {
                            // As with the photographs: worth knowing about, not
                            // worth stopping for. A half-closed account is worse
                            // than a file that would not go.
                            log.error("Could not delete {} while closing account {}",
                                    document.getStorageKey(), landlordId, e);
                        }
                        documents.delete(document);
                    }
                }
            }
        }
    }

    /** Leases where this person is the tenant and has not moved out. */
    private List<Lease> activeTenancies(UUID userId) {
        return leases.findByTenantIdOrderByStartDateDesc(userId).stream()
                .filter(lease -> lease.getStatus() == LeaseStatus.ACTIVE)
                .toList();
    }

    /** Leases in this landlord's own properties that have not ended. */
    private List<Lease> tenantsOf(UUID landlordId) {
        return properties.findByLandlordIdOrderByNameAsc(landlordId).stream()
                .flatMap(property -> units
                        .findByPropertyIdOrderByUnitNumberAsc(property.getId()).stream())
                .map(Unit::getId)
                .flatMap(unitId ->
                        leases.findByUnitIdAndStatus(unitId, LeaseStatus.ACTIVE).stream())
                .toList();
    }

    private String released(UUID userId) {
        return "deleted-" + userId + RELEASED_DOMAIN;
    }
}
