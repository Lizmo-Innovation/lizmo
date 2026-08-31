package app.lizmo.rental;

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
import java.time.LocalDate;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

/**
 * The landlord saying yes, and a lease existing because of it.
 *
 * <p>This is the first place in the system that writes a lease, and the point
 * where several people asking about one bed collapses into one person holding
 * it. The exclusivity tests are the reason the class exists.
 */
class RentalDecisionIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String otherLandlordToken;
    private String anaToken;
    private String beaToken;

    private String propertyId;
    private String bedUnitId;
    private String wholeUnitId;
    private String bed1;
    private String bed2;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = register("elena", true);
        otherLandlordToken = register("mario", true);
        anaToken = register("ana", false);
        beaToken = register("bea", false);

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

        bedUnitId = addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":2,"rent":2500.00}
                """);
        wholeUnitId = addUnit("""
                {"unitNumber":"101","floor":"1","rentalMode":"WHOLE_UNIT","rent":12000.00}
                """);

        String beds = mvc.perform(get("/api/v1/units/" + bedUnitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        bed1 = json.readTree(beds).get(0).get("id").asText();
        bed2 = json.readTree(beds).get(1).get("id").asText();

        makeReadyForALease(anaToken);
        makeReadyForALease(beaToken);
    }

    private String register(String prefix, boolean asLandlord) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"%s","email":"%s%d@example.com",
                                 "password":"correct-horse-battery","asLandlord":%s}
                                """.formatted(prefix, prefix, System.nanoTime(), asLandlord)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("accessToken").asText();
    }

    private String addUnit(String body) throws Exception {
        String created = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(created).get("id").asText();
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

    /** @return the request id */
    private String ask(String token, String unitId, String bedId) throws Exception {
        String body = bedId == null
                ? "{\"unitId\":\"%s\"}".formatted(unitId)
                : "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bedId);
        String created = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(created).get("id").asText();
    }

    private org.springframework.test.web.servlet.ResultActions accept(
            String requestId, String terms) throws Exception {
        var call = post("/api/v1/rental-requests/" + requestId + "/accept")
                .header("Authorization", "Bearer " + landlordToken);
        if (terms != null) {
            call = call.contentType(MediaType.APPLICATION_JSON).content(terms);
        }
        return mvc.perform(call);
    }

    // ---- saying yes -------------------------------------------------------

    @Test
    void accepting_creates_the_lease() throws Exception {
        String request = ask(anaToken, bedUnitId, bed1);

        accept(request, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.unitNumber").value("2B"))
                .andExpect(jsonPath("$.bedLabel").exists())
                // The asking price, unless the landlord says otherwise: what
                // the tenant was shown is what they are held to.
                .andExpect(jsonPath("$.rentAmount").value(2500.00))
                .andExpect(jsonPath("$.startDate").value(LocalDate.now().toString()));
    }

    @Test
    void the_request_is_marked_accepted() throws Exception {
        String request = ask(anaToken, bedUnitId, bed1);
        accept(request, null).andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$[0].status").value("ACCEPTED"))
                .andExpect(jsonPath("$[0].decidedAt").exists());
    }

    @Test
    void the_landlord_can_name_their_own_terms() throws Exception {
        String request = ask(anaToken, bedUnitId, bed1);

        // Every bed in a room falling due on the same day, whatever the move-in
        // date, is the reason due day is set rather than derived.
        accept(request, """
                {"rentAmount":2800.00,"dueDateDay":5,"startDate":"2026-09-15"}
                """)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rentAmount").value(2800.00))
                .andExpect(jsonPath("$.dueDateDay").value(5))
                .andExpect(jsonPath("$.startDate").value("2026-09-15"));
    }

    @Test
    void the_due_day_follows_the_move_in_when_nobody_says_otherwise()
            throws Exception {
        String request = ask(anaToken, bedUnitId, bed1);

        accept(request, "{\"startDate\":\"2026-09-15\"}")
                .andExpect(jsonPath("$.dueDateDay").value(15));
    }

    @Test
    void a_slot_with_no_price_is_refused_rather_than_let_for_nothing()
            throws Exception {
        String unpriced = addUnit("""
                {"unitNumber":"3C","floor":"3","rentalMode":"WHOLE_UNIT"}
                """);
        String request = ask(anaToken, unpriced, null);

        // Writing a zero would read as free for the life of the lease.
        accept(request, null)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("Set a rent")));
    }

    // ---- one bed, one tenant ---------------------------------------------

    @Test
    void accepting_one_supersedes_everybody_else_waiting_on_that_bed()
            throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);
        String bea = ask(beaToken, bedUnitId, bed1);

        accept(ana, null).andExpect(status().isOk());

        // SUPERSEDED, not DECLINED. Nobody judged Bea; she was not first, and
        // being told she was turned down would be untrue.
        mvc.perform(get("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$[0].id").value(bea))
                .andExpect(jsonPath("$[0].status").value("SUPERSEDED"));
    }

    @Test
    void somebody_waiting_on_a_different_bed_keeps_waiting() throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);
        String bea = ask(beaToken, bedUnitId, bed2);

        accept(ana, null).andExpect(status().isOk());

        // Two people asking about different beds in one room are not rivals,
        // and clearing the queue by unit would throw away a tenant.
        mvc.perform(get("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$[0].id").value(bea))
                .andExpect(jsonPath("$[0].status").value("PENDING"));
    }

    @Test
    void a_second_acceptance_on_the_same_bed_is_refused() throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);
        String bea = ask(beaToken, bedUnitId, bed1);

        accept(ana, null).andExpect(status().isOk());

        // Bea's request is superseded, so this is really a test that the
        // landlord cannot double-let by acting on a stale screen.
        accept(bea, null).andExpect(status().isBadRequest());
    }

    @Test
    void a_let_bed_leaves_the_vacancy_list() throws Exception {
        String code = json.readTree(mvc.perform(get("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString())
                .get(0).get("code").asText();

        accept(ask(anaToken, bedUnitId, bed1), null).andExpect(status().isOk());

        // The whole point of occupancy: what a tenant scanning the gate is
        // shown has to match what is actually free.
        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.vacantBeds").value(1));
    }

    @Test
    void a_room_becomes_partly_then_fully_occupied() throws Exception {
        accept(ask(anaToken, bedUnitId, bed1), null).andExpect(status().isOk());

        mvc.perform(get("/api/v1/units/" + bedUnitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.status").value("PARTIALLY_OCCUPIED"));

        accept(ask(beaToken, bedUnitId, bed2), null).andExpect(status().isOk());

        mvc.perform(get("/api/v1/units/" + bedUnitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.status").value("OCCUPIED"));
    }

    @Test
    void a_whole_unit_is_occupied_by_one_lease() throws Exception {
        accept(ask(anaToken, wholeUnitId, null), null).andExpect(status().isOk());

        mvc.perform(get("/api/v1/units/" + wholeUnitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.status").value("OCCUPIED"));
    }

    @Test
    void a_bed_that_went_while_the_queue_waited_is_refused() throws Exception {
        String bea = ask(beaToken, bedUnitId, bed1);

        // Ana asks second and is accepted first, which is the landlord's right.
        accept(ask(anaToken, bedUnitId, bed1), null).andExpect(status().isOk());
        assertThat(bea).isNotBlank();

        // A queue can be days old. The slot is checked again at the moment of
        // acceptance, not only when the request was sent.
        accept(bea, null).andExpect(status().isBadRequest());
    }

    // ---- saying no --------------------------------------------------------

    @Test
    void declining_frees_nothing_because_nothing_was_held() throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);
        String bea = ask(beaToken, bedUnitId, bed1);

        mvc.perform(post("/api/v1/rental-requests/" + ana + "/decline")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DECLINED"));

        // Bea is untouched, and the bed is still there to be given to her.
        accept(bea, null).andExpect(status().isOk());
    }

    @Test
    void a_request_can_only_be_answered_once() throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);

        mvc.perform(post("/api/v1/rental-requests/" + ana + "/decline")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());
        // Otherwise a landlord could overwrite the record of what they did.
        accept(ana, null).andExpect(status().isBadRequest());
    }

    @Test
    void a_withdrawn_request_cannot_be_accepted() throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);

        mvc.perform(post("/api/v1/me/rental-requests/" + ana + "/withdraw")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk());

        accept(ana, null).andExpect(status().isBadRequest());
    }

    // ---- whose decision it is --------------------------------------------

    @Test
    void another_landlord_cannot_answer_this_request() throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);

        mvc.perform(post("/api/v1/rental-requests/" + ana + "/accept")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_accept_their_own_request() throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);

        // The obvious attack, and the reason acceptance is scoped by property
        // rather than by who is holding the request id.
        mvc.perform(post("/api/v1/rental-requests/" + ana + "/accept")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void answering_requires_signing_in() throws Exception {
        String ana = ask(anaToken, bedUnitId, bed1);

        mvc.perform(post("/api/v1/rental-requests/" + ana + "/accept"))
                .andExpect(status().isUnauthorized());
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(40, 30, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.GRAY);
        g.fillRect(0, 0, 40, 30);
        g.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpeg", out);
        return out.toByteArray();
    }
}
