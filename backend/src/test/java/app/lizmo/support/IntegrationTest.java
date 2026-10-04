package app.lizmo.support;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
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
@Import(TestStorageConfig.class)
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

    /** Somebody to be signed in as. See {@link Accounts}. */
    @Autowired
    protected Accounts accounts;

    /**
     * A tenancy, the way one now comes about: a conversation about the
     * property, and the landlord writing the lease into it.
     *
     * <p>Here rather than copied into every test that needs somebody housed.
     * Two steps and a room that has to be named by the landlord is more
     * ceremony than a test about rent or maintenance should carry.
     *
     * @param roomJson  which room, as the lease endpoint takes it:
     *                  {@code {"unitId":...}} and optionally {@code "bedId"}.
     * @param termsJson rent, start date, deposit and so on, or null for the
     *                  defaults.
     * @return the lease, as the API describes it
     */
    protected String letRoom(
            String landlordToken, String tenantToken, String roomJson, String termsJson)
            throws Exception {

        com.fasterxml.jackson.databind.node.ObjectNode room =
                (com.fasterxml.jackson.databind.node.ObjectNode) json.readTree(roomJson);

        // The thread is about the property; the room is named when the lease
        // is written. The unit knows which property it is in.
        String propertyId = json.readTree(mvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .get("/api/v1/units/" + room.get("unitId").asText())
                                .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString())
                .get("propertyId").asText();

        String thread = json.readTree(mvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/api/v1/inquiries")
                                .header("Authorization", "Bearer " + tenantToken)
                                .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                                .content("{\"propertyId\":\"%s\"}".formatted(propertyId)))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .status().isCreated())
                .andReturn().getResponse().getContentAsString())
                .get("inquiry").get("id").asText();

        com.fasterxml.jackson.databind.node.ObjectNode terms = termsJson == null
                ? json.createObjectNode()
                : (com.fasterxml.jackson.databind.node.ObjectNode) json.readTree(termsJson);
        terms.setAll(room);

        return mvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/api/v1/inquiries/" + thread + "/lease")
                                .header("Authorization", "Bearer " + landlordToken)
                                .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                                .content(terms.toString()))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .status().isOk())
                .andReturn().getResponse().getContentAsString();
    }

    /** The conversation alone, for a test about what happens before a lease. */
    protected String askAbout(String tenantToken, String propertyId) throws Exception {
        return json.readTree(mvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/api/v1/inquiries")
                                .header("Authorization", "Bearer " + tenantToken)
                                .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                                .content("{\"propertyId\":\"%s\"}".formatted(propertyId)))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .status().isCreated())
                .andReturn().getResponse().getContentAsString())
                .get("inquiry").get("id").asText();
    }
}
