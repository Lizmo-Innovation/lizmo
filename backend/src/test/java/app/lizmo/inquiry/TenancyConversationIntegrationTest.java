package app.lizmo.inquiry;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import com.fasterxml.jackson.databind.JsonNode;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;

/**
 * The conversation that goes with a tenancy.
 *
 * <p>It is the thread the tenant asked in, kept for as long as they live
 * there, reachable from the tenancy itself, and an ordinary conversation again
 * once they move out -- because moving out is when the deposit gets talked
 * about.
 */
class TenancyConversationIntegrationTest extends IntegrationTest {

    @Autowired
    private JdbcTemplate jdbc;

    private String landlordToken;
    private String otherLandlordToken;
    private String anaToken;
    private String beaToken;

    private String propertyId;
    private String bedUnitId;
    private String bed1;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        otherLandlordToken = accounts.landlord("rodel").token();
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
        bedUnitId = json.readTree(unit).get("id").asText();

        String beds = mvc.perform(get("/api/v1/units/" + bedUnitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        bed1 = json.readTree(beds).get(0).get("id").asText();

        makeReadyForALease(anaToken);
    }

    private void makeReadyForALease(String token) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
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

    private byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(8, 8, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }

    /** @return the lease id */
    private String letBed1ToAna() throws Exception {
        String lease = letRoom(landlordToken, anaToken,
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(bedUnitId, bed1), null);
        return json.readTree(lease).get("id").asText();
    }

    private JsonNode conversation(String leaseId, String token) throws Exception {
        return json.readTree(mvc.perform(post("/api/v1/leases/" + leaseId + "/conversation")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }

    /** The thread as it appears in this person's inbox. */
    private JsonNode inInbox(String token, String threadId) throws Exception {
        JsonNode list = json.readTree(mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + token))
                .andReturn().getResponse().getContentAsString());
        for (JsonNode thread : list) {
            if (thread.get("id").asText().equals(threadId)) {
                return thread;
            }
        }
        throw new AssertionError("thread " + threadId + " is not in the inbox");
    }

    private void end(String leaseId) throws Exception {
        mvc.perform(post("/api/v1/leases/" + leaseId + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());
    }

    // ---- getting from a tenancy to talking about it -----------------------------

    @Test
    void both_sides_reach_the_thread_the_tenancy_came_from() throws Exception {
        String lease = letBed1ToAna();

        JsonNode fromTenant = conversation(lease, anaToken);
        JsonNode fromLandlord = conversation(lease, landlordToken);

        assertThat(fromTenant.get("id").asText()).isEqualTo(fromLandlord.get("id").asText());
        assertThat(fromTenant.get("status").asText()).isEqualTo("LEASED");
        // Each side is told who the other is.
        assertThat(fromTenant.get("withName").asText()).isNotBlank();
        assertThat(fromLandlord.get("withName").asText()).isNotBlank();
    }

    @Test
    void nobody_else_can_reach_it() throws Exception {
        String lease = letBed1ToAna();

        // Not found rather than forbidden: whether there is a tenancy between
        // two other people is not the asker's business.
        for (String stranger : new String[] {beaToken, otherLandlordToken}) {
            mvc.perform(post("/api/v1/leases/" + lease + "/conversation")
                            .header("Authorization", "Bearer " + stranger))
                    .andExpect(status().isNotFound());
        }
        mvc.perform(post("/api/v1/leases/" + UUID.randomUUID() + "/conversation")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isNotFound());
    }

    /**
     * A tenancy from before conversations existed has no thread. One is made,
     * already a tenancy -- there is nothing to ask about a room somebody lives
     * in -- and asking again returns the same one.
     */
    @Test
    void a_tenancy_with_no_thread_is_given_one() throws Exception {
        String lease = letBed1ToAna();
        String original = conversation(lease, anaToken).get("id").asText();

        // As a lease from before October looks: unlinked, with no thread.
        jdbc.update("UPDATE leases SET inquiry_id = NULL WHERE id = ?::uuid", lease);
        jdbc.update("DELETE FROM inquiry_messages WHERE inquiry_id = ?::uuid", original);
        jdbc.update("DELETE FROM inquiries WHERE id = ?::uuid", original);

        JsonNode made = conversation(lease, landlordToken);
        assertThat(made.get("id").asText()).isNotEqualTo(original);
        assertThat(made.get("status").asText()).isEqualTo("LEASED");

        assertThat(conversation(lease, anaToken).get("id").asText())
                .isEqualTo(made.get("id").asText());
    }

    // ---- what a thread says about the tenancy ------------------------------------

    @Test
    void a_thread_says_which_room_and_since_when() throws Exception {
        String lease = letBed1ToAna();
        String thread = conversation(lease, anaToken).get("id").asText();

        for (String token : new String[] {anaToken, landlordToken}) {
            JsonNode tenancy = inInbox(token, thread).get("tenancy");
            assertThat(tenancy.get("leaseId").asText()).isEqualTo(lease);
            assertThat(tenancy.get("place").asText()).isEqualTo("Bed 1, 2B");
            assertThat(tenancy.get("active").asBoolean()).isTrue();
            assertThat(tenancy.get("startDate").asText()).isNotBlank();
        }
    }

    @Test
    void somebody_who_only_asked_has_no_tenancy() throws Exception {
        String thread = askAbout(beaTokenWithANumber(), propertyId);

        assertThat(inInbox(landlordToken, thread).get("tenancy").isNull()).isTrue();
    }

    private String beaTokenWithANumber() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + beaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"contactPhone\":\"09170000002\"}"))
                .andExpect(status().isOk());
        return beaToken;
    }

    // ---- moving out ---------------------------------------------------------------

    /**
     * It used to stay "Renting" in both inboxes forever, and refuse to be
     * closed with "end that instead" -- of a tenancy that had already ended.
     */
    @Test
    void moving_out_makes_it_an_ordinary_conversation_again() throws Exception {
        String lease = letBed1ToAna();
        String thread = conversation(lease, anaToken).get("id").asText();

        end(lease);

        JsonNode after = inInbox(anaToken, thread);
        assertThat(after.get("status").asText()).isEqualTo("OPEN");
        assertThat(after.get("tenancy").get("active").asBoolean()).isFalse();
        assertThat(after.get("tenancy").get("endDate").asText()).isNotBlank();

        // Still somewhere to talk about the deposit.
        mvc.perform(post("/api/v1/inquiries/" + thread + "/messages")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"body\":\"When will the deposit come back?\"}"))
                .andExpect(status().isCreated());

        // And it can be closed now.
        mvc.perform(post("/api/v1/inquiries/" + thread + "/close")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CLOSED"));
    }

    @Test
    void after_moving_out_the_thread_is_still_reachable_from_the_tenancy() throws Exception {
        String lease = letBed1ToAna();
        end(lease);

        JsonNode thread = conversation(lease, anaToken);
        assertThat(thread.get("status").asText()).isEqualTo("OPEN");
    }

    /** A thread left marked as a tenancy from before moving out reopened one. */
    @Test
    void a_thread_stuck_on_an_ended_tenancy_is_mended_when_reached() throws Exception {
        String lease = letBed1ToAna();
        String thread = conversation(lease, anaToken).get("id").asText();
        end(lease);
        jdbc.update("UPDATE inquiries SET status = 'LEASED', closed_at = now() WHERE id = ?::uuid",
                thread);

        assertThat(conversation(lease, landlordToken).get("status").asText())
                .isEqualTo("OPEN");
    }

    @Test
    void the_same_tenant_can_be_let_a_room_again_from_it() throws Exception {
        String first = letBed1ToAna();
        end(first);

        String again = letBed1ToAna();

        assertThat(again).isNotEqualTo(first);
        assertThat(conversation(again, anaToken).get("status").asText()).isEqualTo("LEASED");
    }

    // ---- what the other side is told -------------------------------------------

    /** "Somebody is asking about your place" is wrong about a person who lives there. */
    @Test
    void a_tenant_writing_is_announced_as_the_tenant() throws Exception {
        String lease = letBed1ToAna();
        String thread = conversation(lease, anaToken).get("id").asText();

        mvc.perform(post("/api/v1/inquiries/" + thread + "/messages")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"body\":\"The water is off on the second floor\"}"))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/v1/inquiries/" + thread + "/messages")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"body\":\"The plumber comes at three\"}"))
                .andExpect(status().isCreated());

        assertThat(feed(landlordToken)).contains("Your tenant sent a message");
        assertThat(feed(anaToken)).contains("Your landlord sent a message");
    }

    private String feed(String token) throws Exception {
        return mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + token))
                .andReturn().getResponse().getContentAsString();
    }
}
