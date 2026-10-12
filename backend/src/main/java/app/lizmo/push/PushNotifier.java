package app.lizmo.push;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Sends a notification already recorded to every phone its person is signed
 * in on.
 *
 * <p>The same notifications as the bell, not a second list of what deserves a
 * push: each was written to be read on a lock screen, with no names and no
 * quoted messages.
 */
@Component
public class PushNotifier {

    private static final Logger log = LoggerFactory.getLogger(PushNotifier.class);

    private final DeviceTokenRepository devices;
    private final PushSender sender;

    public PushNotifier(DeviceTokenRepository devices, PushSender sender) {
        this.devices = devices;
        this.sender = sender;
    }

    /**
     * Its own transaction, because this runs after the one that recorded the
     * notification has committed -- and forgetting a dead phone is a write.
     *
     * <p>Never throws, for the reason {@link PushSender#send} gives.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void deliver(
            UUID recipient, UUID notificationId, String type, String title, String body,
            String aboutType, UUID about, UUID leaseId, UUID propertyId) {
        try {
            List<String> tokens = devices.findByUserId(recipient).stream()
                    .map(DeviceToken::getToken)
                    .toList();
            if (tokens.isEmpty()) {
                return;
            }

            Map<String, String> data = new LinkedHashMap<>();
            data.put("notificationId", notificationId.toString());
            data.put("type", type);
            putIfKnown(data, "relatedEntityType", aboutType);
            putIfKnown(data, "relatedEntityId", about);
            putIfKnown(data, "leaseId", leaseId);
            putIfKnown(data, "propertyId", propertyId);

            List<String> dead = sender.send(tokens, new PushMessage(title, body, data));
            if (!dead.isEmpty()) {
                devices.deleteByTokenIn(dead);
            }
        } catch (RuntimeException failed) {
            log.warn("Push for notification {} not delivered", notificationId, failed);
        }
    }

    private static void putIfKnown(Map<String, String> data, String key, Object value) {
        if (value != null) {
            data.put(key, value.toString());
        }
    }
}
