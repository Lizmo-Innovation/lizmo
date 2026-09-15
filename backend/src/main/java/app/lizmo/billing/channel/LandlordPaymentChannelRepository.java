package app.lizmo.billing.channel;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LandlordPaymentChannelRepository
        extends JpaRepository<LandlordPaymentChannel, UUID> {

    /** One landlord's list, hidden included, in the order they put it. */
    List<LandlordPaymentChannel> findByLandlordIdOrderBySortOrderAsc(UUID landlordId);

    /** What their tenants are shown. */
    List<LandlordPaymentChannel> findByLandlordIdAndVisibleTrueOrderBySortOrderAsc(UUID landlordId);

    /** A channel, only if it is this landlord's: anybody else's reads as not found. */
    Optional<LandlordPaymentChannel> findByIdAndLandlordId(UUID id, UUID landlordId);

    /** Where a new channel goes: after this landlord's last one. -1 when there are none. */
    @Query("select coalesce(max(c.sortOrder), -1) from LandlordPaymentChannel c "
            + "where c.landlordId = :landlordId")
    int lastSortOrder(@Param("landlordId") UUID landlordId);
}
