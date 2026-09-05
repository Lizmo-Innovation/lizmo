package app.lizmo.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import app.lizmo.support.RecordingMailer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

/**
 * How somebody becomes a landlord.
 *
 * <p>The only way one is made. Sign-up produces tenants and nothing else, so
 * everything about who may own property, and therefore who may read the details
 * of the people asking to live there, runs through here.
 */
class LandlordInvitationIntegrationTest extends IntegrationTest {

    @Autowired
    private RecordingMailer mailer;

    @Autowired
    private MutableClock clock;

    private String adminToken;
    private String email;

    @BeforeEach
    void setUp() {
        mailer.clear();
        clock.reset();
        adminToken = accounts.admin("Lizmo Staff").token();
        email = "elena%d@example.com".formatted(System.nanoTime());
    }

    private ResultActions invite(String token, String address) throws Exception {
        return mvc.perform(post("/api/v1/admin/landlord-invitations")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"email":"%s","name":"Elena"}
                        """.formatted(address)));
    }

    private ResultActions accept(String token, String name, String password)
            throws Exception {
        return mvc.perform(post("/api/v1/auth/invitations/accept")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"token":"%s","name":"%s","password":"%s"}
                        """.formatted(token, name, password)));
    }

    // ---- who may invite ---------------------------------------------------

    @Test
    void only_lizmo_staff_may_invite() throws Exception {
        // The whole point of the change: a landlord used to be anyone who
        // ticked a box. A tenant, and even a landlord, must not be able to
        // make another one.
        invite(accounts.tenant("ana").token(), email).andExpect(status().isForbidden());
        invite(accounts.landlord("mario").token(), email).andExpect(status().isForbidden());

        assertThat(mailer.invitationCount()).isZero();
    }

    @Test
    void an_invitation_needs_a_token_at_all() throws Exception {
        mvc.perform(post("/api/v1/admin/landlord-invitations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\"}".formatted(email)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void an_admin_invites_and_the_email_goes_out() throws Exception {
        invite(adminToken, email)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.expiresAt").isNotEmpty())
                // Never the token. It exists in one inbox, and an API response
                // would make the admin console a second place to steal it from.
                .andExpect(jsonPath("$.token").doesNotExist());

        assertThat(mailer.invitationCount()).isEqualTo(1);
        assertThat(mailer.lastInvitation().to()).isEqualTo(email);
        assertThat(mailer.lastInvitation().validDays()).isEqualTo(7);
        // The link and the pasteable token are the same thing: until an app
        // registers a deep link, one of the two has to work by hand.
        assertThat(mailer.lastInvitation().link())
                .endsWith(mailer.lastInvitationToken());
    }

    @Test
    void inviting_again_kills_the_earlier_link() throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());
        String first = mailer.lastInvitationToken();

        invite(adminToken, email).andExpect(status().isCreated());
        String second = mailer.lastInvitationToken();

        assertThat(first).isNotEqualTo(second);
        accept(first, "Elena", "Sunrise2Bed!")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
        accept(second, "Elena", "Sunrise2Bed!").andExpect(status().isCreated());
    }

    @Test
    void somebody_who_already_lets_rooms_is_not_invited_twice() throws Exception {
        String taken = accounts.landlord("mario").email();

        invite(adminToken, taken)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_A_LANDLORD"));
        assertThat(mailer.invitationCount()).isZero();
    }

    // ---- taking it up, as somebody new ------------------------------------

    @Test
    void a_new_landlord_sets_their_own_password_and_is_signed_in()
            throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());

        accept(mailer.lastInvitationToken(), "Elena Bautista", "Sunrise2Bed!")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.name").value("Elena Bautista"))
                // A landlord and nothing else. One account is one side of the
                // arrangement, so there is no tenant profile underneath.
                .andExpect(jsonPath("$.profiles.length()").value(1))
                .andExpect(jsonPath("$.profiles[0]").value("LANDLORD"));
    }

    @Test
    void the_new_landlord_can_actually_own_property() throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());
        String token = json.readTree(
                        accept(mailer.lastInvitationToken(), "Elena", "Sunrise2Bed!")
                                .andReturn().getResponse().getContentAsString())
                .get("accessToken").asText();

        // The profile is what the property endpoints check, so this is the
        // assertion that the invitation did the thing it is for.
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated());
    }

    @Test
    void the_password_rule_is_the_same_one_as_everywhere_else() throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());
        String token = mailer.lastInvitationToken();

        accept(token, "Elena", "short")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("WEAK_PASSWORD"));

        // And checking it first means a refused password did not cost them
        // their one link.
        accept(token, "Elena", "Sunrise2Bed!").andExpect(status().isCreated());
    }

    @Test
    void a_new_landlord_has_to_give_a_name() throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());

        // Their tenants see this name, not an email address.
        accept(mailer.lastInvitationToken(), "", "Sunrise2Bed!")
                .andExpect(status().isBadRequest());
    }

    // ---- taking it up, as somebody who already rents -----------------------

    @Test
    void an_address_that_rents_cannot_be_invited() throws Exception {
        Accounts.Account ana = accounts.tenant("Ana");

        // A landlord is not a tenant: one account is one side of the
        // arrangement. Somebody who does both needs a second address, which is
        // a real cost and a deliberate one.
        invite(adminToken, ana.email())
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_A_TENANT"));
        assertThat(mailer.invitationCount()).isZero();
    }

    @Test
    void an_invitee_who_signs_up_as_a_tenant_meanwhile_is_refused()
            throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());
        String token = mailer.lastInvitationToken();

        // Seven days pass between sending and accepting, and sign-up is open.
        // Checking only at invitation time would let exactly this through.
        mvc.perform(post("/api/v1/auth/register/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\"}".formatted(email)))
                .andExpect(status().isOk());
        mvc.perform(post("/api/v1/auth/register/complete")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s","name":"Elena",
                                 "password":"Sunrise2Bed!"}
                                """.formatted(email, mailer.lastCode())))
                .andExpect(status().isCreated());

        accept(token, "Elena", "Sunrise2Bed!")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_A_TENANT"));
    }

    @Test
    void a_refused_password_leaves_the_invitation_usable() throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());
        String token = mailer.lastInvitationToken();

        // Checked before the invitation is spent, so a weak password does not
        // cost somebody their one link.
        accept(token, "Elena", "short").andExpect(status().isBadRequest());
        accept(token, "Elena", "Sunrise2Bed!").andExpect(status().isCreated());
    }

    // ---- the link itself --------------------------------------------------

    @Test
    void the_link_says_what_it_is_for_before_anything_is_typed()
            throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());

        mvc.perform(get("/api/v1/auth/invitations/" + mailer.lastInvitationToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(email))
                // Which decides the whole screen: choose a password, or confirm
                // the one you already have.
                .andExpect(jsonPath("$.hasAccount").value(false));
    }

    @Test
    void a_made_up_token_is_refused() throws Exception {
        mvc.perform(get("/api/v1/auth/invitations/not-a-real-token"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
    }

    @Test
    void one_invitation_makes_one_landlord() throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());
        String token = mailer.lastInvitationToken();
        accept(token, "Elena", "Sunrise2Bed!").andExpect(status().isCreated());

        // Otherwise a link found in an old inbox re-adds a profile that was
        // deliberately taken away.
        accept(token, "Elena", "Sunrise2Bed!")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
    }

    @Test
    void a_week_is_long_enough() throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());
        String token = mailer.lastInvitationToken();

        clock.advanceDays(6);
        accept(token, "Elena", "Sunrise2Bed!").andExpect(status().isCreated());
    }

    @Test
    void an_old_link_stops_working() throws Exception {
        invite(adminToken, email).andExpect(status().isCreated());
        String token = mailer.lastInvitationToken();

        clock.advanceDays(8);
        accept(token, "Elena", "Sunrise2Bed!")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVITATION_EXPIRED"));

        mvc.perform(get("/api/v1/auth/invitations/" + token))
                .andExpect(jsonPath("$.code").value("INVITATION_EXPIRED"));
    }
}
