package app.lizmo.support;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

/**
 * Puts the in-memory store in front of the S3 one for every integration test,
 * so no test reaches the network or needs credentials.
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
}
