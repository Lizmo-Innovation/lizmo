package app.lizmo.auth.verification;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmailVerificationRepository
        extends JpaRepository<EmailVerification, UUID> {

    /** The one live verification for an address, if there is one. */
    Optional<EmailVerification> findByEmailAndConsumedAtIsNull(String email);

    /** How many codes this address has been sent lately, for the daily cap. */
    long countByEmailAndCreatedAtAfter(String email, Instant since);

    Optional<EmailVerification> findFirstByEmailOrderByCreatedAtDesc(String email);
}
