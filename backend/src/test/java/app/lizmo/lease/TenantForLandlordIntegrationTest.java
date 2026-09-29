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

/**
 * The landlord reading the details of somebody living in their room.
 *
 * <p>Closes a hole rather than adding a feature. A tenant could not so much as
 * ask about a bed without supplying an emergency contact and an ID number, and
 * once they had moved in, the one person those exist for could not read either.
 * The request view withholds them on purpose — anybody can put up a listing —
 * and nothing released them afterwards.
 *
 * <p>So these tests are mostly about the boundary: through a live lease, on
 * your own property, and not one day past the tenancy.
 */
class TenantForLandlordIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String otherLandlordToken;
    private String anaToken;
    private String beaToken;

    private String unitId;
    private String bedId;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        otherLandlordToken = accounts.landlord("mario").token();
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
        String propertyId = json.readTree(property).get("id").asText();

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

    // ---- what unlocks -----------------------------------------------------

    @Test
    void the_landlord_can_reach_the_emergency_contact() throws Exception {
        String lease = let(anaToken);

        // The whole reason the tenant was made to supply this before they could
        // ask about a bed.
        mvc.perform(get("/api/v1/leases/" + lease + "/tenant")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.emergencyContactName").value("Rosa Dela Cruz"))
                .andExpect(jsonPath("$.emergencyContactPhone").value("09171234567"));
    }

    @Test
    void the_id_number_is_released_once_they_have_moved_in() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.idType").value("PHILSYS"))
                .andExpect(jsonPath("$.idNumber").value("1234-5678-9012"));
    }

    /**
     * The same number the request view withholds. Worth asserting from both
     * ends: the two records are deliberately different shapes, and a change
     * that quietly made them the same would defeat the point of either.
     */
    @Test
    void a_pending_request_still_withholds_what_a_lease_releases()
            throws Exception {
        String request = ask(anaToken);

        String pending = mvc.perform(get("/api/v1/rental-requests/" + request)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        org.assertj.core.api.Assertions.assertThat(pending)
                .doesNotContain("1234-5678-9012")
                .doesNotContain("Rosa Dela Cruz");
    }

    @Test
    void the_age_is_worked_out_here_not_in_the_app() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
                                 "emergencyContactPhone":"09171234567",
                                 "idType":"PHILSYS","idNumber":"1234-5678-9012",
                                 "birthdate":"2000-01-01"}
                                """))
                .andExpect(status().isOk());

        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.birthdate").value("2000-01-01"))
                .andExpect(jsonPath("$.age").isNumber());
    }

    /** A tenant who gave no birthday has no age, and no age is not zero. */
    @Test
    void no_birthday_means_no_age() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.age").doesNotExist());
    }

    // ---- the list they come from ------------------------------------------

    @Test
    void the_tenant_list_spans_every_property() throws Exception {
        let(anaToken);

        // A second property, with its own tenant, so the test would fail if
        // this only ever looked at one of them.
        makeReadyForALease(beaToken);
        String other = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Second House","address":"9 Rizal Ave",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String otherUnit = mvc.perform(post("/api/v1/properties/"
                        + json.readTree(other).get("id").asText() + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","floor":"1",
                                 "rentalMode":"WHOLE_UNIT","rent":9000.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + beaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\"}"
                                .formatted(json.readTree(otherUnit).get("id").asText())))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        mvc.perform(post("/api/v1/rental-requests/"
                        + json.readTree(request).get("id").asText() + "/accept")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/tenants")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void a_landlord_sees_only_their_own_tenants() throws Exception {
        let(anaToken);

        mvc.perform(get("/api/v1/me/tenants")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    /** Somebody who moved out is not living in the building. */
    @Test
    void an_ended_tenancy_leaves_the_list() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/me/tenants")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(1));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/tenants")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(0));
    }

    // ---- and what does not ------------------------------------------------

    @Test
    void access_ends_with_the_tenancy() throws Exception {
        String lease = let(anaToken);

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        // A landlord who housed somebody cannot go back afterwards for their
        // ID number. The reason they were shown it expired with the tenancy.
        mvc.perform(get("/api/v1/leases/" + lease + "/tenant")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void another_landlord_sees_nothing() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_read_another_tenant_through_a_lease() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void reading_requires_signing_in() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant"))
                .andExpect(status().isUnauthorized());
    }

    // ---- fixtures ---------------------------------------------------------

    /** @return the request id */
    private String ask(String tenantToken) throws Exception {
        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}"
                                .formatted(unitId, bedId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(request).get("id").asText();
    }

    /** @return the lease id */
    private String let(String tenantToken) throws Exception {
        String lease = mvc.perform(post("/api/v1/rental-requests/"
                        + ask(tenantToken) + "/accept")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(lease).get("id").asText();
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
