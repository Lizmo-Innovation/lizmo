package app.lizmo.user;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.DocumentType;
import app.lizmo.document.TenantDocumentService;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Whether a tenant may be attached to a lease yet.
 *
 * <p>The single place that answers it. The tenant's own screen asks so it can
 * show what is left; lease creation will ask so it can refuse. Two
 * implementations of the same rule would drift, and the day they disagreed a
 * tenant would be told they were ready by one screen and refused by the next.
 *
 * <p><strong>Nothing calls {@link #require} yet.</strong> Lease creation does
 * not exist — no endpoint, no rows, no screen — so this guard is written and
 * tested ahead of the thing it guards, on Ariel's instruction. Its tests
 * exercise it directly rather than through an API, which is the most that can
 * honestly be proven until leases land. Whoever builds lease creation should
 * call {@code require(tenantId)} before writing the row, and is the first
 * person able to prove it actually blocks anything.
 */
@Service
public class LeaseReadiness {

    private final TenantProfileRepository profiles;
    private final TenantDocumentService documents;

    public LeaseReadiness(TenantProfileRepository profiles, TenantDocumentService documents) {
        this.profiles = profiles;
        this.documents = documents;
    }

    /**
     * What the tenant still owes, in the order their own form asks for it, and
     * in the words it uses.
     *
     * <p>Named rather than counted, and phrased for a human: a landlord who is
     * told "profile incomplete" has to go back to the tenant with nothing they
     * can act on, whereas "a 1x1 or selfie" is a thing to go and do.
     *
     * <p>Empty means ready.
     */
    @Transactional(readOnly = true)
    public List<String> whatIsMissing(UUID tenantId) {
        Optional<TenantProfile> found = profiles.findById(tenantId);
        if (found.isEmpty()) {
            // No tenant profile at all — a landlord-only account, or an id that
            // is not a tenant. Everything is missing, which is the truthful
            // answer and refuses the lease for the right reason.
            return List.of("a tenant profile");
        }

        TenantProfile profile = found.get();
        List<String> missing = new ArrayList<>();

        if (isBlank(profile.getEmergencyContactName())
                || isBlank(profile.getEmergencyContactPhone())) {
            missing.add("an emergency contact");
        }
        if (profile.getIdType() == null || isBlank(profile.getIdNumber())) {
            missing.add("their ID details");
        }
        if (!documents.has(tenantId, DocumentType.VALID_ID)) {
            missing.add("a photo of their ID");
        }
        if (!documents.has(tenantId, DocumentType.TENANT_PHOTO)) {
            missing.add("a 1x1 or selfie");
        }

        return List.copyOf(missing);
    }

    /** @see #whatIsMissing(UUID) */
    @Transactional(readOnly = true)
    public boolean isReady(UUID tenantId) {
        return whatIsMissing(tenantId).isEmpty();
    }

    /**
     * Refuses unless the tenant is ready.
     *
     * @throws ApiException with {@link ErrorCode#TENANT_PROFILE_INCOMPLETE} —
     *                      a 409 rather than a 400, because nothing is wrong
     *                      with the landlord's request and the very same
     *                      request will succeed once the tenant finishes.
     */
    @Transactional(readOnly = true)
    public void require(UUID tenantId) {
        List<String> missing = whatIsMissing(tenantId);
        if (missing.isEmpty()) {
            return;
        }
        throw new ApiException(ErrorCode.TENANT_PROFILE_INCOMPLETE,
                "This tenant cannot sign a lease yet. They still need %s."
                        .formatted(asAList(missing)));
    }

    /**
     * "a and b", "a, b and c". A comma before "and" reads as a fourth item to
     * anyone skimming.
     */
    private static String asAList(List<String> items) {
        if (items.size() == 1) {
            return items.get(0);
        }
        return String.join(", ", items.subList(0, items.size() - 1))
                + " and " + items.get(items.size() - 1);
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
