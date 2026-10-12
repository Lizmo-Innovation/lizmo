package app.lizmo.property.place;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import com.fasterxml.jackson.databind.JsonNode;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.ZoneId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

/**
 * What a tenant wants to know before asking: who can rent, the house rules,
 * the money up front, what comes with the place, when a room is ready, and
 * who the landlord is.
 */
class PlaceDetailsIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private Accounts.Account elena;
    private String propertyId;
    private String code;
    private String unitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();
        elena = accounts.landlord("Elena Bautista");

        JsonNode property = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString());
        propertyId = property.get("id").asText();
        code = property.get("code").asText();

        unitId = json.readTree(mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"WHOLE_UNIT",
                                 "capacity":1,"rent":6000.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();
    }

    // ---- the details -------------------------------------------------------

    @Test
    void nothing_said_is_null_not_no() throws Exception {
        mvc.perform(get("/api/v1/properties/" + propertyId + "/details")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.whoCanRent").doesNotExist())
                .andExpect(jsonPath("$.pets").doesNotExist())
                .andExpect(jsonPath("$.depositMonths").doesNotExist())
                .andExpect(jsonPath("$.amenities").isEmpty());
    }

    @Test
    void the_landlord_says_them_and_reads_them_back() throws Exception {
        save(everything()).andExpect(status().isOk());

        mvc.perform(get("/api/v1/properties/" + propertyId + "/details")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(jsonPath("$.whoCanRent").value("WOMEN"))
                .andExpect(jsonPath("$.curfew").value("22:00"))
                .andExpect(jsonPath("$.visitors").value("DAYTIME"))
                .andExpect(jsonPath("$.cooking").value(true))
                .andExpect(jsonPath("$.pets").value(false))
                .andExpect(jsonPath("$.smoking").value(false))
                .andExpect(jsonPath("$.otherRules").value("Shoes off inside."))
                .andExpect(jsonPath("$.depositMonths").value(2))
                .andExpect(jsonPath("$.advanceMonths").value(1))
                .andExpect(jsonPath("$.amenities[0]").value("WIFI"))
                .andExpect(jsonPath("$.amenities[1]").value("CCTV"));
    }

    /** The form is the whole of it: a field cleared is cleared. */
    @Test
    void saving_again_replaces_the_lot() throws Exception {
        save(everything()).andExpect(status().isOk());

        save("{\"whoCanRent\":\"ANYONE\",\"otherRules\":\"  \"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.whoCanRent").value("ANYONE"))
                .andExpect(jsonPath("$.curfew").doesNotExist())
                .andExpect(jsonPath("$.otherRules").doesNotExist())
                .andExpect(jsonPath("$.amenities").isEmpty());
    }

    @Test
    void a_curfew_has_to_be_a_time() throws Exception {
        save("{\"curfew\":\"10pm\"}").andExpect(status().isBadRequest());
        save("{\"curfew\":\"24:00\"}").andExpect(status().isBadRequest());
    }

    @Test
    void months_up_front_are_within_reason() throws Exception {
        save("{\"depositMonths\":7}").andExpect(status().isBadRequest());
        save("{\"advanceMonths\":-1}").andExpect(status().isBadRequest());
    }

    @Test
    void nobody_else_can_read_or_set_them() throws Exception {
        Accounts.Account mario = accounts.landlord("Mario");

        mvc.perform(get("/api/v1/properties/" + propertyId + "/details")
                        .header("Authorization", "Bearer " + mario.token()))
                .andExpect(status().isNotFound());
        mvc.perform(put("/api/v1/properties/" + propertyId + "/details")
                        .header("Authorization", "Bearer " + mario.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(everything()))
                .andExpect(status().isNotFound());
    }

    /** Where they matter: the page a stranger sees after scanning the code. */
    @Test
    void anybody_who_scans_the_code_sees_them() throws Exception {
        save(everything()).andExpect(status().isOk());
        Accounts.Account ana = accounts.tenant("Ana");

        lookup(ana)
                .andExpect(jsonPath("$.details.whoCanRent").value("WOMEN"))
                .andExpect(jsonPath("$.details.curfew").value("22:00"))
                .andExpect(jsonPath("$.details.depositMonths").value(2))
                .andExpect(jsonPath("$.details.amenities[0]").value("WIFI"));
    }

    // ---- when a room is ready ----------------------------------------------

    @Test
    void a_vacant_room_is_ready_now_unless_said() throws Exception {
        JsonNode floor = page(accounts.tenant("Ana")).get("floors").get(0);

        assertThat(floor.get("readyLater").asInt()).isZero();
        assertThat(floor.get("readyFrom").isNull()).isTrue();
    }

    @Test
    void a_room_being_readied_says_from_when() throws Exception {
        LocalDate later = today().plusDays(10);
        readyFrom(later).andExpect(status().isOk())
                .andExpect(jsonPath("$.readyFrom").value(later.toString()));

        JsonNode floor = page(accounts.tenant("Ana")).get("floors").get(0);
        assertThat(floor.get("readyLater").asInt()).isEqualTo(1);
        assertThat(floor.get("readyFrom").asText()).isEqualTo(later.toString());
    }

    /** Nobody has to remember to clear it. */
    @Test
    void once_the_day_comes_it_is_ready_now() throws Exception {
        readyFrom(today().plusDays(2)).andExpect(status().isOk());

        clock.advanceDays(3);

        assertThat(page(accounts.tenant("Ana")).get("floors").get(0)
                .get("readyLater").asInt()).isZero();
    }

    @Test
    void a_day_already_gone_is_refused() throws Exception {
        readyFrom(today().minusDays(1)).andExpect(status().isBadRequest());
    }

    // ---- the landlord ------------------------------------------------------

    /** Somebody to ask, and nothing to reach them by. */
    @Test
    void the_landlord_is_a_first_name_and_an_initial() throws Exception {
        JsonNode landlord = page(accounts.tenant("Ana")).get("landlord");

        assertThat(landlord.get("name").asText()).isEqualTo("Elena B.");
        assertThat(landlord.get("since").asText()).endsWith("-01");
        assertThat(landlord.toString()).doesNotContain("@").doesNotContain("0917");
    }

    /** One slow day must not stand for the landlord. */
    @Test
    void how_fast_they_reply_waits_for_three_conversations() throws Exception {
        converse("Ana", 20);
        converse("Bea", 20);

        assertThat(page(accounts.tenant("Zed")).get("landlord").get("replies").isNull())
                .isTrue();
    }

    @Test
    void a_landlord_who_answers_quickly_says_so() throws Exception {
        converse("Ana", 20);
        converse("Bea", 40);
        converse("Cara", 300);

        assertThat(page(accounts.tenant("Zed")).get("landlord").get("replies").asText())
                .isEqualTo("WITHIN_AN_HOUR");
    }

    /** Never answered counts as long as it has waited, once that is a day. */
    @Test
    void conversations_left_unanswered_count_against_them() throws Exception {
        converse("Ana", 20);
        converse("Bea", -1);
        converse("Cara", -1);
        clock.advanceDays(3);

        assertThat(page(accounts.tenant("Zed")).get("landlord").get("replies").asText())
                .isEqualTo("WITHIN_DAYS");
    }

    @Test
    void short_names() {
        assertThat(PlaceDetailsService.shortName("Elena Bautista")).isEqualTo("Elena B.");
        assertThat(PlaceDetailsService.shortName("Maria Clara de la Cruz")).isEqualTo("Maria C.");
        assertThat(PlaceDetailsService.shortName("Elena")).isEqualTo("Elena");
    }

    // ---- fixtures ----------------------------------------------------------

    private LocalDate today() {
        return LocalDate.now(clock.withZone(ZoneId.of("Asia/Manila")));
    }

    private static String everything() {
        return """
                {"whoCanRent":"WOMEN","curfew":"22:00","visitors":"DAYTIME",
                 "cooking":true,"pets":false,"smoking":false,
                 "otherRules":"Shoes off inside.","depositMonths":2,"advanceMonths":1,
                 "amenities":["CCTV","WIFI"]}
                """;
    }

    private ResultActions save(String body) throws Exception {
        return mvc.perform(put("/api/v1/properties/" + propertyId + "/details")
                .header("Authorization", "Bearer " + elena.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private ResultActions readyFrom(LocalDate on) throws Exception {
        return mvc.perform(put("/api/v1/units/" + unitId + "/ready-from")
                .header("Authorization", "Bearer " + elena.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"readyFrom\":\"%s\"}".formatted(on)));
    }

    private ResultActions lookup(Accounts.Account who) throws Exception {
        return mvc.perform(get("/api/v1/properties/lookup").param("code", code)
                        .header("Authorization", "Bearer " + who.token()))
                .andExpect(status().isOk());
    }

    private JsonNode page(Accounts.Account who) throws Exception {
        return json.readTree(lookup(who).andReturn().getResponse()
                .getContentAsString(StandardCharsets.UTF_8));
    }

    /**
     * Somebody asks; the landlord answers after {@code minutes}, or never
     * when negative.
     */
    private void converse(String name, int minutes) throws Exception {
        Accounts.Account tenant = accounts.tenant(name);
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenant.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"contactPhone\":\"09170000001\"}"))
                .andExpect(status().isOk());
        String thread = askAbout(tenant.token(), propertyId);
        say(tenant, thread, "Is there a room?");
        if (minutes >= 0) {
            clock.advanceMinutes(minutes);
            say(elena, thread, "Yes, come and see it.");
        }
        clock.advanceMinutes(1);
    }

    private void say(Accounts.Account who, String thread, String body) throws Exception {
        mvc.perform(post("/api/v1/inquiries/" + thread + "/messages")
                        .header("Authorization", "Bearer " + who.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"body\":\"%s\"}".formatted(body)))
                .andExpect(status().is2xxSuccessful());
    }
}
