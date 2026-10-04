package app.lizmo.inquiry;

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
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * The landlord writing the tenancy they agreed on, from inside the thread.
 *
 * <p>The room is named here and nowhere else: the tenant was shown how many
 * beds are free on each floor and what they cost, never which rooms exist.
 */
class InquiryLeaseIntegrationTest extends IntegrationTest {

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

    /** Everything a tenancy needs on file: the ID, the emergency contact, both photos. */
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
        image.createGraphics().setColor(Color.WHITE);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }

    /** @return the thread id */
    private String askAbout(String token) throws Exception {
        String created = mvc.perform(post("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"propertyId\":\"%s\",\"message\":\"Anything free?\"}"
                                .formatted(propertyId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(created).get("inquiry").get("id").asText();
    }

    private String readyToLease(String token) throws Exception {
        makeReadyForALease(token);
        return askAbout(token);
    }

    private ResultActions writeLease(String id, String terms) throws Exception {
        var request = post("/api/v1/inquiries/" + id + "/lease")
                .header("Authorization", "Bearer " + landlordToken);
        if (terms != null) {
            request = request.contentType(MediaType.APPLICATION_JSON).content(terms);
        }
        return mvc.perform(request);
    }

    private String room(String unitId, String bedId) {
        return bedId == null
                ? "{\"unitId\":\"%s\"}".formatted(unitId)
                : "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bedId);
    }

    // ---- choosing the room ----------------------------------------------------------

    @Test
    void the_landlord_names_the_room_and_the_tenancy_exists() throws Exception {
        String thread = readyToLease(anaToken);

        writeLease(thread, room(bedUnitId, bed1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.unitNumber").value("2B"))
                .andExpect(jsonPath("$.bedLabel").value(Matchers.notNullValue()))
                .andExpect(jsonPath("$.rentAmount").value(2500.00))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.propertyName").value("Sunrise Apartments"));
    }

    @Test
    void a_tenancy_without_a_room_is_refused() throws Exception {
        String thread = readyToLease(anaToken);

        writeLease(thread, "{}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(Matchers.containsString("Choose which room")));
    }

    /** Giving away the whole of a room that is let bed by bed. */
    @Test
    void a_shared_room_cannot_be_handed_over_whole() throws Exception {
        String thread = readyToLease(anaToken);

        writeLease(thread, room(bedUnitId, null))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(Matchers.containsString("bed by bed")));
    }

    @Test
    void a_room_in_somebody_elses_property_is_not_found() throws Exception {
        String thread = readyToLease(anaToken);

        String theirs = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + otherLandlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunset","address":"1 Rizal Ave",
                                 "type":"APARTMENT","usage":"RESIDENTIAL"}
                                """))
                .andReturn().getResponse().getContentAsString();
        String theirProperty = json.readTree(theirs).get("id").asText();

        String theirUnit = json.readTree(mvc.perform(
                        post("/api/v1/properties/" + theirProperty + "/units")
                                .header("Authorization", "Bearer " + otherLandlordToken)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {"unitNumber":"A","rentalMode":"WHOLE_UNIT","rent":5000}
                                        """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        writeLease(thread, room(theirUnit, null)).andExpect(status().isNotFound());
    }

    // ---- what the tenant must have on file -------------------------------------------

    /**
     * A number was enough to ask a question. A tenancy is a different thing,
     * and the gate for it lives here.
     */
    @Test
    void a_tenant_who_only_gave_a_number_cannot_be_leased_to() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"contactPhone\":\"09170000001\"}"))
                .andExpect(status().isOk());
        String thread = askAbout(anaToken);

        writeLease(thread, room(bedUnitId, bed1))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TENANT_PROFILE_INCOMPLETE"));
    }

    /** Refused, not spent: the same thread works once they finish. */
    @Test
    void the_thread_survives_being_refused_for_an_unfinished_profile() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"contactPhone\":\"09170000001\"}"))
                .andExpect(status().isOk());
        String thread = askAbout(anaToken);
        writeLease(thread, room(bedUnitId, bed1)).andExpect(status().isConflict());

        makeReadyForALease(anaToken);
        writeLease(thread, room(bedUnitId, bed1)).andExpect(status().isOk());
    }

    /** So the landlord can see what to wait for before they try. */
    @Test
    void the_thread_says_what_the_tenant_still_needs() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"contactPhone\":\"09170000001\"}"))
                .andExpect(status().isOk());
        String thread = askAbout(anaToken);

        mvc.perform(get("/api/v1/inquiries/" + thread)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.applicant.stillNeeds",
                        Matchers.hasItem(Matchers.containsString("emergency"))));
    }

    // ---- the terms -------------------------------------------------------------------

    @Test
    void the_rent_falls_back_to_what_was_advertised() throws Exception {
        String thread = readyToLease(anaToken);

        writeLease(thread, room(wholeUnitId, null))
                .andExpect(jsonPath("$.rentAmount").value(12000.00))
                // The day they move in, when nobody says otherwise.
                .andExpect(jsonPath("$.dueDateDay")
                        .value(java.time.LocalDate.now().getDayOfMonth()));
    }

    @Test
    void the_landlord_can_name_their_own_terms() throws Exception {
        String thread = readyToLease(anaToken);

        writeLease(thread, """
                {"unitId":"%s","rentAmount":9000.00,"dueDateDay":5,
                 "startDate":"2026-11-01","depositAmount":18000.00,
                 "advanceAmount":9000.00}
                """.formatted(wholeUnitId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rentAmount").value(9000.00))
                .andExpect(jsonPath("$.dueDateDay").value(5))
                .andExpect(jsonPath("$.startDate").value("2026-11-01"))
                .andExpect(jsonPath("$.depositAmount").value(18000.00))
                .andExpect(jsonPath("$.advanceAmount").value(9000.00));
    }

    @Test
    void a_room_with_no_price_is_refused_rather_than_let_for_nothing() throws Exception {
        String unpriced = addUnit("""
                {"unitNumber":"301","rentalMode":"WHOLE_UNIT"}
                """);
        String thread = readyToLease(anaToken);

        writeLease(thread, room(unpriced, null))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(Matchers.containsString("Set a rent")));
    }

    // ---- what it does to the room and the thread --------------------------------------

    @Test
    void the_thread_becomes_a_tenancy_and_stays_readable() throws Exception {
        String thread = readyToLease(anaToken);
        writeLease(thread, room(bedUnitId, bed1)).andExpect(status().isOk());

        mvc.perform(get("/api/v1/inquiries/" + thread)
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.inquiry.status").value("LEASED"))
                .andExpect(jsonPath("$.messages.length()").value(1));

        // And the two of them can carry on talking in it: it is the same two
        // people, and a tenancy needs somewhere to talk.
        mvc.perform(post("/api/v1/inquiries/" + thread + "/messages")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"body\":\"Thank you! What time can I move in?\"}"))
                .andExpect(status().isCreated());
    }

    @Test
    void the_tenant_is_told_the_terms_they_are_on() throws Exception {
        String thread = readyToLease(anaToken);
        writeLease(thread, room(wholeUnitId, null)).andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$[0].type").value("REQUEST_ACCEPTED"))
                .andExpect(jsonPath("$[0].message")
                        .value(Matchers.containsString("unit 101")))
                .andExpect(jsonPath("$[0].message")
                        .value(Matchers.containsString("12000")))
                .andExpect(jsonPath("$[0].leaseId").value(Matchers.notNullValue()));
    }

    @Test
    void a_room_becomes_partly_then_fully_occupied() throws Exception {
        String ana = readyToLease(anaToken);
        writeLease(ana, room(bedUnitId, bed1)).andExpect(status().isOk());

        mvc.perform(get("/api/v1/units/" + bedUnitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.status").value("PARTIALLY_OCCUPIED"));

        String bea = readyToLease(beaToken);
        writeLease(bea, room(bedUnitId, bed2)).andExpect(status().isOk());

        mvc.perform(get("/api/v1/units/" + bedUnitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.status").value("OCCUPIED"));
    }

    /** What a tenant scanning the gate sees has to match what is actually free. */
    @Test
    void a_let_bed_leaves_the_vacancy_list() throws Exception {
        String code = json.readTree(mvc.perform(get("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString())
                .get(0).get("code").asText();

        String thread = readyToLease(anaToken);
        writeLease(thread, room(bedUnitId, bed1)).andExpect(status().isOk());

        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.vacantBeds").value(1));
    }

    /** A thread can be a fortnight old, and the room may have gone. */
    @Test
    void a_bed_that_went_while_they_talked_is_refused() throws Exception {
        String bea = readyToLease(beaToken);
        String ana = readyToLease(anaToken);

        writeLease(ana, room(bedUnitId, bed1)).andExpect(status().isOk());
        // A conflict rather than a bad request: nothing the landlord sent was
        // wrong, the bed simply went while they were talking.
        writeLease(bea, room(bedUnitId, bed1))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("SLOT_UNAVAILABLE"))
                .andExpect(jsonPath("$.message")
                        .value(Matchers.containsString("already let")));
    }

    /**
     * Nobody is superseded. A thread is about a building, not a room, so
     * somebody else asking about the same place has lost nothing — the
     * landlord may well have another room for them.
     */
    @Test
    void the_other_conversations_carry_on() throws Exception {
        String bea = readyToLease(beaToken);
        String ana = readyToLease(anaToken);
        writeLease(ana, room(bedUnitId, bed1)).andExpect(status().isOk());

        mvc.perform(get("/api/v1/inquiries/" + bea)
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.inquiry.status").value("OPEN"));
    }

    @Test
    void one_conversation_produces_one_tenancy() throws Exception {
        String thread = readyToLease(anaToken);
        writeLease(thread, room(bedUnitId, bed1)).andExpect(status().isOk());

        writeLease(thread, room(bedUnitId, bed2))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(Matchers.containsString("already a tenancy")));
    }

    @Test
    void a_closed_conversation_cannot_become_a_tenancy() throws Exception {
        String thread = readyToLease(anaToken);
        mvc.perform(post("/api/v1/inquiries/" + thread + "/close")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        writeLease(thread, room(bedUnitId, bed1)).andExpect(status().isBadRequest());
    }

    // ---- who may do it ----------------------------------------------------------------

    @Test
    void another_landlord_cannot_write_a_tenancy_in_this_thread() throws Exception {
        String thread = readyToLease(anaToken);

        mvc.perform(post("/api/v1/inquiries/" + thread + "/lease")
                        .header("Authorization", "Bearer " + otherLandlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(room(bedUnitId, bed1)))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_give_themselves_a_room() throws Exception {
        String thread = readyToLease(anaToken);

        mvc.perform(post("/api/v1/inquiries/" + thread + "/lease")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(room(bedUnitId, bed1)))
                .andExpect(status().isNotFound());

        assertThat(thread).isNotBlank();
    }

    @Test
    void writing_a_tenancy_requires_signing_in() throws Exception {
        String thread = readyToLease(anaToken);

        mvc.perform(post("/api/v1/inquiries/" + thread + "/lease")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(room(bedUnitId, bed1)))
                .andExpect(status().isUnauthorized());
    }
}
