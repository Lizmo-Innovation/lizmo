package app.lizmo.admin;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
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
 * What a locked property stops, and — more importantly — what it does not.
 *
 * <p>Locking is Lizmo's lever for an unpaid invoice, and the whole design rests
 * on one asymmetry: it blocks what <em>grows</em> the account and permits what
 * shrinks it or serves the people already living there. Every rule below is one
 * half of that, and the permissive half is the half that would be quietly wrong
 * if nobody wrote it down.
 */
class PropertyLockIntegrationTest extends IntegrationTest {

    private String adminToken;
    private String landlordToken;
    private String tenantToken;

    private String propertyId;
    private String bedUnitId;
    private String bedId;

    @BeforeEach
    void setUp() throws Exception {
        adminToken = accounts.admin("Lizmo Staff").token();
        landlordToken = accounts.landlord("elena").token();

        Accounts.Account ana = accounts.tenant("ana");
        tenantToken = ana.token();

        propertyId = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        bedUnitId = json.readTree(mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        bedId = json.readTree(mvc.perform(get("/api/v1/units/" + bedUnitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();

        makeReadyForALease(tenantToken);
    }

    private void lockIt() throws Exception {
        mvc.perform(post("/api/v1/admin/properties/" + propertyId + "/lock")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accountStatus").value("LOCKED"));
    }

    /** @return the conversation they started */
    private String askAboutThePlace() throws Exception {
        return askAbout(tenantToken, propertyId);
    }

    /** The landlord trying to write the bed into a lease. */
    private org.springframework.test.web.servlet.ResultActions giveThemTheBed(String thread)
            throws Exception {
        return mvc.perform(post("/api/v1/inquiries/" + thread + "/lease")
                .header("Authorization", "Bearer " + landlordToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"unitId":"%s","bedId":"%s","startDate":"2026-10-01"}
                        """.formatted(bedUnitId, bedId)));
    }

    // ---- what locking stops ------------------------------------------------

    @Test
    void a_locked_property_takes_no_new_tenants() throws Exception {
        String thread = askAboutThePlace();
        lockIt();

        // The point of the mechanism: an unpaid property does not grow.
        giveThemTheBed(thread)
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("ACCOUNT_LOCKED_UNPAID_INVOICE"));
    }

    @Test
    void a_locked_property_grows_no_further() throws Exception {
        lockIt();

        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"3C","floor":"3","rentalMode":"WHOLE_UNIT",
                                 "rent":9000.00}
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    void one_locked_property_stops_a_landlord_starting_another() throws Exception {
        lockIt();

        // The hole a per-property lock would otherwise open: lock one building
        // and simply make another. This is the single rule that stays
        // landlord-shaped, and it is derived rather than stored.
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Another one","address":"9 Rizal St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("ACCOUNT_LOCKED_UNPAID_INVOICE"));
    }

    // ---- what locking must never stop --------------------------------------

    @Test
    void a_locked_property_can_still_answer_no() throws Exception {
        String thread = askAboutThePlace();
        lockIt();

        // The tenant waiting for an answer is not the one who owes Lizmo money.
        // Blocking this leaves their conversation open for ever, about a room
        // they could be looking for elsewhere.
        mvc.perform(post("/api/v1/inquiries/" + thread + "/close")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CLOSED"));
    }

    @Test
    void a_locked_property_can_still_end_a_tenancy() throws Exception {
        String thread = askAboutThePlace();
        String leaseId = json.readTree(giveThemTheBed(thread)
                        .andExpect(status().isOk())
                        .andReturn().getResponse().getContentAsString()).get("id").asText();

        lockIt();

        // Ending a lease is the write that *lowers* the invoice. Blocking it
        // would mean billing for a bed the landlord may not mark empty -- and
        // the tenant who moved out would keep seeing an active lease.
        mvc.perform(post("/api/v1/leases/" + leaseId + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"2026-11-30\",\"reason\":\"Moved out\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void a_locked_property_is_still_readable() throws Exception {
        lockIt();

        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());
    }

    @Test
    void unlocking_gives_everything_back() throws Exception {
        lockIt();
        mvc.perform(post("/api/v1/admin/properties/" + propertyId + "/unlock")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accountStatus").value("ACTIVE"));

        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"3C","floor":"3","rentalMode":"WHOLE_UNIT",
                                 "rent":9000.00}
                                """))
                .andExpect(status().isCreated());
    }

    @Test
    void a_landlords_other_properties_are_untouched() throws Exception {
        String second = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Second House","address":"9 Rizal St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        lockIt();

        // The whole reason the lock moved off the landlord: three buildings,
        // one unpaid invoice, two businesses that carry on.
        mvc.perform(post("/api/v1/properties/" + second + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","floor":"1","rentalMode":"WHOLE_UNIT",
                                 "rent":8000.00}
                                """))
                .andExpect(status().isCreated());
    }

    // ---- who may lock ------------------------------------------------------

    @Test
    void a_landlord_cannot_unlock_their_own_property() throws Exception {
        lockIt();

        mvc.perform(post("/api/v1/admin/properties/" + propertyId + "/unlock")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isForbidden());
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
            upload(token, kind);
        }
    }

    private ResultActions upload(String token, String docType) throws Exception {
        BufferedImage image = new BufferedImage(8, 8, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setPaint(Color.GRAY);
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", bytes);

        return mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "id.jpg", "image/jpeg",
                                bytes.toByteArray()))
                        .param("docType", docType)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isCreated());
    }
}
