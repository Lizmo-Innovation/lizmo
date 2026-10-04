package app.lizmo.lease;

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
import org.springframework.test.web.servlet.ResultActions;

/**
 * The money a tenant hands over before moving in, and what becomes of it.
 *
 * <p>Two different things throughout. The advance is rent and pays for the
 * first month; the deposit is held and mostly given back. Most of these tests
 * exist to stop the two collapsing into one "upfront money" figure, which
 * would make the end of a tenancy unanswerable.
 */
class LeaseDepositIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String anaToken;

    private String propertyId;
    private String unitId;
    private String bedId;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        anaToken = accounts.tenant("ana").token();

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
        bedId = json.readTree(beds).get(0).get("id").asText();

        makeReadyForALease(anaToken);
    }

    // ---- taking it --------------------------------------------------------

    @Test
    void a_deposit_and_an_advance_are_recorded_apart() throws Exception {
        accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01",
                 "depositAmount":5000.00,"advanceAmount":2500.00}
                """)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.depositAmount").value(5000.00))
                .andExpect(jsonPath("$.advanceAmount").value(2500.00));
    }

    /**
     * Null, not zero. A landlord who took no deposit and one who has not
     * recorded what they took are different facts, and only null can say the
     * second -- which is what lets the apps show a dash rather than "P0".
     */
    @Test
    void nothing_recorded_stays_null() throws Exception {
        accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01"}
                """)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.depositAmount").doesNotExist())
                .andExpect(jsonPath("$.advanceAmount").doesNotExist());
    }

    /** A landlord who genuinely took nothing can say so, and it is not null. */
    @Test
    void zero_is_a_different_answer_from_nothing() throws Exception {
        accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01",
                 "depositAmount":0.00}
                """)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.depositAmount").value(0.00));
    }

    @Test
    void the_tenant_can_see_what_they_handed_over() throws Exception {
        accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01",
                 "depositAmount":5000.00,"advanceAmount":2500.00}
                """).andExpect(status().isOk());

        // Their own record of it, which they had no way to see before.
        mvc.perform(get("/api/v1/me/leases")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].depositAmount").value(5000.00))
                .andExpect(jsonPath("$[0].advanceAmount").value(2500.00));
    }

    @Test
    void a_negative_deposit_is_refused() throws Exception {
        accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01",
                 "depositAmount":-100.00}
                """)
                .andExpect(status().isBadRequest());
    }

    // ---- giving it back ---------------------------------------------------

    @Test
    void the_deposit_is_settled_when_the_tenancy_ends() throws Exception {
        String lease = leaseFrom(accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01",
                 "depositAmount":5000.00,"advanceAmount":2500.00}
                """));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"endDate":"2026-11-30","reason":"Moved out",
                                 "depositReturned":4500.00,
                                 "depositSettlement":"Withheld P500 for the window latch."}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.depositReturned").value(4500.00))
                .andExpect(jsonPath("$.depositSettlement")
                        .value("Withheld P500 for the window latch."));
    }

    /**
     * The tenant keeps the record after they move out. What was withheld and
     * why is the thing they will want months later, and the landlord holding
     * the only copy is how a disagreement becomes their word against nobody's.
     */
    @Test
    void a_former_tenant_can_still_read_the_settlement() throws Exception {
        String lease = leaseFrom(accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01","depositAmount":5000.00}
                """));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"endDate":"2026-11-30","depositReturned":4500.00,
                                 "depositSettlement":"Withheld P500 for the window latch."}
                                """))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/leases")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$[0].depositReturned").value(4500.00))
                .andExpect(jsonPath("$[0].depositSettlement")
                        .value("Withheld P500 for the window latch."));
    }

    @Test
    void returning_more_than_was_taken_is_a_typo() throws Exception {
        String lease = leaseFrom(accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01","depositAmount":5000.00}
                """));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"endDate":"2026-11-30","depositReturned":6000.00}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("more than the deposit")));
    }

    /** An ongoing tenancy has settled nothing, and zero would claim otherwise. */
    @Test
    void a_live_lease_has_no_settlement() throws Exception {
        accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01","depositAmount":5000.00}
                """)
                .andExpect(jsonPath("$.depositReturned").doesNotExist())
                .andExpect(jsonPath("$.depositSettlement").doesNotExist());
    }

    @Test
    void ending_without_mentioning_the_deposit_still_works() throws Exception {
        String lease = leaseFrom(accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01","depositAmount":5000.00}
                """));

        // Not every landlord settles on the day. Leaving it unanswered has to
        // stay possible, or the end-of-tenancy screen becomes a wall.
        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"2026-11-30\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.depositReturned").doesNotExist());
    }

    /**
     * Until now a tenant learned their tenancy had ended by opening the app
     * and noticing it was gone -- the same silence the request notifications
     * were built to close.
     */
    @Test
    void the_tenant_is_told_their_tenancy_ended() throws Exception {
        String lease = leaseFrom(accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01","depositAmount":5000.00}
                """));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"endDate":"2026-11-30","depositReturned":4500.00,
                                 "depositSettlement":"Withheld P500 for the window latch."}
                                """))
                .andExpect(status().isOk());

        String body = mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + anaToken))
                .andReturn().getResponse().getContentAsString();

        // The settlement travels with the news: what came back and why is the
        // whole of what somebody wants on the day they move out.
        org.assertj.core.api.Assertions.assertThat(body)
                .contains("LEASE_ENDED")
                .contains("4500")
                .contains("window latch");
    }

    @Test
    void ending_without_a_settlement_invents_no_words() throws Exception {
        String lease = leaseFrom(accept("""
                {"rentAmount":2500.00,"startDate":"2026-10-01","depositAmount":5000.00}
                """));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"2026-11-30\"}"))
                .andExpect(status().isOk());

        String body = mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + anaToken))
                .andReturn().getResponse().getContentAsString();

        org.assertj.core.api.Assertions.assertThat(body)
                .contains("LEASE_ENDED")
                .doesNotContain("Deposit returned");
    }

    // ---- fixtures ---------------------------------------------------------

    /**
     * The landlord writing the lease, with the deposit and advance under test
     * in the terms. Unlike {@code letRoom}, the response is handed back
     * unchecked: half of these are about a refusal.
     */
    private ResultActions accept(String terms) throws Exception {
        String thread = askAbout(anaToken, propertyId);

        com.fasterxml.jackson.databind.node.ObjectNode body =
                (com.fasterxml.jackson.databind.node.ObjectNode) json.readTree(terms);
        body.put("unitId", unitId);
        body.put("bedId", bedId);

        return mvc.perform(post("/api/v1/inquiries/" + thread + "/lease")
                .header("Authorization", "Bearer " + landlordToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body.toString()));
    }

    private String leaseFrom(ResultActions accepted) throws Exception {
        return json.readTree(accepted.andReturn().getResponse().getContentAsString())
                .get("id").asText();
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

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
