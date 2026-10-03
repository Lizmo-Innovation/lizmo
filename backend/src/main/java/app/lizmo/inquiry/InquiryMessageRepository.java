package app.lizmo.inquiry;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InquiryMessageRepository extends JpaRepository<InquiryMessage, UUID> {

    /** Oldest first: a conversation is read in the order it happened. */
    List<InquiryMessage> findByInquiryIdOrderBySentAtAsc(UUID inquiryId);

    List<InquiryMessage> findByInquiryIdInOrderBySentAtAsc(List<UUID> inquiryIds);
}
