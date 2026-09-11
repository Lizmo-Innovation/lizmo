package app.lizmo.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

/**
 * Being told what happened.
 *
 * <p>Before this existed the app changed underneath people. A tenant found out
 * they had been accepted by noticing a different screen, and the rivals — whose
 * requests close the moment somebody else is accepted — were told nothing at
 * all. These tests are mostly about that silence.
 */
class NotificationIntegrationTest extends IntegrationTest {

    private static final String TERMS = """
            {"rentAmount":3000.00,"startDate":"2026-03-05"}
            """;

    private String landlordToken;
    private String anaToken;
    private String beaToken;

    private String propertyId;
    private String unitId;
    private String bed1;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        anaToken = accounts.tenant("ana").token();
        beaToken = accounts.tenant("bea").token();

        String property = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        propertyId = json.readTree(property).get("id").asText();

        String unit = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        unitId = json.readTree(unit).get("id").asText();

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        bed1 = json.readTree(beds).get(0).get("id").asText();

        makeReadyForALease(anaToken);
        makeReadyForALease(beaToken);
    }

    // ---- somebody asks ----------------------------------------------------

    @Test
    void asking_tells_the_landlord() throws Exception {
        ask(anaToken);

        mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].type").value("REQUEST_RECEIVED"))
                .andExpect(jsonPath("$[0].unread").value(true))
                .andExpect(jsonPath("$[0].relatedEntityType").value("RENTAL_REQUEST"));
    }

    /**
     * A request is answered on its property, and the notification only knew
     * the request. Without the property, tapping it could open nothing.
     */
    @Test
    void a_request_leads_the_landlord_to_its_property() throws Exception {
        ask(anaToken);

        mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].propertyId").value(propertyId))
                .andExpect(jsonPath("$[0].leaseId").isEmpty());
    }

    /**
     * A notification is read on a lock screen, and later inside a push. The
     * tenant agreed to show the landlord who they are inside the app, not on
     * the outside of somebody's phone.
     */
    @Test
    void the_landlords_notification_does_not_name_the_tenant() throws Exception {
        ask(anaToken);

        String body = mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();

        assertThat(body).doesNotContainIgnoringCase("ana");
        assertThat(body).contains("Bed 1 in 2B");
    }

    @Test
    void the_tenant_is_told_nothing_for_their_own_asking() throws Exception {
        ask(anaToken);

        mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(0));
    }

    // ---- the landlord answers ---------------------------------------------

    @Test
    void accepting_tells_the_tenant_the_terms() throws Exception {
        String request = ask(anaToken);

        mvc.perform(post("/api/v1/rental-requests/" + request + "/accept")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(TERMS))
                .andExpect(status().isOk());

        String body = mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].type").value("REQUEST_ACCEPTED"))
                .andExpect(jsonPath("$[0].relatedEntityType").value("LEASE"))
                .andExpect(jsonPath("$[0].leaseId").isNotEmpty())
                .andReturn().getResponse().getContentAsString();

        // The rent may not be the one they were looking at when they asked, so
        // the terms travel with the news.
        assertThat(body).contains("Bed 1 in 2B").contains("3000")
                .contains("5th").contains("2026-03-05");
    }

    @Test
    void declining_tells_the_tenant() throws Exception {
        String request = ask(anaToken);

        mvc.perform(post("/api/v1/rental-requests/" + request + "/decline")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].type").value("REQUEST_DECLINED"));
    }

    /** The one this feature was built for. */
    @Test
    void losing_the_bed_to_somebody_else_is_not_silent() throws Exception {
        String anas = ask(anaToken);
        ask(beaToken);

        mvc.perform(post("/api/v1/rental-requests/" + anas + "/accept")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(TERMS))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].type").value("REQUEST_SUPERSEDED"));
    }

    // ---- reading ----------------------------------------------------------

    @Test
    void the_badge_counts_only_the_unread() throws Exception {
        ask(anaToken);
        ask(beaToken);

        mvc.perform(get("/api/v1/me/notifications/unread-count")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.unread").value(2));

        mvc.perform(post("/api/v1/me/notifications/" + newestFor(landlordToken) + "/read")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/v1/me/notifications/unread-count")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.unread").value(1));

        mvc.perform(post("/api/v1/me/notifications/read")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/v1/me/notifications/unread-count")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.unread").value(0));
    }

    /** Read stays read, and the count does not go negative on a second tap. */
    @Test
    void marking_read_twice_changes_nothing() throws Exception {
        ask(anaToken);
        String id = newestFor(landlordToken);

        for (int tap = 0; tap < 2; tap++) {
            mvc.perform(post("/api/v1/me/notifications/" + id + "/read")
                            .header("Authorization", "Bearer " + landlordToken))
                    .andExpect(status().isNoContent());
        }

        mvc.perform(get("/api/v1/me/notifications/unread-count")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.unread").value(0));
        mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].unread").value(false));
    }

    /**
     * 404 rather than 403: whether somebody else's notification exists is not
     * something to confirm to a stranger.
     */
    @Test
    void somebody_elses_notification_is_not_there_to_read() throws Exception {
        ask(anaToken);
        String id = newestFor(landlordToken);

        mvc.perform(post("/api/v1/me/notifications/" + id + "/read")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(status().isNotFound());
    }

    // ---- fixtures ---------------------------------------------------------

    /** @return the request id */
    private String ask(String token) throws Exception {
        String created = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bed1)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(created).get("id").asText();
    }

    private String newestFor(String token) throws Exception {
        String body = mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + token))
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get(0).get("id").asText();
    }

    private void makeReadyForALease(String token) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"emergencyContactName":"Rosa Dela Cruz",
                                 "emergencyContactPhone":"09171234567",
                                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                                """))
                .andExpect(status().isOk());

        for (String kind : new String[] {"VALID_ID", "TENANT_PHOTO"}) {
            mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                            .file(new MockMultipartFile("file", "p.jpg", "image/jpeg", photo()))
                            .param("docType", kind)
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isCreated());
        }
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
