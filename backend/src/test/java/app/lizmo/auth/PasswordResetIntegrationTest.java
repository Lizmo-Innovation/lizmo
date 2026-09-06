package app.lizmo.auth;

import static org.assertj.core.api.Assertions.assertThat;
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
 * Getting back into an account, and everything that stops that being abused.
 *
 * <p>A forgotten password used to be permanent. The rules that make the way
 * back safe are all measured in time or in tries, which is exactly the kind of
 * thing that ships broken — so the clock is moved rather than waited on, and
 * the codes are read out of a recording mailer rather than an inbox.
 */
class PasswordResetIntegrationTest extends IntegrationTest {

    private static final String NEW_PASSWORD = "Moonrise7Bed!";

    @Autowired
    private RecordingMailer mailer;

    @Autowired
    private MutableClock clock;

    private Accounts.Account ana;

    @BeforeEach
    void setUp() {
        mailer.clear();
        clock.reset();
        ana = accounts.tenant("ana");
    }

    private ResultActions start(String address) throws Exception {
        return mvc.perform(post("/api/v1/auth/password-reset")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"%s\"}".formatted(address)));
    }

    private ResultActions complete(String address, String code, String password)
            throws Exception {
        return mvc.perform(post("/api/v1/auth/password-reset/complete")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"%s\",\"code\":\"%s\",\"password\":\"%s\"}"
                        .formatted(address, code, password)));
    }

    private ResultActions login(String address, String password) throws Exception {
        return mvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                // "identifier", not "email": login takes an address or a phone.
                .content("{\"identifier\":\"%s\",\"password\":\"%s\"}"
                        .formatted(address, password)));
    }

    // ---- the way back -----------------------------------------------------

    @Test
    void a_forgotten_password_can_be_replaced() throws Exception {
        start(ana.email())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.resendAfterSeconds").value(60));

        complete(ana.email(), mailer.lastResetCode(), NEW_PASSWORD)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty());

        login(ana.email(), NEW_PASSWORD).andExpect(status().isOk());
    }

    @Test
    void the_old_password_stops_working() throws Exception {
        start(ana.email());
        complete(ana.email(), mailer.lastResetCode(), NEW_PASSWORD)
                .andExpect(status().isOk());

        login(ana.email(), Accounts.PASSWORD).andExpect(status().isUnauthorized());
    }

    @Test
    void the_email_names_the_person_and_carries_the_code() throws Exception {
        start(ana.email()).andExpect(status().isOk());

        RecordingMailer.Sent sent = mailer.lastReset();
        assertThat(sent.to()).isEqualTo(ana.email());
        assertThat(sent.name()).isEqualTo("ana");
        assertThat(sent.code()).hasSize(6);
        assertThat(sent.validMinutes()).isEqualTo(15);

        // Not the sign-up email. The wording has to differ: this one arrives
        // unbidden when an account is under attack.
        assertThat(mailer.count()).isZero();
    }

    // ---- who is asking ----------------------------------------------------

    /**
     * The rule this endpoint exists to protect. Success here means "mail was
     * sent to somebody else's inbox", so an honest "no such account" would make
     * Lizmo a way to test a list of addresses against its own membership.
     */
    @Test
    void an_unknown_address_is_answered_exactly_as_a_known_one() throws Exception {
        String known = mvc.perform(post("/api/v1/auth/password-reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\"}".formatted(ana.email())))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        String unknown = start("nobody%d@example.com".formatted(System.nanoTime()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        assertThat(unknown).isEqualTo(known);
    }

    @Test
    void nothing_is_emailed_to_an_address_with_no_account() throws Exception {
        start("nobody%d@example.com".formatted(System.nanoTime()))
                .andExpect(status().isOk());

        assertThat(mailer.resetCount()).isZero();
    }

    /**
     * The rate limit has to apply to unknown addresses too. If it did not, how
     * quickly the endpoint refused would itself be the answer it refuses to
     * give.
     */
    @Test
    void an_unknown_address_is_rate_limited_like_any_other() throws Exception {
        String nobody = "nobody%d@example.com".formatted(System.nanoTime());

        start(nobody).andExpect(status().isOk());
        start(nobody).andExpect(status().isTooManyRequests());
    }

    // ---- the code ---------------------------------------------------------

    @Test
    void a_wrong_code_is_refused_and_counts_against_you() throws Exception {
        start(ana.email());

        complete(ana.email(), "000000", NEW_PASSWORD)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.containsString("4 tries left")));

        login(ana.email(), Accounts.PASSWORD).andExpect(status().isOk());
    }

    @Test
    void five_wrong_codes_burn_the_reset() throws Exception {
        start(ana.email());
        String real = mailer.lastResetCode();

        for (int guess = 0; guess < 4; guess++) {
            complete(ana.email(), "000000", NEW_PASSWORD)
                    .andExpect(status().isBadRequest());
        }
        complete(ana.email(), "000000", NEW_PASSWORD)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.containsString("Too many wrong tries")));

        // Even the right one, now. The reset is spent, not merely locked.
        complete(ana.email(), real, NEW_PASSWORD).andExpect(status().isBadRequest());
    }

    @Test
    void a_code_expires_after_fifteen_minutes() throws Exception {
        start(ana.email());
        String code = mailer.lastResetCode();

        clock.advanceMinutes(16);

        complete(ana.email(), code, NEW_PASSWORD)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.containsString("expired")));
    }

    @Test
    void a_code_works_once() throws Exception {
        start(ana.email());
        String code = mailer.lastResetCode();

        complete(ana.email(), code, NEW_PASSWORD).andExpect(status().isOk());
        complete(ana.email(), code, "Another9Pass!").andExpect(status().isBadRequest());

        login(ana.email(), NEW_PASSWORD).andExpect(status().isOk());
    }

    @Test
    void asking_again_kills_the_previous_code() throws Exception {
        start(ana.email());
        String first = mailer.lastResetCode();

        clock.advanceSeconds(61);
        start(ana.email()).andExpect(status().isOk());
        String second = mailer.lastResetCode();

        complete(ana.email(), first, NEW_PASSWORD).andExpect(status().isBadRequest());
        complete(ana.email(), second, NEW_PASSWORD).andExpect(status().isOk());
    }

    @Test
    void a_new_code_cannot_be_asked_for_straight_away() throws Exception {
        start(ana.email()).andExpect(status().isOk());
        start(ana.email())
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.containsString("Wait")));

        clock.advanceSeconds(61);
        start(ana.email()).andExpect(status().isOk());
    }

    @Test
    void five_codes_is_enough_for_one_day() throws Exception {
        for (int sent = 0; sent < 5; sent++) {
            start(ana.email()).andExpect(status().isOk());
            clock.advanceSeconds(61);
        }

        start(ana.email())
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.containsString("enough codes for today")));

        clock.advanceDays(1);
        start(ana.email()).andExpect(status().isOk());
    }

    // ---- what a reset does to the account ---------------------------------

    /**
     * The reason somebody resets a password is often that a stranger knows the
     * old one. A refresh token outliving the password it was issued against
     * would make the whole exercise cosmetic.
     */
    @Test
    void resetting_ends_every_session_the_account_had() throws Exception {
        String signedIn = login(ana.email(), Accounts.PASSWORD)
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        String refresh = json.readTree(signedIn).get("refreshToken").asText();

        // Still good, before the reset.
        mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"%s\"}".formatted(refresh)))
                .andExpect(status().isOk());

        start(ana.email());
        complete(ana.email(), mailer.lastResetCode(), NEW_PASSWORD)
                .andExpect(status().isOk());

        mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"%s\"}".formatted(refresh)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void a_weak_password_is_refused_and_the_old_one_stands() throws Exception {
        start(ana.email());

        complete(ana.email(), mailer.lastResetCode(), "short")
                .andExpect(status().isBadRequest());

        login(ana.email(), Accounts.PASSWORD).andExpect(status().isOk());
    }

    @Test
    void the_address_is_matched_however_it_was_typed() throws Exception {
        start(ana.email().toUpperCase()).andExpect(status().isOk());

        complete(ana.email(), mailer.lastResetCode(), NEW_PASSWORD)
                .andExpect(status().isOk());
    }
}
