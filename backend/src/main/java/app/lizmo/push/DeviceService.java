package app.lizmo.push;

import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Which phones a person is signed in on. */
@Service
public class DeviceService {

    private final DeviceTokenRepository devices;
    private final Clock clock;

    public DeviceService(DeviceTokenRepository devices, Clock clock) {
        this.devices = devices;
        this.clock = clock;
    }

    /**
     * Records a phone, or that it is still there.
     *
     * <p>Called after every sign-in and whenever Firebase rotates the token,
     * so it is an upsert: the same token twice is one phone. A token already
     * held by another account moves to this one -- somebody else has signed in
     * on that phone, and the last person must stop being told things on it.
     */
    @Transactional
    public void register(UUID userId, String token, DevicePlatform platform) {
        DeviceToken device = devices.findByToken(token)
                .orElseGet(() -> new DeviceToken(userId, token, platform, clock.instant()));
        device.seen(userId, platform, clock.instant());
        devices.save(device);
    }

    /**
     * Forgets a phone on sign-out. Only the caller's own: a token is no key to
     * anybody else's device list.
     */
    @Transactional
    public void forget(UUID userId, String token) {
        devices.deleteByTokenAndUserId(token, userId);
    }
}
