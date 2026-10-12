package app.lizmo.property.place;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlaceDetailsRepository extends JpaRepository<PlaceDetails, UUID> {
}
