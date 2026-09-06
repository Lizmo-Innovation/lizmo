package app.lizmo.lease;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.InMemoryDocumentStore;
import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * The paperwork a landlord keeps against a tenancy.
 *
 * <p>Two rules carry most of the weight here. These outlive the tenancy, unlike
 * everything else addressed by lease -- a dispute happens after somebody has
 * moved out, which is exactly when the contract is wanted. And the landlord
 * decides one document at a time which of them the tenant may also read.
 */
class LeaseDocumentIntegrationTest extends IntegrationTest {

    @Autowired
    private InMemoryDocumentStore store;

    private String landlordToken;
    private String otherLandlordToken;
    private String anaToken;
    private String beaToken;

    private String unitId;
    private String bedId;
    private String leaseId;

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

        String unit = mvc.perform(post("/api/v1/properties/"
                        + json.readTree(property).get("id").asText() + "/units")
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
        leaseId = let(anaToken);
    }

    // ---- attaching --------------------------------------------------------

    @Test
    void a_landlord_can_file_a_contract_against_a_tenancy() throws Exception {
        attach(pdf(), "Signed contract", "LEASE_CONTRACT", true)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.label").value("Signed contract"))
                .andExpect(jsonPath("$.docType").value("LEASE_CONTRACT"))
                .andExpect(jsonPath("$.contentType").value("application/pdf"))
                .andExpect(jsonPath("$.sharedWithTenant").value(true))
                .andExpect(jsonPath("$.url").isNotEmpty());

        mvc.perform(get("/api/v1/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void a_lease_holds_more_than_one() throws Exception {
        attach(pdf(), "Signed contract", "LEASE_CONTRACT", true).andExpect(status().isCreated());
        attach(photo(), "Deposit receipt", "RECEIPT", true).andExpect(status().isCreated());

        mvc.perform(get("/api/v1/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(2));
    }

    /**
     * A PDF is kept exactly as it arrived. There is no metadata scrub for one,
     * and rewriting a signed document would change the artefact somebody may
     * later have to rely on.
     */
    @Test
    void a_pdf_is_stored_untouched() throws Exception {
        byte[] original = pdf();
        String body = attach(original, "Contract", "LEASE_CONTRACT", true)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        assertThat(json.readTree(body).get("byteSize").asLong())
                .isEqualTo(original.length);
        // By key prefix, not "the only object": the tenant's own two
        // photographs are in the same store, uploaded to make them lettable.
        assertThat(leaseObjects()).hasSize(1);
        assertThat(leaseObjects().values().iterator().next().bytes()).isEqualTo(original);
    }

    /** A photograph goes through the same scrub as everything else. */
    @Test
    void a_photograph_is_re_encoded() throws Exception {
        attach(photo(), "Receipt", "RECEIPT", true)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.contentType").value("image/jpeg"));
    }

    @Test
    void a_tenants_own_kinds_cannot_be_filed_here() throws Exception {
        // VALID_ID and TENANT_PHOTO belong to the tenant, who uploads them
        // about themselves. A landlord filing one here would make "the
        // tenant's ID" a question with two answers.
        attach(photo(), "Their ID", "VALID_ID", true)
                .andExpect(status().isBadRequest());
    }

    @Test
    void an_unnamed_document_still_reads_as_something() throws Exception {
        attach(pdf(), null, "LEASE_CONTRACT", true)
                .andExpect(status().isCreated())
                // Better than an empty row in a list.
                .andExpect(jsonPath("$.label").value("Lease contract"));
    }

    // ---- who can see it ---------------------------------------------------

    @Test
    void the_tenant_sees_what_was_shared_with_them() throws Exception {
        attach(pdf(), "Signed contract", "LEASE_CONTRACT", true).andExpect(status().isCreated());

        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].label").value("Signed contract"));
    }

    @Test
    void the_tenant_does_not_see_what_was_not() throws Exception {
        attach(pdf(), "My own notes", "OTHER", false).andExpect(status().isCreated());

        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        // The landlord still has it.
        mvc.perform(get("/api/v1/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void sharing_can_be_turned_on_and_off_afterwards() throws Exception {
        String created = attach(pdf(), "Clearance", "OTHER", false)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String documentId = json.readTree(created).get("id").asText();

        mvc.perform(patch("/api/v1/leases/" + leaseId + "/documents/" + documentId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .param("sharedWithTenant", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sharedWithTenant").value(true));

        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(1));

        mvc.perform(patch("/api/v1/leases/" + leaseId + "/documents/" + documentId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .param("sharedWithTenant", "false"))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void a_document_can_be_renamed() throws Exception {
        String created = attach(pdf(), "Contarct", "LEASE_CONTRACT", true)
                .andReturn().getResponse().getContentAsString();

        mvc.perform(patch("/api/v1/leases/" + leaseId + "/documents/"
                        + json.readTree(created).get("id").asText())
                        .header("Authorization", "Bearer " + landlordToken)
                        .param("label", "Contract"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.label").value("Contract"));
    }

    @Test
    void another_landlord_sees_nothing_and_can_attach_nothing() throws Exception {
        attach(pdf(), "Signed contract", "LEASE_CONTRACT", true).andExpect(status().isCreated());

        mvc.perform(get("/api/v1/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());

        mvc.perform(multipart("/api/v1/leases/" + leaseId + "/documents")
                        .file(new MockMultipartFile("file", "x.pdf", "application/pdf", pdf()))
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void another_tenant_cannot_read_them() throws Exception {
        attach(pdf(), "Signed contract", "LEASE_CONTRACT", true).andExpect(status().isCreated());

        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_attach_anything() throws Exception {
        mvc.perform(multipart("/api/v1/leases/" + leaseId + "/documents")
                        .file(new MockMultipartFile("file", "x.pdf", "application/pdf", pdf()))
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isNotFound());
    }

    // ---- outliving the tenancy --------------------------------------------

    /**
     * The rule this feature turns on. Every other thing addressed by lease
     * closes when the tenancy does, which is right for a tenant's ID and
     * exactly wrong for a signed contract: the dispute comes afterwards.
     */
    @Test
    void the_paperwork_outlives_the_tenancy() throws Exception {
        attach(pdf(), "Signed contract", "LEASE_CONTRACT", true).andExpect(status().isCreated());

        mvc.perform(post("/api/v1/leases/" + leaseId + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        // The tenant's ID has gone, as it should.
        mvc.perform(get("/api/v1/leases/" + leaseId + "/tenant")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());

        // The contract has not.
        mvc.perform(get("/api/v1/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void a_former_tenant_keeps_their_copy() throws Exception {
        attach(pdf(), "Signed contract", "LEASE_CONTRACT", true).andExpect(status().isCreated());

        mvc.perform(post("/api/v1/leases/" + leaseId + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        // A copy of what you signed is worth having after you move out.
        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    // ---- removing ---------------------------------------------------------

    @Test
    void deleting_takes_the_file_with_the_record() throws Exception {
        String created = attach(pdf(), "Signed contract", "LEASE_CONTRACT", true)
                .andReturn().getResponse().getContentAsString();

        assertThat(leaseObjects()).hasSize(1);

        mvc.perform(delete("/api/v1/leases/" + leaseId + "/documents/"
                        + json.readTree(created).get("id").asText())
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        // A row deleted while the object stays in a bucket is the failure worth
        // testing for: the file is the thing somebody wanted gone.
        assertThat(leaseObjects()).isEmpty();
        mvc.perform(get("/api/v1/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void a_document_id_from_elsewhere_is_refused() throws Exception {
        String created = attach(pdf(), "Signed contract", "LEASE_CONTRACT", true)
                .andReturn().getResponse().getContentAsString();
        String documentId = json.readTree(created).get("id").asText();

        // A second lease, owned by the same landlord. Owning the lease in the
        // path must not be enough to reach a document filed against another.
        makeReadyForALease(beaToken);
        String secondLease = letBed(beaToken, 1);

        mvc.perform(delete("/api/v1/leases/" + secondLease + "/documents/" + documentId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());

        mvc.perform(get("/api/v1/leases/" + leaseId + "/documents")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(1));
    }

    // ---- fixtures ---------------------------------------------------------

    /** Only what was filed against a lease, never the tenant's own photographs. */
    private java.util.Map<String, InMemoryDocumentStore.Stored> leaseObjects() {
        return store.all().entrySet().stream()
                .filter(entry -> entry.getKey().startsWith("leases/"))
                .collect(java.util.stream.Collectors.toMap(
                        java.util.Map.Entry::getKey, java.util.Map.Entry::getValue));
    }

    private ResultActions attach(
            byte[] bytes, String label, String docType, boolean shared) throws Exception {
        var call = multipart("/api/v1/leases/" + leaseId + "/documents")
                .file(new MockMultipartFile("file", "upload", null, bytes))
                .header("Authorization", "Bearer " + landlordToken)
                .param("docType", docType)
                .param("sharedWithTenant", String.valueOf(shared));
        if (label != null) {
            call = call.param("label", label);
        }
        return mvc.perform(call);
    }

    /** @return the lease id */
    private String let(String tenantToken) throws Exception {
        return letBed(tenantToken, 0);
    }

    private String letBed(String tenantToken, int index) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bed = json.readTree(beds).get(index).get("id").asText();

        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}"
                                .formatted(unitId, bed)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String lease = mvc.perform(post("/api/v1/rental-requests/"
                        + json.readTree(request).get("id").asText() + "/accept")
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

    /** Enough of a PDF to be recognised by its first five bytes, which is how the server decides. */
    private static byte[] pdf() {
        return "%PDF-1.7\nsigned lease contract\n%%EOF\n"
                .getBytes(StandardCharsets.UTF_8);
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
