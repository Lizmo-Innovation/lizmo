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
import java.time.LocalDate;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

/**
 * Reading leases, and ending them.
 *
 * <p>The letting-again tests are the reason this class matters. Both
 * exclusivity indexes are partial on ACTIVE, and a partial index written even
 * slightly wrong produces a bed that its first tenant poisons for good — free
 * on the screen, and refused every time anybody asks for it.
 */
class LeaseIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String otherLandlordToken;
    private String anaToken;
    private String beaToken;

    private String propertyId;
    private String code;
    private String bedUnitId;
    private String wholeUnitId;
    private String bed1;
    private String bed2;

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
        propertyId = json.readTree(property).get("id").asText();
        code = json.readTree(property).get("code").asText();

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
    private String let(String tenantToken, String unitId, String bedId) throws Exception {
        String body = bedId == null
                ? "{\"unitId\":\"%s\"}".formatted(unitId)
                : "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bedId);
        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String requestId = json.readTree(request).get("id").asText();

        String lease = mvc.perform(post("/api/v1/rental-requests/" + requestId + "/accept")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(lease).get("id").asText();
    }

    private org.springframework.test.web.servlet.ResultActions endLease(
            String leaseId, String body) throws Exception {
        var call = post("/api/v1/leases/" + leaseId + "/end")
                .header("Authorization", "Bearer " + landlordToken);
        if (body != null) {
            call = call.contentType(MediaType.APPLICATION_JSON).content(body);
        }
        return mvc.perform(call);
    }

    // ---- reading ----------------------------------------------------------

    @Test
    void a_tenant_sees_their_own_lease() throws Exception {
        let(anaToken, bedUnitId, bed1);

        mvc.perform(get("/api/v1/me/leases")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].propertyName").value("Sunrise Apartments"))
                .andExpect(jsonPath("$[0].unitNumber").value("2B"))
                .andExpect(jsonPath("$[0].status").value("ACTIVE"));
    }

    @Test
    void a_tenant_does_not_see_somebody_else_lease() throws Exception {
        let(anaToken, bedUnitId, bed1);

        mvc.perform(get("/api/v1/me/leases")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void a_landlord_sees_who_is_living_in_their_property() throws Exception {
        let(anaToken, bedUnitId, bed1);
        let(beaToken, wholeUnitId, null);

        mvc.perform(get("/api/v1/properties/" + propertyId + "/leases")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void another_landlord_sees_nothing_of_it() throws Exception {
        let(anaToken, bedUnitId, bed1);

        mvc.perform(get("/api/v1/properties/" + propertyId + "/leases")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    // ---- ending, and letting again ---------------------------------------

    @Test
    void ending_a_lease_gives_the_bed_back() throws Exception {
        String lease = let(anaToken, bedUnitId, bed1);

        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.vacantBeds").value(1));

        endLease(lease, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ENDED"))
                .andExpect(jsonPath("$.endDate").value(LocalDate.now().toString()));

        // Back on the list a tenant scanning the gate is shown.
        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.vacantBeds").value(2));
    }

    @Test
    void the_bed_can_be_let_to_somebody_new() throws Exception {
        String lease = let(anaToken, bedUnitId, bed1);
        endLease(lease, null).andExpect(status().isOk());

        // The test this class exists for. Both unique indexes are partial on
        // ACTIVE; written even slightly wrong, the first tenant poisons the bed
        // for good and nobody can ever be accepted for it again.
        let(beaToken, bedUnitId, bed1);

        mvc.perform(get("/api/v1/properties/" + propertyId + "/leases")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].tenantName").value("bea"));
    }

    @Test
    void a_whole_unit_can_be_let_again_too() throws Exception {
        String lease = let(anaToken, wholeUnitId, null);
        endLease(lease, null).andExpect(status().isOk());

        // uq_active_lease_per_unit is the index that went missing in the V8
        // repair. This is the other half of proving it is back and correct.
        let(beaToken, wholeUnitId, null);
    }

    @Test
    void a_room_goes_back_to_partly_occupied_when_one_tenant_leaves()
            throws Exception {
        String first = let(anaToken, bedUnitId, bed1);
        let(beaToken, bedUnitId, bed2);

        mvc.perform(get("/api/v1/units/" + bedUnitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.status").value("OCCUPIED"));

        endLease(first, null).andExpect(status().isOk());

        // Counted, not assumed: one tenant leaving a two-bed room does not make
        // the room vacant.
        mvc.perform(get("/api/v1/units/" + bedUnitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.status").value("PARTIALLY_OCCUPIED"));
    }

    @Test
    void a_bed_out_of_service_does_not_come_back_when_a_neighbour_leaves()
            throws Exception {
        String first = let(anaToken, bedUnitId, bed1);

        mvc.perform(put("/api/v1/beds/" + bed2 + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"underMaintenance\":true}"))
                .andExpect(status().isOk());

        endLease(first, null).andExpect(status().isOk());

        // Only bed1 is free. A bed the landlord shut must not creep back onto
        // the vacancy list because somebody else moved out.
        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.vacantBeds").value(1));
    }

    @Test
    void a_tenancy_stopped_early_is_recorded_as_such() throws Exception {
        String lease = let(anaToken, bedUnitId, bed1);

        // Relative to today, not a date typed into the test. A fixed one was
        // in the future when this was written and in the past by October,
        // which failed as a lease ending before it began -- a test that
        // rots on a calendar rather than on the behaviour it guards.
        String leavingDay = LocalDate.now().plusDays(10).toString();

        // Two different things to look back on. Flattening them would lose the
        // only record of which happened.
        endLease(lease, "{\"terminated\":true,\"endDate\":\"%s\"}".formatted(leavingDay))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("TERMINATED"))
                .andExpect(jsonPath("$.endDate").value(leavingDay));
    }

    @Test
    void a_lease_cannot_end_before_it_starts() throws Exception {
        String lease = let(anaToken, bedUnitId, bed1);

        // Not a tenancy anybody can reason about, least of all a billing
        // period counting months between two dates.
        endLease(lease, "{\"endDate\":\"2020-01-01\"}")
                .andExpect(status().isBadRequest());
    }

    @Test
    void ending_twice_is_refused() throws Exception {
        String lease = let(anaToken, bedUnitId, bed1);

        endLease(lease, null).andExpect(status().isOk());
        // Otherwise the second call would rewrite when the tenant left.
        endLease(lease, null).andExpect(status().isBadRequest());
    }

    @Test
    void a_tenant_cannot_end_their_own_lease() throws Exception {
        String lease = let(anaToken, bedUnitId, bed1);

        // Moving out is a conversation, not a button. The landlord records it.
        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void another_landlord_cannot_end_it_either() throws Exception {
        String lease = let(anaToken, bedUnitId, bed1);

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void ending_requires_signing_in() throws Exception {
        String lease = let(anaToken, bedUnitId, bed1);

        mvc.perform(post("/api/v1/leases/" + lease + "/end"))
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
