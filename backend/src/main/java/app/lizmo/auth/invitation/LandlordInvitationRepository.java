package app.lizmo.auth.invitation;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LandlordInvitationRepository
        extends JpaRepository<LandlordInvitation, UUID> {

    /** The one live invitation for an address, if there is one. */
    Optional<LandlordInvitation> findByEmailAndAcceptedAtIsNull(String email);

    /**
     * Looked up by hash, spent or not.
     *
     * <p>Not filtered to live rows on purpose: an already-accepted token has to
     * be told apart from one that never existed, or somebody who taps the link
     * twice is told their invitation was never real.
     */
    Optional<LandlordInvitation> findByTokenHash(String tokenHash);
}
