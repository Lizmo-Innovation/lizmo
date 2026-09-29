package app.lizmo.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.lease.LeaseRepository;
import app.lizmo.lease.LeaseStatus;
import app.lizmo.support.Accounts;
import app.lizmo.support.InMemoryDocumentStore;
import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

/**
 * Leaving.
 *
 * <p>Required by Google Play, and the shape of it is a product decision: a
 * tenancy is a record between two people. What a person can take with them
 * when they go, and what stays because it is somebody else's record too, is
 * the whole of this class.
 */
class AccountDeletionIntegrationTest extends IntegrationTest {

    @Autowired
    private StoredDocumentRepository documents;

    @Autowired
    private InMemoryDocumentStore store;

    @Autowired
    private UserRepository users;

    @Autowired
    private TenantProfileRepository tenantProfiles;

    @Autowired
    private LeaseRepository leases;

    // ---- what stops it ----------------------------------------------------

    @Test
    void a_tenant_in_a_tenancy_cannot_leave_yet() throws Exception {
        var world = aTenancy();

        // The lease is the landlord's arrangement too. Somebody walking out of
        // the app does not end it, and pretending otherwise would leave a
        // landlord with a bed they believe is let and nobody in it.
        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + world.tenantToken()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ACCOUNT_HAS_ACTIVE_LEASE"))
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.containsString("landlord")));
    }

    @Test
    void a_landlord_with_tenants_cannot_leave_yet() throws Exception {
        var world = aTenancy();

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + world.landlordToken()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ACCOUNT_HAS_ACTIVE_LEASE"));
    }

    @Test
    void the_app_can_ask_before_it_offers_to_delete() throws Exception {
        var world = aTenancy();

        // Asked before the confirmation screen, so somebody is told why not
        // while they can still do something about it.
        mvc.perform(get("/api/v1/me/deletable")
                        .header("Authorization", "Bearer " + world.tenantToken()))
                .andExpect(status().isConflict());

        mvc.perform(get("/api/v1/me/deletable")
                        .header("Authorization", "Bearer " + accounts.tenant("bea").token()))
                .andExpect(status().isNoContent());
    }

    // ---- what leaving does ------------------------------------------------

    @Test
    void the_photographs_are_actually_deleted() throws Exception {
        Accounts.Account ana = accounts.tenant("Ana");
        upload(ana.token(), "VALID_ID");
        upload(ana.token(), "TENANT_PHOTO");

        int before = store.size();
        assertThat(documents.findByOwnerTypeAndOwnerId(DocumentOwnerType.TENANT, ana.id()))
                .hasSize(2);

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isNoContent());

        // Out of the database and out of storage. A row deleted while the
        // object stays in a bucket is not deletion — the photograph of a
        // government ID is the thing somebody wants gone.
        assertThat(documents.findByOwnerTypeAndOwnerId(DocumentOwnerType.TENANT, ana.id()))
                .isEmpty();
        assertThat(store.size()).isEqualTo(before - 2);
    }

    @Test
    void nothing_that_names_them_is_left() throws Exception {
        Accounts.Account ana = accounts.tenant("Ana");
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + ana.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
                                 "emergencyContactPhone":"09171234567",
                                 "idType":"PHILSYS","idNumber":"1234-5678-9012",
                                 "occupation":"Nurse","birthdate":"1998-04-12",
                                 "permanentAddress":"Brgy. San Isidro"}
                                """))
                .andExpect(status().isOk());

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isNoContent());

        User closed = users.findById(ana.id()).orElseThrow();
        assertThat(closed.getName()).isEqualTo("Deleted account");
        assertThat(closed.getPhone()).isNull();
        assertThat(closed.getEmail()).doesNotContain("ana");
        assertThat(closed.isDeleted()).isTrue();
        assertThat(closed.isActive()).isFalse();

        // The profile row survives, because leases point at it. Everything
        // inside it does not.
        TenantProfile profile = tenantProfiles.findById(ana.id()).orElseThrow();
        assertThat(profile.getIdNumber()).isNull();
        assertThat(profile.getBirthdate()).isNull();
        assertThat(profile.getEmergencyContactName()).isNull();
        assertThat(profile.getPermanentAddress()).isNull();
    }

    @Test
    void every_session_ends() throws Exception {
        Accounts.Account ana = accounts.tenant("Ana");
        String refresh = json.readTree(mvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"identifier":"%s","password":"%s"}
                                """.formatted(ana.email(), Accounts.PASSWORD)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("refreshToken").asText();

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isNoContent());

        // A refresh token in another device's storage is a session too.
        mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"%s\"}".formatted(refresh)))
                .andExpect(status().isUnauthorized());

        mvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"identifier":"%s","password":"%s"}
                                """.formatted(ana.email(), Accounts.PASSWORD)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void the_address_is_free_to_use_again() throws Exception {
        Accounts.Account ana = accounts.tenant("Ana");
        String email = ana.email();

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isNoContent());

        // An address held for ever is one somebody can never use to come back,
        // and it is still their email address sitting in a database after they
        // asked to be forgotten.
        mvc.perform(post("/api/v1/auth/register/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\"}".formatted(email)))
                .andExpect(status().isOk());
    }

    @Test
    void a_past_tenancy_survives_for_the_landlord() throws Exception {
        var world = aTenancy();

        mvc.perform(post("/api/v1/leases/" + world.leaseId() + "/end")
                        .header("Authorization", "Bearer " + world.landlordToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"2026-11-30\",\"reason\":\"Moved out\"}"))
                .andExpect(status().isOk());

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + world.tenantToken()))
                .andExpect(status().isNoContent());

        // The landlord's record of their own property does not disappear
        // because the other party left. Read from the database rather than
        // from /properties/{id}/leases, which answers "who is living here" and
        // so lists active tenancies only.
        assertThat(leases.findByTenantIdOrderByStartDateDesc(world.tenantId()))
                .singleElement()
                .satisfies(lease -> {
                    assertThat(lease.getStatus()).isEqualTo(LeaseStatus.ENDED);
                    assertThat(lease.getRentAmount()).isNotNull();
                });
    }

    /**
     * Lease attachments outlive the tenancy on purpose, so nothing else ever
     * removes them. Closing the landlord's account is the one thing that does:
     * they are the landlord's records, and they end when the landlord does.
     */
    @Test
    void a_landlords_paperwork_goes_with_them() throws Exception {
        var world = aTenancy();

        mvc.perform(multipart("/api/v1/leases/" + world.leaseId() + "/documents")
                        .file(new MockMultipartFile(
                                "file", "c.pdf", null, "%PDF-1.7\ncontract\n".getBytes()))
                        .header("Authorization", "Bearer " + world.landlordToken())
                        .param("docType", "LEASE_CONTRACT"))
                .andExpect(status().isCreated());

        assertThat(paperworkOn(world.leaseId())).hasSize(1);

        mvc.perform(post("/api/v1/leases/" + world.leaseId() + "/end")
                        .header("Authorization", "Bearer " + world.landlordToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"2026-11-30\",\"reason\":\"Moved out\"}"))
                .andExpect(status().isOk());

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + world.landlordToken()))
                .andExpect(status().isNoContent());

        // The file, not only the row. An object left in a bucket that nothing
        // points at is one nobody will ever delete.
        assertThat(paperworkOn(world.leaseId())).isEmpty();
    }

    /**
     * A contract is an agreement between two people, and one of them leaving
     * does not entitle them to shred the other's copy.
     */
    @Test
    void a_tenant_leaving_does_not_take_the_landlords_paperwork() throws Exception {
        var world = aTenancy();

        mvc.perform(multipart("/api/v1/leases/" + world.leaseId() + "/documents")
                        .file(new MockMultipartFile(
                                "file", "c.pdf", null, "%PDF-1.7\ncontract\n".getBytes()))
                        .header("Authorization", "Bearer " + world.landlordToken())
                        .param("docType", "LEASE_CONTRACT"))
                .andExpect(status().isCreated());

        mvc.perform(post("/api/v1/leases/" + world.leaseId() + "/end")
                        .header("Authorization", "Bearer " + world.landlordToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"2026-11-30\",\"reason\":\"Moved out\"}"))
                .andExpect(status().isOk());

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + world.tenantToken()))
                .andExpect(status().isNoContent());

        assertThat(paperworkOn(world.leaseId())).hasSize(1);
        mvc.perform(get("/api/v1/leases/" + world.leaseId() + "/documents")
                        .header("Authorization", "Bearer " + world.landlordToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    /**
     * What is filed against <em>this</em> lease.
     *
     * <p>Scoped to the one lease on purpose. The document store is a singleton
     * shared by every test class, so a count of everything under "leases/"
     * tallies paperwork left behind by other tests and says nothing about the
     * account under test -- it would fail while the rule was correct, which is
     * a mistake this suite has made before.
     */
    private java.util.Map<String, ?> paperworkOn(String leaseId) {
        return store.all().entrySet().stream()
                .filter(entry -> entry.getKey().startsWith("leases/" + leaseId + "/"))
                .collect(java.util.stream.Collectors.toMap(
                        java.util.Map.Entry::getKey, java.util.Map.Entry::getValue));
    }

    // ---- a world with somebody living in it --------------------------------

    private record World(
            String landlordToken, String tenantToken, java.util.UUID tenantId,
            String propertyId, String leaseId) {}

    private World aTenancy() throws Exception {
        String landlordToken = accounts.landlord("elena").token();
        Accounts.Account ana = accounts.tenant("ana");

        String propertyId = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        String unitId = json.readTree(mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        String bedId = json.readTree(mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();

        readyForALease(ana.token());

        String requestId = json.readTree(mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + ana.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}"
                                .formatted(unitId, bedId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        String leaseId = json.readTree(mvc.perform(post("/api/v1/rental-requests/" + requestId + "/accept")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"monthlyRent\":2500.00,\"startDate\":\"2026-10-01\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        return new World(landlordToken, ana.token(), ana.id(), propertyId, leaseId);
    }

    private void readyForALease(String token) throws Exception {
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
        upload(token, "VALID_ID");
        upload(token, "TENANT_PHOTO");
    }

    private void upload(String token, String docType) throws Exception {
        BufferedImage image = new BufferedImage(8, 8, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setPaint(Color.GRAY);
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", bytes);

        mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "id.jpg", "image/jpeg",
                                bytes.toByteArray()))
                        .param("docType", docType)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isCreated());
    }
}
