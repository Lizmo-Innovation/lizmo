package app.lizmo.notice;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NoticeRepository extends JpaRepository<Notice, UUID> {

    /** What a landlord has up on one building, newest first. */
    List<Notice> findByPropertyIdAndArchivedFalseOrderByPostedAtDesc(UUID propertyId);

    /** What could be shown to somebody renting in these buildings. */
    List<Notice> findByPropertyIdInAndArchivedFalseOrderByPostedAtDesc(
            Collection<UUID> propertyIds);
}
