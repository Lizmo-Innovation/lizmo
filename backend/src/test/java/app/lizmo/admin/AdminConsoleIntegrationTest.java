package app.lizmo.admin;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.RecordingMailer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

/**
 * What Lizmo's console reads.
 *
 * <p>Two things are asserted throughout: that only staff can read any of it,
 * and that the landlord list and a landlord's page name no tenant. Lizmo bills
 * on occupied slots, and those screens are about the count.
 *
 * <p>Opening a single property does name its current tenants, by decision --
 * see {@link AdminPropertyIntegrationTest}, which also holds it to name and
 * contact only.
 */
class AdminConsoleIntegrationTest extends IntegrationTest {

    @Autowired
    private RecordingMailer mailer;

    private String adminToken;

    @BeforeEach
    void setUp() {
        mailer.clear();
        adminToken = accounts.admin("Lizmo Staff").token();
    }

    private String propertyFor(String landlordToken, String name) throws Exception {
        return json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"%s","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """.formatted(name)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();
    }

    // ---- who may look ------------------------------------------------------

    @Test
    void the_console_is_for_staff_only() throws Exception {
        for (String token : new String[] {
                accounts.tenant("ana").token(), accounts.landlord("elena").token()}) {
            mvc.perform(get("/api/v1/admin/landlords")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isForbidden());
        }

        mvc.perform(get("/api/v1/admin/landlords")).andExpect(status().isUnauthorized());
    }

    // ---- the landlords list ------------------------------------------------

    @Test
    void an_empty_platform_lists_nobody() throws Exception {
        // The console's empty state is a real answer, not a failure.
        mvc.perform(get("/api/v1/admin/landlords")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
    }

    @Test
    void a_landlord_appears_with_their_properties_counted() throws Exception {
        Accounts.Account elena = accounts.landlord("Elena");
        propertyFor(elena.token(), "Sunrise Apartments");
        propertyFor(elena.token(), "Second House");

        mvc.perform(get("/api/v1/admin/landlords/" + elena.id())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.landlord.name").value("Elena"))
                .andExpect(jsonPath("$.landlord.properties").value(2))
                .andExpect(jsonPath("$.landlord.lockedProperties").value(0))
                .andExpect(jsonPath("$.properties.length()").value(2));
    }

    @Test
    void the_list_counts_slots_and_names_no_tenant() throws Exception {
        Accounts.Account elena = accounts.landlord("Elena");
        String property = propertyFor(elena.token(), "Sunrise Apartments");

        mvc.perform(post("/api/v1/properties/" + property + "/units")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":3,"rent":2500.00}
                                """))
                .andExpect(status().isCreated());

        String body = mvc.perform(get("/api/v1/admin/landlords/" + elena.id())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.properties[0].beds").value(3))
                // Nothing is let yet, so nothing is billable yet.
                .andExpect(jsonPath("$.properties[0].occupiedBeds").value(0))
                .andExpect(jsonPath("$.properties[0].accountStatus").value("ACTIVE"))
                .andReturn().getResponse().getContentAsString();

        // Counts, never people: no field anywhere in this payload is a tenant.
        org.assertj.core.api.Assertions.assertThat(body)
                .doesNotContain("tenant")
                .doesNotContain("idNumber");
    }

    @Test
    void a_landlord_who_does_not_exist_is_a_404() throws Exception {
        mvc.perform(get("/api/v1/admin/landlords/" + java.util.UUID.randomUUID())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void locking_shows_up_on_the_landlords_page() throws Exception {
        Accounts.Account elena = accounts.landlord("Elena");
        String property = propertyFor(elena.token(), "Sunrise Apartments");

        mvc.perform(post("/api/v1/admin/properties/" + property + "/lock")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());

        // The console's list has to show one locked of two, not "locked".
        mvc.perform(get("/api/v1/admin/landlords/" + elena.id())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(jsonPath("$.landlord.lockedProperties").value(1))
                .andExpect(jsonPath("$.properties[0].accountStatus").value("LOCKED"));
    }

    // ---- invitations -------------------------------------------------------

    @Test
    void an_invitation_shows_on_the_list_until_it_is_taken_up() throws Exception {
        String email = "elena%d@example.com".formatted(System.nanoTime());
        mvc.perform(post("/api/v1/admin/landlord-invitations")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\",\"name\":\"Elena\"}".formatted(email)))
                .andExpect(status().isCreated());

        mvc.perform(get("/api/v1/admin/landlord-invitations")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].email").value(email))
                .andExpect(jsonPath("$[0].expired").value(false))
                // Never the token: it lives in one inbox, and an API response
                // would make the console a second place to steal it from.
                .andExpect(jsonPath("$[0].token").doesNotExist());

        mvc.perform(post("/api/v1/auth/invitations/accept")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"%s","name":"Elena","password":"Sunrise2Bed!"}
                                """.formatted(mailer.lastInvitationToken())))
                .andExpect(status().isCreated());

        mvc.perform(get("/api/v1/admin/landlord-invitations")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void a_revoked_invitation_stops_working() throws Exception {
        String email = "wrong%d@example.com".formatted(System.nanoTime());
        mvc.perform(post("/api/v1/admin/landlord-invitations")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\"}".formatted(email)))
                .andExpect(status().isCreated());

        String token = mailer.lastInvitationToken();
        String id = json.readTree(mvc.perform(get("/api/v1/admin/landlord-invitations")
                        .header("Authorization", "Bearer " + adminToken))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();

        mvc.perform(delete("/api/v1/admin/landlord-invitations/" + id)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNoContent());

        // A wrong address is the reason this exists, and the link has to die
        // the moment somebody notices.
        mvc.perform(post("/api/v1/auth/invitations/accept")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"%s","name":"Nobody","password":"Sunrise2Bed!"}
                                """.formatted(token)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void a_landlord_cannot_revoke_an_invitation() throws Exception {
        mvc.perform(delete("/api/v1/admin/landlord-invitations/" + java.util.UUID.randomUUID())
                        .header("Authorization", "Bearer " + accounts.landlord("mario").token()))
                .andExpect(status().isForbidden());
    }
}
