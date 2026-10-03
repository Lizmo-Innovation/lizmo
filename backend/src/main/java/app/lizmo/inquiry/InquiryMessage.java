package app.lizmo.inquiry;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * One thing somebody said.
 *
 * <p>The sender is a user rather than a side, because which side they are is
 * whatever they are to this thread: the landlord of this property, or the
 * person asking about it.
 */
@Entity
@Table(name = "inquiry_messages")
public class InquiryMessage {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "inquiry_id", nullable = false, updatable = false)
    private UUID inquiryId;

    @Column(name = "sender_id", nullable = false, updatable = false)
    private UUID senderId;

    @Column(nullable = false, updatable = false)
    private String body;

    @Column(name = "sent_at", nullable = false, updatable = false)
    private Instant sentAt;

    protected InquiryMessage() {
    }

    public InquiryMessage(UUID inquiryId, UUID senderId, String body, Instant sentAt) {
        this.inquiryId = inquiryId;
        this.senderId = senderId;
        this.body = body;
        this.sentAt = sentAt;
    }

    public UUID getId() {
        return id;
    }

    public UUID getInquiryId() {
        return inquiryId;
    }

    public UUID getSenderId() {
        return senderId;
    }

    public String getBody() {
        return body;
    }

    public Instant getSentAt() {
        return sentAt;
    }
}
