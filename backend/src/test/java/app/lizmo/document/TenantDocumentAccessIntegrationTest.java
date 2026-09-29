package app.lizmo.document;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.InMemoryDocumentStore;
import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

/**
 * A landlord looking at the ID of somebody living in their room, and the year
 * after which nobody looks at it again.
 *
 * <p>This finishes the tenant-document story, which has been waiting on leases
 * since the photographs were built. Both halves of the promise made then are
 * asserted here: seen only through a live lease, and gone a year after the last
 * one ended.
 */
class TenantDocumentAccessIntegrationTest extends IntegrationTest {

    @Autowired
    private DocumentRetentionService retention;

    @Autowired
    private InMemoryDocumentStore store;

    private String landlordToken;
    private String otherLandlordToken;
    private String anaToken;
    private String beaToken;

    private String propertyId;
    private String unitId;
    private String bedId;

    @BeforeEach
    void setUp() throws Exception {
        store.clear();

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

    /** @return the lease id */
    private String let(String tenantToken) throws Exception {
        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}"
                                .formatted(unitId, bedId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String lease = mvc.perform(post("/api/v1/rental-requests/"
                        + json.readTree(request).get("id").asText() + "/accept")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(lease).get("id").asText();
    }

    // ---- who may look -----------------------------------------------------

    @Test
    void a_landlord_sees_the_id_of_the_person_in_their_room() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant-documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                // Signed and short-lived, the same as the tenant's own view.
                .andExpect(jsonPath("$[0].url").exists())
                .andExpect(jsonPath("$[0].urlExpiresInSeconds").value(600));
    }

    @Test
    void access_ends_with_the_tenancy() throws Exception {
        String lease = let(anaToken);

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        // The reason they were shown an ID was to let a room. That reason
        // expires with the tenancy, and so does the access -- a landlord cannot
        // go back afterwards for a copy.
        mvc.perform(get("/api/v1/leases/" + lease + "/tenant-documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void another_landlord_sees_nothing() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant-documents")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_read_another_tenant_documents_through_a_lease()
            throws Exception {
        String lease = let(anaToken);

        // Bea is not the landlord, so the property check refuses her — the same
        // path that stops a stranger holding a lease id.
        mvc.perform(get("/api/v1/leases/" + lease + "/tenant-documents")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void there_is_no_way_to_ask_by_person() throws Exception {
        let(anaToken);

        // The API answers "the documents of whoever holds this lease", never
        // "the documents of this person". A tenant id is not a key to anything.
        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                // The landlord gets their own, which are none.
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void reading_requires_signing_in() throws Exception {
        String lease = let(anaToken);

        mvc.perform(get("/api/v1/leases/" + lease + "/tenant-documents"))
                .andExpect(status().isUnauthorized());
    }

    // ---- the year afterwards ---------------------------------------------

    @Test
    void a_tenant_still_renting_keeps_their_documents() throws Exception {
        let(anaToken);

        // Even years later. An ID is needed for the tenancy they are in.
        //
        // Asserted on this tenant rather than on how many documents the sweep
        // removed: every test class shares one database, so the tally counts
        // tenants left behind by other tests and says nothing about Ana.
        retention.purgeAsOf(LocalDate.now().plusYears(5));

        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void documents_survive_the_first_year_after_a_tenancy() throws Exception {
        String lease = let(anaToken);
        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        // A dispute about a tenancy does not end the day somebody moves out.
        retention.purgeAsOf(LocalDate.now().plusDays(364));

        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void documents_go_a_year_after_the_last_tenancy_ends() throws Exception {
        String lease = let(anaToken);
        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        retention.purgeAsOf(LocalDate.now().plusDays(366));

        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void the_files_go_too_not_only_the_rows() throws Exception {
        String lease = let(anaToken);
        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        assertThat(store.size()).isEqualTo(2);
        retention.purgeAsOf(LocalDate.now().plusDays(366));

        // Deleting the row alone would leave the photograph sitting in the
        // bucket with nothing pointing at it, which is the thing this whole
        // service exists to prevent.
        assertThat(store.size()).isZero();
    }

    @Test
    void a_second_tenancy_resets_the_clock() throws Exception {
        String first = let(anaToken);
        mvc.perform(post("/api/v1/leases/" + first + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        // They rent again. Their documents belong to them, not to the tenancy
        // that happened to end first.
        let(anaToken);

        retention.purgeAsOf(LocalDate.now().plusDays(400));

        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void somebody_who_never_rented_is_left_alone() throws Exception {
        makeReadyForALease(beaToken);

        // Bea has a profile and photographs and has never signed a lease. She
        // is still using the app, and nothing of hers has expired because
        // nothing ever started.
        retention.purgeAsOf(LocalDate.now().plusYears(5));

        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.length()").value(2));
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
