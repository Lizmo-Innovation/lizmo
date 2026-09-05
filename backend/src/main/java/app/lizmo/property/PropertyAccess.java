package app.lizmo.property;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
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
 *   <li><b>Account lock</b> — a property whose platform invoice is unpaid past
 *       the grace period cannot be added to, but can still be read and reduced.
 * </ul>
 *
 * <p>The lock is per property. A landlord with three boarding houses who falls
 * behind on one keeps managing the other two, because the debt belongs to a
 * building and not to a person.
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

    /**
     * A property the caller may add to.
     *
     * <p>For the writes that <em>grow</em> the account: new units, new beds,
     * accepting a request. Anything that shrinks it — declining, ending a
     * lease — uses {@link #reducible} instead, and is allowed while locked.
     */
    public Property writable(UUID propertyId, UUID userId) {
        Property property = readable(propertyId, userId);
        requireUnlocked(property);
        return property;
    }

    /**
     * A property the caller may reduce or answer for, locked or not.
     *
     * <p>Ending a tenancy and declining a request are both writes, and both are
     * permitted while locked, for two different reasons.
     *
     * <p>Ending a lease is the write that <em>lowers</em> the invoice. Blocking
     * it means Lizmo keeps billing for a bed the landlord is not allowed to
     * mark empty — "you owe us, so you may not tell us you have fewer tenants"
     * — which inflates the very debt that caused the lock.
     *
     * <p>Declining a request is about somebody who is not Lizmo's debtor. A
     * tenant left waiting forever on a landlord's unpaid platform fee is the
     * one person in this arrangement who did nothing and can do nothing.
     */
    public Property reducible(UUID propertyId, UUID userId) {
        return readable(propertyId, userId);
    }

    /**
     * Guards writes that are not about an existing property, such as creating
     * one.
     *
     * @throws ApiException if the caller has no landlord profile, or any
     *                      property of theirs is locked
     */
    public void requireActiveLandlord(UUID userId) {
        if (!landlords.existsById(userId)) {
            throw new ApiException(ErrorCode.FORBIDDEN,
                    "This account cannot manage properties.");
        }

        // Creating a property has no property to check, which is the one hole a
        // per-property lock opens: lock one building and simply make another.
        // So this single rule stays landlord-shaped, and is derived rather than
        // stored — there is no landlord-level status to fall out of step.
        if (properties.existsByLandlordIdAndAccountStatus(
                userId, PropertyAccountStatus.LOCKED)) {
            throw new ApiException(ErrorCode.ACCOUNT_LOCKED_UNPAID_INVOICE,
                    "One of your properties has an unpaid Lizmo invoice. "
                            + "Settle it before adding another property.");
        }
    }

    private static void requireUnlocked(Property property) {
        if (property.isLocked()) {
            // A distinct code so the app can route to the unpaid invoice rather
            // than showing a dead end. Tenants are never affected by this.
            throw new ApiException(ErrorCode.ACCOUNT_LOCKED_UNPAID_INVOICE,
                    "This property has an unpaid Lizmo invoice. "
                            + "Settle it to continue managing the property.");
        }
    }
}
