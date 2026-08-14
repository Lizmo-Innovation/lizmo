package app.lizmo.user;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantProfileRepository extends JpaRepository<TenantProfile, UUID> {
}
