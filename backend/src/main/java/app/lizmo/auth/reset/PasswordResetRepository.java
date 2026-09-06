package app.lizmo.auth.reset;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PasswordResetRepository
        extends JpaRepository<PasswordReset, UUID> {

    /** The one live reset for an address, if there is one. */
    Optional<PasswordReset> findByEmailAndConsumedAtIsNull(String email);

    /** How many codes this address has been sent lately, for the daily cap. */
    long countByEmailAndCreatedAtAfter(String email, Instant since);

    Optional<PasswordReset> findFirstByEmailOrderByCreatedAtDesc(String email);
}
