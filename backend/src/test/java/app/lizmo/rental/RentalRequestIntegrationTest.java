package app.lizmo.rental;

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
 * A tenant asking a landlord for somewhere to live.
 *
 * <p>The tenant drives this: they found the place by its code, saw what was
 * free, and are asking for one particular bed. Nothing here creates a lease —
 * that is the landlord's answer, and a later step.
 */
class RentalRequestIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String tenantToken;
    private String otherTenantToken;

    private String propertyId;
    private String bedUnitId;
    private String wholeUnitId;
    private String bedId;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        tenantToken = accounts.tenant("ana").token();
        otherTenantToken = accounts.tenant("bea").token();

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

        bedUnitId = addUnit(propertyId, """
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":3,"rent":2500.00}
                """);
        wholeUnitId = addUnit(propertyId, """
                {"unitNumber":"101","floor":"1","rentalMode":"WHOLE_UNIT","rent":12000.00}
                """);

        String beds = mvc.perform(get("/api/v1/units/" + bedUnitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        bedId = json.readTree(beds).get(0).get("id").asText();
    }


    private String addUnit(String propertyId, String body) throws Exception {
        String created = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(created).get("id").asText();
    }

    /** Fills in the profile and uploads both photographs. */
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

    private ResultActions ask(String token, String unitId, String bedId) throws Exception {
        String body = bedId == null
                ? "{\"unitId\":\"%s\"}".formatted(unitId)
                : "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bedId);
        return mvc.perform(post("/api/v1/me/rental-requests")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    // ---- the gate ---------------------------------------------------------

    @Test
    void a_tenant_cannot_ask_without_a_number_to_ring() throws Exception {
        ask(tenantToken, bedUnitId, bedId)
                .andExpect(status().isConflict())
                // The only thing asked before asking: a landlord answering a
                // request wants to ring whoever made it.
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("a phone number")))
                .andExpect(jsonPath("$.code").value("TENANT_PROFILE_INCOMPLETE"));
    }

    /**
     * It used to take an emergency contact, an ID number, a photograph of the
     * ID and a 1x1 before a stranger could ask whether a bed was free. The
     * ones who would not are invisible: they simply never asked.
     */
    @Test
    void a_number_alone_is_enough_to_ask() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"contactPhone":"09170000001"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.readyForALease").value(false));

        ask(tenantToken, bedUnitId, bedId)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING"));
    }

    @Test
    void finishing_the_profile_opens_the_door() throws Exception {
        makeReadyForALease(tenantToken);

        ask(tenantToken, bedUnitId, bedId)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.propertyName").value("Sunrise Apartments"))
                .andExpect(jsonPath("$.unitNumber").value("2B"))
                .andExpect(jsonPath("$.bedLabel").exists())
                // Nothing is decided yet, and the field says so rather than
                // carrying a placeholder date.
                .andExpect(jsonPath("$.decidedAt").doesNotExist());
    }

    // ---- asking about the place ----------------------------------------------

    private ResultActions askAboutTheProperty(String token) throws Exception {
        return mvc.perform(post("/api/v1/me/rental-requests")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"propertyId\":\"%s\"}".formatted(propertyId)));
    }

    /**
     * Scanning a code shows how many beds are free per floor, not which, so
     * there is no room for the tenant to name. The landlord picks one when
     * they accept, which is how it is settled on the phone anyway.
     */
    @Test
    void a_tenant_can_ask_about_the_property_without_naming_a_room()
            throws Exception {
        makeReadyForALease(tenantToken);

        askAboutTheProperty(tenantToken)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.propertyName").value("Sunrise Apartments"))
                // Nothing to name yet: the landlord chooses on acceptance.
                .andExpect(jsonPath("$.unitNumber").doesNotExist())
                .andExpect(jsonPath("$.bedLabel").doesNotExist());
    }

    /** One ask per place: tapping twice is one enquiry, not two. */
    @Test
    void asking_about_the_same_place_twice_is_refused() throws Exception {
        makeReadyForALease(tenantToken);
        askAboutTheProperty(tenantToken).andExpect(status().isCreated());

        askAboutTheProperty(tenantToken)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_REQUESTED"))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("already asked about this place")));
    }

    /**
     * A request nobody can fill leaves a tenant waiting for an answer that
     * cannot come, and a landlord declining somebody who did nothing wrong.
     */
    @Test
    void asking_about_a_full_property_is_refused() throws Exception {
        makeReadyForALease(tenantToken);
        fillEveryRoom();

        askAboutTheProperty(tenantToken)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("Nothing is free here")));
    }

    @Test
    void asking_about_nothing_in_particular_is_refused() throws Exception {
        makeReadyForALease(tenantToken);

        mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("which property")));
    }

    /** Puts every bed and unit beyond reach, without letting them. */
    private void fillEveryRoom() throws Exception {
        for (String unit : new String[] {bedUnitId, wholeUnitId}) {
            mvc.perform(put("/api/v1/units/" + unit + "/maintenance")
                            .header("Authorization", "Bearer " + landlordToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"underMaintenance\":true}"))
                    .andExpect(status().isOk());
        }
    }

    @Test
    void a_whole_unit_is_asked_for_without_naming_a_bed() throws Exception {
        makeReadyForALease(tenantToken);

        ask(tenantToken, wholeUnitId, null)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bedId").doesNotExist())
                .andExpect(jsonPath("$.unitNumber").value("101"));
    }

    // ---- what is actually on offer ---------------------------------------

    @Test
    void a_room_let_bed_by_bed_cannot_be_asked_for_whole() throws Exception {
        makeReadyForALease(tenantToken);

        // Every bed in it may be free, and it is still not a room to rent
        // entire. The landlord chose how to let it.
        ask(tenantToken, bedUnitId, null)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("bed by bed")));
    }

    @Test
    void a_whole_unit_has_no_beds_to_ask_for() throws Exception {
        makeReadyForALease(tenantToken);

        ask(tenantToken, wholeUnitId, bedId)
                .andExpect(status().isConflict());
    }

    @Test
    void a_bed_from_another_room_is_not_findable_through_this_one()
            throws Exception {
        makeReadyForALease(tenantToken);

        String other = addUnit(
                json.readTree(mvc.perform(get("/api/v1/properties")
                                .header("Authorization", "Bearer " + landlordToken))
                        .andReturn().getResponse().getContentAsString())
                        .get(0).get("id").asText(),
                """
                {"unitNumber":"3C","floor":"3","rentalMode":"BEDSPACE",
                 "capacity":2,"rent":2000.00}
                """);
        String otherBeds = mvc.perform(get("/api/v1/units/" + other + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String foreignBed = json.readTree(otherBeds).get(0).get("id").asText();

        // Both ids come from the request, so the pairing is checked rather than
        // trusted.
        ask(tenantToken, bedUnitId, foreignBed)
                .andExpect(status().isNotFound());
    }

    @Test
    void a_bed_out_of_service_is_not_on_offer() throws Exception {
        makeReadyForALease(tenantToken);

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"underMaintenance\":true}"))
                .andExpect(status().isOk());

        ask(tenantToken, bedUnitId, bedId)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("SLOT_UNAVAILABLE"));
    }

    @Test
    void a_room_shut_for_repairs_takes_its_beds_with_it() throws Exception {
        makeReadyForALease(tenantToken);

        mvc.perform(put("/api/v1/units/" + bedUnitId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"underMaintenance\":true}"))
                .andExpect(status().isOk());

        ask(tenantToken, bedUnitId, bedId)
                .andExpect(status().isConflict());
    }

    @Test
    void a_unit_that_does_not_exist_is_a_404() throws Exception {
        makeReadyForALease(tenantToken);

        ask(tenantToken, "00000000-0000-0000-0000-000000000000", null)
                .andExpect(status().isNotFound());
    }

    // ---- more than one asker ---------------------------------------------

    @Test
    void two_tenants_may_ask_about_the_same_bed() throws Exception {
        makeReadyForALease(tenantToken);
        makeReadyForALease(otherTenantToken);

        ask(tenantToken, bedUnitId, bedId).andExpect(status().isCreated());
        // The whole reason a request is not a lease. Five people asking about
        // one bed is the point: the landlord picks.
        ask(otherTenantToken, bedUnitId, bedId).andExpect(status().isCreated());
    }

    @Test
    void the_same_tenant_cannot_ask_twice_for_the_same_bed() throws Exception {
        makeReadyForALease(tenantToken);

        ask(tenantToken, bedUnitId, bedId).andExpect(status().isCreated());
        // Tapping the button twice is one enquiry, and a landlord should never
        // see the same person asking for the same bed twice.
        ask(tenantToken, bedUnitId, bedId)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_REQUESTED"));
    }

    @Test
    void asking_twice_for_the_same_whole_unit_is_refused_too() throws Exception {
        makeReadyForALease(tenantToken);

        ask(tenantToken, wholeUnitId, null).andExpect(status().isCreated());
        // The case a single index over (tenant, unit, bed) would miss, because
        // null is not equal to itself.
        ask(tenantToken, wholeUnitId, null)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_REQUESTED"));
    }

    @Test
    void a_tenant_may_shop_around() throws Exception {
        makeReadyForALease(tenantToken);

        ask(tenantToken, bedUnitId, bedId).andExpect(status().isCreated());
        // Somebody looking for a room asks about several. Refusing this would
        // make them wait on one landlord before approaching the next.
        ask(tenantToken, wholeUnitId, null).andExpect(status().isCreated());

        mvc.perform(get("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.length()").value(2));
    }

    // ---- changing your mind ----------------------------------------------

    @Test
    void a_tenant_can_withdraw_and_then_ask_again() throws Exception {
        makeReadyForALease(tenantToken);

        String created = ask(tenantToken, bedUnitId, bedId)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String id = json.readTree(created).get("id").asText();

        mvc.perform(post("/api/v1/me/rental-requests/" + id + "/withdraw")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("WITHDRAWN"))
                .andExpect(jsonPath("$.decidedAt").exists());

        // Withdrawing frees the tenant to ask again — they changed their mind
        // back, which people do.
        ask(tenantToken, bedUnitId, bedId).andExpect(status().isCreated());
    }

    @Test
    void withdrawing_twice_is_refused_rather_than_rewriting_history()
            throws Exception {
        makeReadyForALease(tenantToken);

        String created = ask(tenantToken, bedUnitId, bedId)
                .andReturn().getResponse().getContentAsString();
        String id = json.readTree(created).get("id").asText();

        mvc.perform(post("/api/v1/me/rental-requests/" + id + "/withdraw")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk());
        mvc.perform(post("/api/v1/me/rental-requests/" + id + "/withdraw")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isBadRequest());
    }

    @Test
    void one_tenant_cannot_touch_another_tenants_request() throws Exception {
        makeReadyForALease(tenantToken);

        String created = ask(tenantToken, bedUnitId, bedId)
                .andReturn().getResponse().getContentAsString();
        String id = json.readTree(created).get("id").asText();

        // 404, not 403: somebody else's request should not be distinguishable
        // from one that does not exist.
        mvc.perform(post("/api/v1/me/rental-requests/" + id + "/withdraw")
                        .header("Authorization", "Bearer " + otherTenantToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_only_ever_sees_their_own() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken, bedUnitId, bedId).andExpect(status().isCreated());

        mvc.perform(get("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + otherTenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void asking_requires_signing_in() throws Exception {
        mvc.perform(post("/api/v1/me/rental-requests")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\"}".formatted(wholeUnitId)))
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
