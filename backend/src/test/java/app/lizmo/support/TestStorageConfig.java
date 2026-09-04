package app.lizmo.support;

import org.springframework.boot.test.context.TestConfiguration;
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
}
