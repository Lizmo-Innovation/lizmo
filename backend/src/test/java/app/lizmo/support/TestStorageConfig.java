package app.lizmo.support;

import app.lizmo.security.JwtService;
import app.lizmo.user.LandlordProfileRepository;
import app.lizmo.user.PlatformAdminRepository;
import app.lizmo.user.TenantProfileRepository;
import app.lizmo.user.UserRepository;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

/**
 * Puts the in-memory store in front of the S3 one, and a recording mailer in
 * front of SMTP, for every integration test — so no test reaches the network
 * or needs credentials.
 *
 * <p>One bean, declared as the concrete type. Declaring a second @Primary
 * DocumentStore alongside it makes both candidates primary, and Spring refuses
 * to choose -- the whole context then fails to start, which reads as every test
 * in the suite being broken.
 */
@TestConfiguration
public class TestStorageConfig {

    /**
     * A clock every test can push forward, in place of the real one. Rules
     * measured in minutes and days are checked by moving time, never by
     * waiting for it.
     *
     * <p>Named differently from the production bean on purpose. Same name and
     * Spring refuses to start at all — bean overriding is off by default — so
     * this sits alongside ClockConfig's and wins on @Primary instead.
     */
    @Bean
    @Primary
    MutableClock mutableClock() {
        return new MutableClock();
    }

    @Bean
    @Primary
    InMemoryDocumentStore documentStore() {
        return new InMemoryDocumentStore();
    }

    /**
     * One bean, declared as the concrete type — it is a Mailer, so it satisfies
     * both the interface and any test that wants to read what was sent.
     * Exposing a second @Bean for the interface would give Spring two
     * candidates and refuse to start the context, which is exactly how the
     * document store went wrong.
     */
    @Bean
    @Primary
    RecordingMailer mailer() {
        return new RecordingMailer();
    }

    /**
     * Signed-in people, for the tests whose subject is something else.
     */
    @Bean
    Accounts accounts(
            UserRepository users,
            TenantProfileRepository tenantProfiles,
            LandlordProfileRepository landlordProfiles,
            PlatformAdminRepository platformAdmins,
            PasswordEncoder passwordEncoder,
            JwtService jwt) {
        return new Accounts(users, tenantProfiles, landlordProfiles, platformAdmins,
                passwordEncoder, jwt);
    }
}
