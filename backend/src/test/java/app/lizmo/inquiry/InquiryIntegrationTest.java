package app.lizmo.inquiry;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Somebody asking about a place, and the landlord answering — in words.
 *
 * <p>This replaces the form that came before it, where a tenant pressed a
 * button and a landlord read five rows of facts. Neither could say anything to
 * the other, so every real exchange happened on the phone and nothing about it
 * was written down.
 */
class InquiryIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String tenantToken;
    private String strangerToken;

    private String propertyId;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        tenantToken = accounts.tenant("ana").token();
        strangerToken = accounts.tenant("bea").token();

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
    }

    private void giveANumber(String token) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"contactPhone\":\"09170000001\"}"))
                .andExpect(status().isOk());
    }

    private ResultActions ask(String token, String message) throws Exception {
        String body = message == null
                ? "{\"propertyId\":\"%s\"}".formatted(propertyId)
                : "{\"propertyId\":\"%s\",\"message\":\"%s\"}".formatted(propertyId, message);
        return mvc.perform(post("/api/v1/inquiries")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private String startedBy(String token, String message) throws Exception {
        String created = ask(token, message)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(created).get("inquiry").get("id").asText();
    }

    private ResultActions say(String token, String id, String what) throws Exception {
        return mvc.perform(post("/api/v1/inquiries/" + id + "/messages")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"%s\"}".formatted(what)));
    }

    // ---- starting one ---------------------------------------------------------------

    /**
     * The one thing still asked before asking: the landlord's first instinct
     * is to ring, and a conversation they cannot answer any other way is worse
     * than none.
     */
    @Test
    void asking_needs_a_number_to_ring() throws Exception {
        ask(tenantToken, null)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TENANT_PROFILE_INCOMPLETE"))
                .andExpect(jsonPath("$.message")
                        .value(Matchers.containsString("a phone number")));
    }

    @Test
    void a_number_is_all_it_takes() throws Exception {
        giveANumber(tenantToken);

        ask(tenantToken, "Is there a bed free in November?")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.inquiry.propertyName").value("Sunrise Apartments"))
                .andExpect(jsonPath("$.inquiry.status").value("OPEN"))
                // The landlord's name, because a thread with a building is not
                // a conversation.
                .andExpect(jsonPath("$.inquiry.withName").value("elena"))
                .andExpect(jsonPath("$.messages.length()").value(1))
                .andExpect(jsonPath("$.messages[0].body")
                        .value("Is there a bed free in November?"))
                .andExpect(jsonPath("$.messages[0].mine").value(true))
                // The tenant knows who they are; the facts are for the other side.
                .andExpect(jsonPath("$.applicant").doesNotExist());
    }

    /** Asking is a question, not a form. The first message is optional. */
    @Test
    void a_thread_can_start_with_nothing_said() throws Exception {
        giveANumber(tenantToken);

        ask(tenantToken, null)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.messages.length()").value(0))
                .andExpect(jsonPath("$.inquiry.lastMessageAt").doesNotExist());
    }

    /**
     * Tapping the button twice is the same conversation, not two of them.
     */
    @Test
    void asking_twice_picks_the_same_thread_back_up() throws Exception {
        giveANumber(tenantToken);
        String first = startedBy(tenantToken, "Anything free?");
        String again = startedBy(tenantToken, "Still looking");

        org.assertj.core.api.Assertions.assertThat(again).isEqualTo(first);

        mvc.perform(get("/api/v1/inquiries/" + first)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.messages.length()").value(2));
    }

    @Test
    void a_landlord_cannot_ask_about_their_own_place() throws Exception {
        mvc.perform(post("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"propertyId\":\"%s\"}".formatted(propertyId)))
                .andExpect(status().isBadRequest());
    }

    // ---- what each side sees --------------------------------------------------------

    /**
     * What the request card used to carry, and no more: the ID type without
     * its number, no photographs, no emergency contact. Anyone can print a
     * code and stick it on a gate.
     */
    @Test
    void the_landlord_sees_who_is_asking_and_what_they_still_need() throws Exception {
        giveANumber(tenantToken);
        String id = startedBy(tenantToken, "Hello");

        mvc.perform(get("/api/v1/inquiries/" + id)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.applicant.name").value("ana"))
                .andExpect(jsonPath("$.applicant.phone").value("09170000001"))
                .andExpect(jsonPath("$.applicant.stillNeeds").isNotEmpty())
                // Their own side of it reads the same either way.
                .andExpect(jsonPath("$.messages[0].body").value("Hello"))
                // Written by the tenant, so not theirs.
                .andExpect(jsonPath("$.messages[0].mine").value(false));
    }

    @Test
    void a_stranger_cannot_read_somebody_elses_conversation() throws Exception {
        giveANumber(tenantToken);
        String id = startedBy(tenantToken, "Hello");

        // Not forbidden: whether these two are talking is itself none of
        // their business.
        mvc.perform(get("/api/v1/inquiries/" + id)
                        .header("Authorization", "Bearer " + strangerToken))
                .andExpect(status().isNotFound());

        say(strangerToken, id, "Let me in")
                .andExpect(status().isNotFound());
    }

    // ---- talking --------------------------------------------------------------------

    @Test
    void both_sides_can_write_and_the_thread_keeps_the_order() throws Exception {
        giveANumber(tenantToken);
        String id = startedBy(tenantToken, "Is the second floor free?");

        say(landlordToken, id, "Yes, from the 15th. Want to see it Saturday?")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.mine").value(true));
        say(tenantToken, id, "Saturday works").andExpect(status().isCreated());

        mvc.perform(get("/api/v1/inquiries/" + id)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.messages.length()").value(3))
                .andExpect(jsonPath("$.messages[0].mine").value(true))
                .andExpect(jsonPath("$.messages[1].mine").value(false))
                .andExpect(jsonPath("$.messages[2].body").value("Saturday works"));
    }

    @Test
    void an_empty_message_is_refused() throws Exception {
        giveANumber(tenantToken);
        String id = startedBy(tenantToken, "Hello");

        say(tenantToken, id, "   ").andExpect(status().isBadRequest());
    }

    // ---- the inbox ------------------------------------------------------------------

    /**
     * One endpoint for both sides. A landlord's inbox and a tenant's are the
     * same question asked from opposite ends.
     */
    @Test
    void each_side_sees_the_thread_from_their_own_end() throws Exception {
        giveANumber(tenantToken);
        startedBy(tenantToken, "Hello");

        mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].withName").value("elena"))
                .andExpect(jsonPath("$[0].lastMessage").value("Hello"));

        mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].withName").value("ana"))
                .andExpect(jsonPath("$[0].propertyName").value("Sunrise Apartments"));
    }

    /** Someone with no properties and no threads has an empty inbox, not an error. */
    @Test
    void an_inbox_with_nothing_in_it_is_a_list() throws Exception {
        mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + strangerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void unread_is_what_the_other_side_has_said_since_you_looked() throws Exception {
        giveANumber(tenantToken);
        String id = startedBy(tenantToken, "Hello");

        // The landlord has not opened it.
        mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].unread").value(true));

        // Writing it is reading it: the tenant's own message is not unread.
        mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$[0].unread").value(false));

        mvc.perform(get("/api/v1/inquiries/" + id)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].unread").value(false));

        // And the reply puts it back on the tenant.
        say(landlordToken, id, "Yes, come Saturday").andExpect(status().isCreated());
        mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$[0].unread").value(true));
    }

    @Test
    void a_message_tells_the_other_side_without_quoting_it() throws Exception {
        giveANumber(tenantToken);
        startedBy(tenantToken, "My budget is 2500 and I work nights");

        mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].type").value("INQUIRY_MESSAGE"))
                .andExpect(jsonPath("$[0].message")
                        .value(Matchers.containsString("Sunrise Apartments")))
                // Read on a lock screen. What they said is not for whoever is
                // holding the phone.
                .andExpect(jsonPath("$[0].message")
                        .value(Matchers.not(Matchers.containsString("budget"))));
    }

    // ---- ending it ------------------------------------------------------------------

    @Test
    void either_side_can_close_it_and_asking_again_reopens_it() throws Exception {
        giveANumber(tenantToken);
        String id = startedBy(tenantToken, "Hello");

        mvc.perform(post("/api/v1/inquiries/" + id + "/close")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CLOSED"));

        // Nothing more is said into a conversation that is over.
        say(tenantToken, id, "Are you sure?")
                .andExpect(status().isBadRequest());

        // The same thread comes back, with what was said in it.
        String again = startedBy(tenantToken, "Changed your mind?");
        org.assertj.core.api.Assertions.assertThat(again).isEqualTo(id);

        mvc.perform(get("/api/v1/inquiries/" + id)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.inquiry.status").value("OPEN"))
                .andExpect(jsonPath("$.messages.length()").value(2));
    }
}
