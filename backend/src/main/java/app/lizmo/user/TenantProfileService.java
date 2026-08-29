package app.lizmo.user;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.document.TenantDocumentService;
import app.lizmo.user.dto.TenantProfileRequest;
import app.lizmo.user.dto.TenantProfileResponse;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A tenant's own details, readable and writable only by that tenant.
 *
 * <p>Every method takes the caller's id and loads by it. There is deliberately
 * no way to fetch someone else's profile here: a landlord sees a tenant's
 * details through a lease, which is where that permission belongs.
 */
@Service
public class TenantProfileService {

    private final TenantProfileRepository profiles;
    private final TenantDocumentService documents;

    public TenantProfileService(
            TenantProfileRepository profiles, TenantDocumentService documents) {
        this.profiles = profiles;
        this.documents = documents;
    }

    @Transactional(readOnly = true)
    public TenantProfileResponse get(UUID userId) {
        return TenantProfileResponse.of(require(userId), documents.hasBothPhotographs(userId));
    }

    @Transactional
    public TenantProfileResponse update(UUID userId, TenantProfileRequest request) {
        TenantProfile profile = require(userId);

        profile.update(
                request.birthdate(),
                // Blank means not answered, not answered with nothing — the
                // same rule every optional field in this API follows.
                trimToNull(request.permanentAddress()),
                trimToNull(request.occupation()),
                trimToNull(request.emergencyContactName()),
                trimToNull(request.emergencyContactRelationship()),
                trimToNull(request.emergencyContactPhone()),
                request.idType(),
                trimToNull(request.idNumber()));

        return TenantProfileResponse.of(
                profiles.save(profile), documents.hasBothPhotographs(userId));
    }

    /**
     * The caller's profile.
     *
     * <p>Registration always creates one, so its absence means the account
     * holds no tenant profile at all — a landlord-only account asking for a
     * tenant's screen.
     */
    private TenantProfile require(UUID userId) {
        return profiles.findById(userId).orElseThrow(() -> new ApiException(
                ErrorCode.NOT_FOUND, "This account has no tenant profile."));
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
