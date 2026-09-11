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

/**
 * What a landlord sees of the people asking to live in their property.
 *
 * <p>The disclosure tests are the point of this class. Anyone can create a
 * property, generate a code and collect whatever a request carries, so what is
 * withheld matters as much as what is shown.
 */
class RentalInboxIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String otherLandlordToken;
    private String tenantToken;
    private String otherTenantToken;

    private String propertyId;
    private String unitId;
    private String bedId;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        otherLandlordToken = accounts.landlord("mario").token();
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

        String unit = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":3,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        unitId = json.readTree(unit).get("id").asText();

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        bedId = json.readTree(beds).get(0).get("id").asText();
    }


    private void makeReadyForALease(String token) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"emergencyContactName":"Rosa Dela Cruz",
                                 "emergencyContactRelationship":"Mother",
                                 "emergencyContactPhone":"09171234567",
                                 "occupation":"Nurse","birthdate":"1998-04-12",
                                 "permanentAddress":"Naga City",
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
    private String ask(String token) throws Exception {
        String created = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}"
                                .formatted(unitId, bedId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(created).get("id").asText();
    }

    // ---- the queue --------------------------------------------------------

    @Test
    void an_untroubled_landlord_has_an_empty_inbox() throws Exception {
        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void a_request_appears_for_the_landlord_who_owns_the_place() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken);

        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].status").value("PENDING"))
                .andExpect(jsonPath("$[0].unitNumber").value("2B"))
                .andExpect(jsonPath("$[0].bedLabel").exists());
    }

    @Test
    void the_queue_is_answered_in_the_order_people_joined_it() throws Exception {
        makeReadyForALease(tenantToken);
        makeReadyForALease(otherTenantToken);

        ask(tenantToken);
        ask(otherTenantToken);

        // Oldest first. Newest-first would quietly reward whoever asked last,
        // which is not how a queue of people waiting should work.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].tenantName").value("ana"))
                .andExpect(jsonPath("$[1].tenantName").value("bea"));
    }

    @Test
    void withdrawn_requests_leave_the_queue() throws Exception {
        makeReadyForALease(tenantToken);
        String id = ask(tenantToken);

        mvc.perform(post("/api/v1/me/rental-requests/" + id + "/withdraw")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(0));

        // But they are still there to look back at, which is a different
        // question and a different request.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .param("pendingOnly", "false")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].status").value("WITHDRAWN"));
    }

    // ---- across every property ---------------------------------------------

    /**
     * The queue used to exist one property at a time, so a landlord with more
     * than one building had to open each to find out whether anybody was
     * asking.
     */
    @Test
    void every_property_is_asked_about_at_once() throws Exception {
        String[] elsewhere = secondProperty();
        makeReadyForALease(tenantToken);
        makeReadyForALease(otherTenantToken);
        ask(tenantToken);
        askFor(otherTenantToken, elsewhere[0], elsewhere[1]);

        mvc.perform(get("/api/v1/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                // Each names its building, which one property's queue never
                // needed to.
                .andExpect(jsonPath("$[*].propertyName").value(
                        org.hamcrest.Matchers.containsInAnyOrder(
                                "Sunrise Apartments", "Sunset Residences")));
    }

    @Test
    void only_what_still_needs_an_answer() throws Exception {
        makeReadyForALease(tenantToken);
        String request = ask(tenantToken);

        mvc.perform(post("/api/v1/rental-requests/" + request + "/decline")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(0));
    }

    /** Ownership is by construction: only the caller's own properties are asked. */
    @Test
    void another_landlords_people_are_not_among_them() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken);

        mvc.perform(get("/api/v1/rental-requests")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void a_tenant_has_nobody_waiting_on_them() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken);

        mvc.perform(get("/api/v1/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void one_propertys_queue_names_its_building_too() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken);

        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].propertyName").value("Sunrise Apartments"));
    }

    @Test
    void the_whole_queue_requires_signing_in() throws Exception {
        mvc.perform(get("/api/v1/rental-requests"))
                .andExpect(status().isUnauthorized());
    }

    /** @return the second property's unit id and first bed id */
    private String[] secondProperty() throws Exception {
        String property = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunset Residences","address":"48 Rizal Ave",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String unit = mvc.perform(post("/api/v1/properties/"
                        + json.readTree(property).get("id").asText() + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","floor":"1","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2000.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String unitIdThere = json.readTree(unit).get("id").asText();

        String beds = mvc.perform(get("/api/v1/units/" + unitIdThere + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        return new String[] {unitIdThere, json.readTree(beds).get(0).get("id").asText()};
    }

    private void askFor(String token, String unit, String bed) throws Exception {
        mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}"
                                .formatted(unit, bed)))
                .andExpect(status().isCreated());
    }

    // ---- what the landlord is told about a stranger -----------------------

    @Test
    void enough_of_the_tenant_to_decide_on_them() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken);

        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].tenantName").value("ana"))
                .andExpect(jsonPath("$[0].occupation").value("Nurse"))
                .andExpect(jsonPath("$[0].birthdate").value("1998-04-12"))
                .andExpect(jsonPath("$[0].permanentAddress").value("Naga City"))
                // The age, not the sum. A landlord reads "27", and the
                // arithmetic -- leap years, a phone whose clock is a day out --
                // is not the app's to get wrong.
                .andExpect(jsonPath("$[0].age").isNumber())
                // The figure accepting will use unless the landlord types
                // another, so the decision is made against a number rather
                // than the words "the asking rent".
                .andExpect(jsonPath("$[0].askingRent").value(2500.0))
                // What they carry, so the landlord knows a lease can be signed.
                .andExpect(jsonPath("$[0].idType").value("PHILSYS"))
                // And how to actually reach them about a viewing.
                .andExpect(jsonPath("$[0].tenantPhone").exists())

                // Not the emergency contact. That is a third person who never
                // used Lizmo and never agreed to anything, and a landlord
                // deciding whether to let a room has no use for who to ring if
                // something happens to somebody who does not live there yet.
                .andExpect(jsonPath("$[0].emergencyContactName").doesNotExist())
                .andExpect(jsonPath("$[0].emergencyContactPhone").doesNotExist())
                .andExpect(jsonPath("$[0].emergencyContactRelationship").doesNotExist());
    }

    @Test
    void the_id_number_and_the_photographs_wait_for_acceptance() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken);

        // The rule this whole record was shaped around. Anyone can put up a
        // property with a code and collect what requests carry, so a fake
        // listing should harvest as little as possible. A landlord who needs to
        // see a face can accept first.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].idNumber").doesNotExist())
                .andExpect(jsonPath("$[0].documents").doesNotExist())
                .andExpect(jsonPath("$[0].idPhotoUrl").doesNotExist())
                .andExpect(jsonPath("$[0].photoUrl").doesNotExist());
    }

    // ---- whose inbox it is ------------------------------------------------

    @Test
    void another_landlord_cannot_read_this_queue() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken);

        // Not their property, so not their queue — and the details in it belong
        // to somebody who never asked them for anything.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_read_a_landlord_queue() throws Exception {
        makeReadyForALease(tenantToken);
        ask(tenantToken);

        // Their own request is theirs to see; everybody else in the queue is
        // not, and this endpoint returns the queue.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void one_request_can_be_opened_by_the_landlord_it_was_sent_to()
            throws Exception {
        makeReadyForALease(tenantToken);
        String id = ask(tenantToken);

        mvc.perform(get("/api/v1/rental-requests/" + id)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tenantName").value("ana"))
                .andExpect(jsonPath("$.idNumber").doesNotExist());
    }

    @Test
    void a_request_id_alone_opens_nothing() throws Exception {
        makeReadyForALease(tenantToken);
        String id = ask(tenantToken);

        // The id is a UUID somebody could hold without owning the property.
        // Without this check it would hand over a stranger's details.
        mvc.perform(get("/api/v1/rental-requests/" + id)
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void reading_an_inbox_requires_signing_in() throws Exception {
        mvc.perform(get("/api/v1/properties/" + propertyId + "/rental-requests"))
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
