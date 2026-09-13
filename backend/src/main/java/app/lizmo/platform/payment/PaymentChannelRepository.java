package app.lizmo.platform.payment;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface PaymentChannelRepository extends JpaRepository<PaymentChannel, UUID> {

    /** Everything, hidden included, in the order an admin put them. */
    List<PaymentChannel> findAllByOrderBySortOrderAsc();

    /** What a landlord is shown. */
    List<PaymentChannel> findByVisibleTrueOrderBySortOrderAsc();

    /** Where a new channel goes: after the last one. -1 when there are none. */
    @Query("select coalesce(max(c.sortOrder), -1) from PaymentChannel c")
    int lastSortOrder();
}
