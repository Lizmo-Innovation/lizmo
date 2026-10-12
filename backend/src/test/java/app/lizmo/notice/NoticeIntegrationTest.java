package app.lizmo.notice;

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
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Announcements: a landlord telling everybody in a building, or in one unit,
 * the same thing at once.
 */
class NoticeIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private Accounts.Account elena;
    private Accounts.Account ana;
    private Accounts.Account bea;
    private String propertyId;
    private String unit2B;
    private String unit3A;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();
        elena = accounts.landlord("Elena");
        ana = accounts.tenant("Ana");
        bea = accounts.tenant("Bea");

        propertyId = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();
        unit2B = unit("2B");
        unit3A = unit("3A");

        makeReadyForALease(ana.token());
        makeReadyForALease(bea.token());
    }

    // ---- posting -----------------------------------------------------------

    @Test
    void everybody_in_the_building_is_told() throws Exception {
        let(ana, unit2B);
        let(bea, unit3A);

        postNotice(notice("Water off on Saturday", null, null)).andExpect(status().isCreated());

        assertThat(toldAbout(ana)).containsExactly("Sunrise Apartments: Water off on Saturday");
        assertThat(toldAbout(bea)).containsExactly("Sunrise Apartments: Water off on Saturday");
        assertThat(titles(mine(ana))).containsExactly("Water off on Saturday");
    }

    @Test
    void one_unit_is_only_that_unit() throws Exception {
        let(ana, unit2B);
        let(bea, unit3A);

        postNotice(notice("Leak above 2B", unit2B, null))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.unitNumber").value("2B"))
                .andExpect(jsonPath("$.audience").value(1));

        assertThat(titles(mine(ana))).containsExactly("Leak above 2B");
        assertThat(mine(ana).get(0).get("unitNumber").asText()).isEqualTo("2B");
        assertThat(mine(bea)).isEmpty();
        assertThat(toldAbout(bea)).isEmpty();
    }

    /** Read on a lock screen: the start of it, not a wall of text. */
    @Test
    void a_long_message_is_cut_short_in_the_notification() throws Exception {
        let(ana, unit2B);
        String long_ = "The water main is being replaced. ".repeat(10);

        postNotice(notice("Water", null, null, long_)).andExpect(status().isCreated());

        String said = notificationsTo(ana).get(0).get("message").asText();
        assertThat(said).endsWith("…").hasSizeLessThanOrEqualTo(140);
        assertThat(mine(ana).get(0).get("message").asText()).isEqualTo(long_.trim());
    }

    @Test
    void only_the_landlord_of_the_building_can_post() throws Exception {
        Accounts.Account mario = accounts.landlord("Mario");

        mvc.perform(post("/api/v1/properties/" + propertyId + "/notices")
                        .header("Authorization", "Bearer " + mario.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(notice("Hello", null, null)))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/properties/" + propertyId + "/notices")
                        .header("Authorization", "Bearer " + ana.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(notice("Hello", null, null)))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_unit_from_another_building_is_refused() throws Exception {
        Accounts.Account mario = accounts.landlord("Mario");
        String his = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + mario.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Elsewhere","address":"1 Rizal Ave",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();
        String hisUnit = json.readTree(mvc.perform(post("/api/v1/properties/" + his + "/units")
                        .header("Authorization", "Bearer " + mario.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","floor":"1","rentalMode":"WHOLE_UNIT",
                                 "capacity":1,"rent":6000.00}
                                """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        postNotice(notice("Hello", hisUnit, null)).andExpect(status().isNotFound());
    }

    @Test
    void a_title_and_a_message_are_needed() throws Exception {
        postNotice("{\"title\":\"\",\"message\":\"Something\"}").andExpect(status().isBadRequest());
        postNotice("{\"title\":\"Something\",\"message\":\" \"}").andExpect(status().isBadRequest());
    }

    @Test
    void a_last_day_already_gone_is_refused() throws Exception {
        postNotice(notice("Late", null, today().minusDays(1))).andExpect(status().isBadRequest());
    }

    // ---- who sees it -------------------------------------------------------

    /** House rules matter most to somebody new. */
    @Test
    void somebody_who_moves_in_later_sees_it_but_is_not_told() throws Exception {
        postNotice(notice("House rules", null, null)).andExpect(status().isCreated());

        let(ana, unit2B);

        assertThat(titles(mine(ana))).containsExactly("House rules");
        assertThat(toldAbout(ana)).isEmpty();
    }

    @Test
    void somebody_who_has_moved_out_no_longer_sees_it() throws Exception {
        String lease = let(ana, unit2B);
        postNotice(notice("House rules", null, null)).andExpect(status().isCreated());

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\"}".formatted(today())))
                .andExpect(status().isOk());

        assertThat(mine(ana)).isEmpty();
    }

    @Test
    void it_is_shown_through_its_last_day_and_no_longer() throws Exception {
        let(ana, unit2B);
        postNotice(notice("Water off", null, today().plusDays(2))).andExpect(status().isCreated());

        clock.advanceDays(2);
        assertThat(titles(mine(ana))).containsExactly("Water off");
        assertThat(mine(ana).get(0).get("until").asText())
                .isEqualTo(today().toString());

        clock.advanceDays(1);
        assertThat(mine(ana)).isEmpty();
        // The landlord still has it, marked as over.
        assertThat(onBuilding().get(0).get("live").asBoolean()).isFalse();
    }

    @Test
    void taken_down_it_is_gone_for_everybody() throws Exception {
        let(ana, unit2B);
        String id = json.readTree(postNotice(notice("Oops", null, null))
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        mvc.perform(post("/api/v1/notices/" + id + "/take-down")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isNoContent());

        assertThat(mine(ana)).isEmpty();
        assertThat(onBuilding()).isEmpty();
    }

    @Test
    void nobody_else_can_take_it_down() throws Exception {
        String id = json.readTree(postNotice(notice("Mine", null, null))
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        mvc.perform(post("/api/v1/notices/" + id + "/take-down")
                        .header("Authorization", "Bearer " + accounts.landlord("Mario").token()))
                .andExpect(status().isNotFound());
    }

    // ---- who has seen it ---------------------------------------------------

    @Test
    void the_landlord_sees_how_many_have_opened_it() throws Exception {
        let(ana, unit2B);
        let(bea, unit3A);
        String id = json.readTree(postNotice(notice("Water off", null, null))
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        read(ana, id).andExpect(status().isNoContent());
        read(ana, id).andExpect(status().isNoContent());

        JsonNode notice = onBuilding().get(0);
        assertThat(notice.get("seenBy").asInt()).isEqualTo(1);
        assertThat(notice.get("audience").asInt()).isEqualTo(2);
        assertThat(mine(ana).get(0).get("read").asBoolean()).isTrue();
        assertThat(mine(bea).get(0).get("read").asBoolean()).isFalse();
    }

    /** Marking one read counts you as somebody it reached; it has to be yours. */
    @Test
    void nobody_can_read_one_that_is_not_for_them() throws Exception {
        let(ana, unit2B);
        String id = json.readTree(postNotice(notice("Leak", unit2B, null))
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        read(bea, id).andExpect(status().isNotFound());
    }

    // ---- fixtures ----------------------------------------------------------

    private LocalDate today() {
        return LocalDate.now(clock.withZone(ZoneId.of("Asia/Manila")));
    }

    private String unit(String number) throws Exception {
        return json.readTree(mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"%s","floor":"2","rentalMode":"WHOLE_UNIT",
                                 "capacity":1,"rent":6000.00}
                                """.formatted(number)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();
    }

    private String let(Accounts.Account tenant, String unit) throws Exception {
        return json.readTree(letRoom(elena.token(), tenant.token(),
                        "{\"unitId\":\"%s\"}".formatted(unit),
                        "{\"startDate\":\"%s\"}".formatted(LocalDate.now(clock))))
                .get("id").asText();
    }

    private static String notice(String title, String unitId, LocalDate until) {
        return notice(title, unitId, until, "Fill a bucket the night before.");
    }

    private static String notice(String title, String unitId, LocalDate until, String message) {
        return "{\"title\":\"%s\",\"message\":\"%s\"%s%s}".formatted(
                title, message,
                unitId == null ? "" : ",\"unitId\":\"" + unitId + "\"",
                until == null ? "" : ",\"until\":\"" + until + "\"");
    }

    private ResultActions postNotice(String body) throws Exception {
        return mvc.perform(post("/api/v1/properties/" + propertyId + "/notices")
                .header("Authorization", "Bearer " + elena.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private ResultActions read(Accounts.Account who, String id) throws Exception {
        return mvc.perform(post("/api/v1/me/notices/" + id + "/read")
                .header("Authorization", "Bearer " + who.token()));
    }

    private JsonNode mine(Accounts.Account who) throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/me/notices")
                        .header("Authorization", "Bearer " + who.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private JsonNode onBuilding() throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/properties/" + propertyId + "/notices")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private static List<String> titles(JsonNode notices) {
        List<String> titles = new ArrayList<>();
        notices.forEach(notice -> titles.add(notice.get("title").asText()));
        return titles;
    }

    private List<JsonNode> notificationsTo(Accounts.Account who) throws Exception {
        List<JsonNode> found = new ArrayList<>();
        for (JsonNode one : json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + who.token()))
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8))) {
            if (one.get("type").asText().equals("NEW_NOTICE_POSTED")) {
                found.add(one);
            }
        }
        return found;
    }

    private List<String> toldAbout(Accounts.Account who) throws Exception {
        return notificationsTo(who).stream().map(one -> one.get("title").asText()).toList();
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
