package app.lizmo.paymentchannel;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;

/** The two rules every list of payment channels keeps, whoever owns it. */
public final class ChannelRules {

    private ChannelRules() {
    }

    /**
     * Trimmed, and refused when there is nothing left.
     *
     * <p>A channel with no number is somebody told to pay and unable to.
     */
    public static String filled(String value, String what) {
        String trimmed = value == null ? "" : value.trim();
        if (trimmed.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, "Enter " + what + ".");
        }
        return trimmed;
    }

    /**
     * An order naming every channel exactly once.
     *
     * <p>The whole list or nothing: a partial order would leave the ones left
     * out at positions that collide with the ones moved, and "which comes
     * first" would depend on the database's mood.
     */
    public static void requireWholeOrder(List<UUID> ids, Collection<UUID> existing) {
        boolean everyOnceExactly = ids.size() == existing.size()
                && new HashSet<>(ids).size() == ids.size()
                && existing.containsAll(ids);
        if (!everyOnceExactly) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Send every channel exactly once, in the order to show them.");
        }
    }
}
