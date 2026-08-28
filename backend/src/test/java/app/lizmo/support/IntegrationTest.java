package app.lizmo.support;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * One Postgres container and one Spring context, shared by every integration
 * test.
 *
 * <p>Started once in a static initialiser and never stopped, rather than with
 * {@code @Container}. That annotation ties the container to a single class's
 * lifecycle: with two test classes inheriting it, Testcontainers shut the
 * database down after the first finished, and the second ran against a dead
 * container — thirty seconds of connection timeouts and a 500 from every
 * request. Ryuk reaps the container when the JVM exits.
 *
 * <p>Real Postgres rather than H2: the schema leans on partial unique indexes
 * and CHECK constraints that H2 does not honour, so an in-memory database would
 * pass while production broke.
 */
@SpringBootTest
@AutoConfigureMockMvc
public abstract class IntegrationTest {

    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16");

    static {
        POSTGRES.start();
    }

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("lizmo.jwt.secret",
                () -> "test-secret-that-is-long-enough-for-hmac-sha256-signing");
    }

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected ObjectMapper json;
}
