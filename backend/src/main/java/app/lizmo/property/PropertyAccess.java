package app.lizmo.property;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.user.LandlordProfile;
import app.lizmo.user.LandlordProfileRepository;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * The authorisation boundary for everything under a property.
 *
 * <p>Implements layers 2 and 5 of tech spec §4 in one place, so no endpoint can
 * forget one of them:
 * <ul>
 *   <li><b>Ownership</b> — a landlord may only touch their own properties.
 *   <li><b>Account lock</b> — a landlord whose platform invoice is unpaid past
 *       the grace period cannot perform management writes, but can still read.
 * </ul>
 *
 * <p>Staff (layer 3) are not handled yet: staff assignments do not exist as
 * endpoints, so today only the owner passes. When they arrive, this is the
 * single place that has to learn about them.
 *
 * <p>Missing and forbidden both return 404 on read paths. Returning 403 for a
 * property that exists but belongs to someone else confirms its existence, which
 * lets a landlord enumerate a competitor's portfolio by trying ids.
 */
@Component
public class PropertyAccess {

    private final PropertyRepository properties;
    private final LandlordProfileRepository landlords;

    public PropertyAccess(PropertyRepository properties, LandlordProfileRepository landlords) {
        this.properties = properties;
        this.landlords = landlords;
    }

    /** A property the caller may read. */
    public Property readable(UUID propertyId, UUID userId) {
        return properties.findById(propertyId)
                .filter(property -> property.isOwnedBy(userId))
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No such property."));
    }

    /** A property the caller may modify. Adds the account-lock check. */
    public Property writable(UUID propertyId, UUID userId) {
        Property property = readable(propertyId, userId);
        requireUnlocked(userId);
        return property;
    }

    /**
     * Guards writes that are not about an existing property, such as creating
     * one.
     *
     * @throws ApiException if the caller has no landlord profile, or their
     *                      account is locked
     */
    public void requireActiveLandlord(UUID userId) {
        landlords.findById(userId).orElseThrow(() -> new ApiException(
                ErrorCode.FORBIDDEN, "This account cannot manage properties."));
        requireUnlocked(userId);
    }

    private void requireUnlocked(UUID userId) {
        LandlordProfile profile = landlords.findById(userId).orElseThrow(() -> new ApiException(
                ErrorCode.FORBIDDEN, "This account cannot manage properties."));

        if (profile.isLocked()) {
            // A distinct code so the app can route to the unpaid invoice rather
            // than showing a dead end. Tenants are never affected by this.
            throw new ApiException(ErrorCode.ACCOUNT_LOCKED_UNPAID_INVOICE,
                    "Your Lizmo invoice is unpaid. Settle it to continue managing your properties.");
        }
    }
}
