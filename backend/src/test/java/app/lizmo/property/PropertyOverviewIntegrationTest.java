package app.lizmo.property;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import com.fasterxml.jackson.databind.JsonNode;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.ZoneId;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

/** A building at a glance: how full, what is late, each unit's beds. */
class PropertyOverviewIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private Accounts.Account elena;
    private String propertyId;
    private String shared;
    private String whole;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();
        elena = accounts.landlord("Elena");
        propertyId = id(mvc.perform(post("/api/v1/properties")
                .header("Authorization", "Bearer " + elena.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"name":"Sunrise Apartments","address":"12 Mabini St",
                         "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                        """)).andReturn().getResponse().getContentAsString());
        shared = unit("2B", "BEDSPACE", 2, 2500);
        whole = unit("3A", "WHOLE_UNIT", 1, 6000);
    }

    @Test
    void counts_every_space_that_can_be_let() throws Exception {
        JsonNode overview = overview();

        assertThat(overview.get("rentable").asInt()).isEqualTo(3);
        assertThat(overview.get("occupied").asInt()).isZero();
        assertThat(overview.get("vacant").asInt()).isEqualTo(3);
        assertThat(overview.get("overdueTotal").decimalValue()).isEqualByComparingTo("0");
    }

    @Test
    void each_bed_says_whether_it_is_let_and_a_whole_unit_who_has_it() throws Exception {
        Accounts.Account ana = tenant("Ana");
        Accounts.Account miguel = tenant("Miguel Cruz");
        letBed(ana, firstBed(shared), today());
        let(miguel, whole, today());

        JsonNode overview = overview();
        assertThat(overview.get("occupied").asInt()).isEqualTo(2);
        assertThat(overview.get("vacant").asInt()).isEqualTo(1);

        JsonNode bedspace = unitIn(overview, "2B");
        assertThat(bedspace.get("beds")).hasSize(2);
        assertThat(bedspace.get("beds").get(0).get("let").asBoolean()).isTrue();
        assertThat(bedspace.get("beds").get(1).get("let").asBoolean()).isFalse();
        assertThat(bedspace.get("rent").decimalValue()).isEqualByComparingTo("2500");

        JsonNode unit = unitIn(overview, "3A");
        assertThat(unit.get("beds")).isEmpty();
        assertThat(unit.get("tenantName").asText()).isEqualTo("Miguel Cruz");
    }

    /** Two months gone by unpaid: both owed late, one tenancy behind. */
    @Test
    void what_is_owed_late_is_summed_and_its_unit_says_so() throws Exception {
        String lease = let(tenant("Miguel"), whole, today().minusDays(40));
        mvc.perform(get("/api/v1/leases/" + lease + "/billing")
                .header("Authorization", "Bearer " + elena.token()));

        JsonNode overview = overview();
        assertThat(overview.get("overdueTotal").decimalValue()).isEqualByComparingTo("12000");
        assertThat(unitIn(overview, "3A").get("overdueTenancies").asInt()).isEqualTo(1);
        assertThat(unitIn(overview, "2B").get("overdueTenancies").asInt()).isZero();
    }

    @Test
    void a_unit_out_of_service_is_not_a_space_to_let() throws Exception {
        mvc.perform(put("/api/v1/units/" + whole + "/maintenance")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"underMaintenance\":true}"))
                .andExpect(status().isOk());

        assertThat(overview().get("rentable").asInt()).isEqualTo(2);
    }

    @Test
    void a_room_being_readied_says_from_when() throws Exception {
        LocalDate later = today().plusDays(14);
        mvc.perform(put("/api/v1/units/" + whole + "/ready-from")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"readyFrom\":\"%s\"}".formatted(later)))
                .andExpect(status().isOk());

        assertThat(unitIn(overview(), "3A").get("readyFrom").asText()).isEqualTo(later.toString());
    }

    @Test
    void nobody_else_can_read_it() throws Exception {
        mvc.perform(get("/api/v1/properties/" + propertyId + "/overview")
                        .header("Authorization", "Bearer " + accounts.landlord("Mario").token()))
                .andExpect(status().isNotFound());
    }

    // ---- fixtures ----------------------------------------------------------

    private LocalDate today() {
        return LocalDate.now(clock.withZone(ZoneId.of("Asia/Manila")));
    }

    private JsonNode overview() throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/properties/" + propertyId + "/overview")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private static JsonNode unitIn(JsonNode overview, String number) {
        for (JsonNode unit : overview.get("units")) {
            if (unit.get("unitNumber").asText().equals(number)) {
                return unit;
            }
        }
        throw new AssertionError("no unit " + number);
    }

    private String unit(String number, String mode, int capacity, int rent) throws Exception {
        return id(mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                .header("Authorization", "Bearer " + elena.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"unitNumber":"%s","floor":"2","rentalMode":"%s",
                         "capacity":%d,"rent":%d}
                        """.formatted(number, mode, capacity, rent)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString());
    }

    private String firstBed(String unit) throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/units/" + unit + "/beds")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();
    }

    private String letBed(Accounts.Account tenant, String bed, LocalDate start) throws Exception {
        return id(letRoom(elena.token(), tenant.token(),
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(shared, bed),
                "{\"startDate\":\"%s\"}".formatted(start)));
    }

    private String let(Accounts.Account tenant, String unit, LocalDate start) throws Exception {
        return id(letRoom(elena.token(), tenant.token(),
                "{\"unitId\":\"%s\"}".formatted(unit),
                "{\"startDate\":\"%s\"}".formatted(start)));
    }

    private String id(String body) throws Exception {
        return json.readTree(body).get("id").asText();
    }

    private Accounts.Account tenant(String name) throws Exception {
        Accounts.Account tenant = accounts.tenant(name);
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenant.token())
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
                            .header("Authorization", "Bearer " + tenant.token()))
                    .andExpect(status().isCreated());
        }
        return tenant;
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
