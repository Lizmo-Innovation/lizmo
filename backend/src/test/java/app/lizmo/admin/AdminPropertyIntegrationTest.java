package app.lizmo.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import com.fasterxml.jackson.databind.JsonNode;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * One property, opened up for Lizmo's staff: its units and beds, and who
 * leases which right now.
 *
 * <p>The one admin read that names tenants, and only the current ones -- with
 * their name and how to reach them, never their ID or emergency contact.
 */
class AdminPropertyIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private String adminToken;
    private Accounts.Account elena;
    private Accounts.Account ana;
    private Accounts.Account bea;

    private String propertyId;
    private String bedspaceId;
    private String wholeUnitId;
    private String anasLease;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();
        adminToken = accounts.admin("Lizmo Staff").token();
        elena = accounts.landlord("Elena");
        ana = accounts.tenant("Ana Reyes");
        bea = accounts.tenant("Bea Cruz");

        propertyId = idOf(mvc.perform(post("/api/v1/properties")
                .header("Authorization", "Bearer " + elena.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"name":"Sunrise Apartments","address":"12 Mabini St",
                         "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                        """)));
        bedspaceId = idOf(unit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE","capacity":3,"rent":2500.00}
                """));
        wholeUnitId = idOf(unit("""
                {"unitNumber":"1A","floor":"1","rentalMode":"WHOLE_UNIT","capacity":1,"rent":7000.00}
                """));

        makeReadyForALease(ana.token());
        makeReadyForALease(bea.token());

        // Ana in the first bed, Bea in the whole unit, the third bed out of service.
        anasLease = let(ana.token(), "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(bedspaceId, bed(0)));
        let(bea.token(), "{\"unitId\":\"%s\"}".formatted(wholeUnitId));
        mvc.perform(put("/api/v1/beds/" + bed(2) + "/maintenance")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"underMaintenance\":true}"))
                .andExpect(status().isOk());
    }

    // ---- what an admin sees -------------------------------------------------------

    @Test
    void an_admin_sees_every_unit_and_bed_and_who_leases_them() throws Exception {
        property()
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Sunrise Apartments"))
                .andExpect(jsonPath("$.landlordName").value("Elena"))
                .andExpect(jsonPath("$.unitCount").value(2))
                .andExpect(jsonPath("$.bedCount").value(3))
                .andExpect(jsonPath("$.leased").value(2))
                .andExpect(jsonPath("$.outOfService").value(1))
                // In unit order: the whole unit first, then the shared room.
                .andExpect(jsonPath("$.units[0].unitNumber").value("1A"))
                .andExpect(jsonPath("$.units[0].rentalMode").value("WHOLE_UNIT"))
                .andExpect(jsonPath("$.units[0].occupancy").value("LEASED"))
                .andExpect(jsonPath("$.units[0].tenancy.tenantName").value("Bea Cruz"))
                .andExpect(jsonPath("$.units[0].tenancy.tenantEmail").value(bea.email()))
                .andExpect(jsonPath("$.units[0].tenancy.tenantPhone").value(bea.phone()))
                .andExpect(jsonPath("$.units[0].tenancy.rent").value(2500.00))
                .andExpect(jsonPath("$.units[0].tenancy.startDate").value(LocalDate.now(clock).toString()))
                .andExpect(jsonPath("$.units[1].unitNumber").value("2B"))
                .andExpect(jsonPath("$.units[1].occupancy").value("PARTLY_LEASED"))
                .andExpect(jsonPath("$.units[1].tenancy").doesNotExist())
                .andExpect(jsonPath("$.units[1].beds.length()").value(3))
                .andExpect(jsonPath("$.units[1].beds[0].occupancy").value("LEASED"))
                .andExpect(jsonPath("$.units[1].beds[0].tenancy.tenantName").value("Ana Reyes"))
                .andExpect(jsonPath("$.units[1].beds[0].tenancy.tenantEmail").value(ana.email()))
                .andExpect(jsonPath("$.units[1].beds[1].occupancy").value("VACANT"))
                .andExpect(jsonPath("$.units[1].beds[1].tenancy").doesNotExist())
                .andExpect(jsonPath("$.units[1].beds[2].occupancy").value("OUT_OF_SERVICE"));
    }

    /** Name and contact only: nothing from the tenant's profile beyond that. */
    @Test
    void a_tenancy_carries_no_id_or_emergency_contact() throws Exception {
        String body = property().andReturn().getResponse().getContentAsString();

        assertThat(body)
                .doesNotContain("Rosa Dela Cruz")
                .doesNotContain("09171234567")
                .doesNotContain("1234-5678-9012")
                .doesNotContain("PHILSYS");
    }

    /** Current tenancies only: somebody who has moved out is not named here. */
    @Test
    void a_bed_freed_by_an_ended_tenancy_is_vacant_and_names_nobody() throws Exception {
        mvc.perform(post("/api/v1/leases/" + anasLease + "/end")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\",\"reason\":\"Moved out\"}"
                                .formatted(LocalDate.now(clock))))
                .andExpect(status().isOk());

        String body = property()
                .andExpect(jsonPath("$.units[1].beds[0].occupancy").value("VACANT"))
                .andExpect(jsonPath("$.units[1].beds[0].tenancy").doesNotExist())
                .andExpect(jsonPath("$.leased").value(1))
                .andReturn().getResponse().getContentAsString();
        assertThat(body).doesNotContain("Ana Reyes");
    }

    /** The same count the landlord page shows, so the two never disagree. */
    @Test
    void the_leased_count_matches_the_landlord_page() throws Exception {
        JsonNode landlordPage = json.readTree(mvc.perform(get("/api/v1/admin/landlords/" + elena.id())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        JsonNode summary = landlordPage.path("properties").get(0);
        int occupied = summary.path("occupiedUnits").asInt() + summary.path("occupiedBeds").asInt();

        JsonNode detail = json.readTree(property().andReturn().getResponse().getContentAsString());

        assertThat(detail.path("leased").asInt()).isEqualTo(occupied).isEqualTo(2);
        assertThat(detail.path("bedCount").asInt()).isEqualTo(summary.path("beds").asInt());
        assertThat(detail.path("unitCount").asInt()).isEqualTo(summary.path("units").asInt());
    }

    // ---- who may look ---------------------------------------------------------------

    @Test
    void only_lizmos_staff_can_open_a_property() throws Exception {
        for (String token : new String[] {elena.token(), ana.token()}) {
            mvc.perform(get("/api/v1/admin/properties/" + propertyId)
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isForbidden());
        }
        mvc.perform(get("/api/v1/admin/properties/" + propertyId))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void a_property_that_does_not_exist_is_not_found() throws Exception {
        mvc.perform(get("/api/v1/admin/properties/" + UUID.randomUUID())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNotFound());
    }

    // ---- fixtures -----------------------------------------------------------------------

    private ResultActions property() throws Exception {
        return mvc.perform(get("/api/v1/admin/properties/" + propertyId)
                .header("Authorization", "Bearer " + adminToken));
    }

    private ResultActions unit(String body) throws Exception {
        return mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());
    }

    private String bed(int index) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + bedspaceId + "/beds")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString();
        return json.readTree(beds).get(index).get("id").asText();
    }

    /** A tenant asks, the landlord accepts. Returns the lease id. */
    private String let(String tenantToken, String request) throws Exception {
        String asked = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        return idOf(mvc.perform(post("/api/v1/rental-requests/"
                        + json.readTree(asked).get("id").asText() + "/accept")
                .header("Authorization", "Bearer " + elena.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"rentAmount\":2500.00,\"startDate\":\"%s\"}"
                        .formatted(LocalDate.now(clock)))));
    }

    private String idOf(ResultActions actions) throws Exception {
        return json.readTree(actions.andReturn().getResponse().getContentAsString())
                .get("id").asText();
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

    private static byte[] photo() throws Exception {
        BufferedImage picture = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        picture.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(picture, "jpg", out);
        return out.toByteArray();
    }
}
