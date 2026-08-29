package app.lizmo.property;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * A code that has been handed out, and therefore may never be handed out again.
 *
 * <p>Separate from the property that holds it, and outlives it. Deleting a
 * property frees its row and its place in the unique index; this ledger is what
 * stops a later property minting the same code and quietly inheriting an old
 * QR sticker, a sign by the gate, or a code somebody wrote on their hand.
 *
 * <p>Nothing deletes from this table.
 */
@Entity
@Table(name = "issued_property_codes")
public class IssuedPropertyCode {

    @Id
    private String code;

    @Column(name = "issued_at", nullable = false, updatable = false)
    private Instant issuedAt;

    protected IssuedPropertyCode() {
    }

    public IssuedPropertyCode(String code) {
        this.code = code;
    }

    @PrePersist
    void stampIssuedAt() {
        if (issuedAt == null) {
            issuedAt = Instant.now();
        }
    }

    public String getCode() {
        return code;
    }

    public Instant getIssuedAt() {
        return issuedAt;
    }
}
