package app.lizmo.push;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, UUID> {

    Optional<DeviceToken> findByToken(String token);

    List<DeviceToken> findByUserId(UUID userId);

    long deleteByTokenAndUserId(String token, UUID userId);

    long deleteByUserId(UUID userId);

    long deleteByTokenIn(Collection<String> tokens);
}
