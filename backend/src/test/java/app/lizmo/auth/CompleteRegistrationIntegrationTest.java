package app.lizmo.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import app.lizmo.support.RecordingMailer;
import app.lizmo.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Turning a verified address into an account.
 *
 * <p>The place where a self-service account first exists, and therefore the
 * place where "nothing is stored until the password is saved" is either true or
 * a comment somebody wrote once.
 */
class CompleteRegistrationIntegrationTest extends IntegrationTest {

    @Autowired
    private RecordingMailer mailer;

    @Autowired
    private MutableClock clock;

    @Autowired
    private UserRepository users;

    private String email;

    @BeforeEach
    void setUp() {
        mailer.clear();
        clock.reset();
        email = "ana%d@example.com".formatted(System.nanoTime());
    }

    private void askForACode() throws Exception {
        mvc.perform(post("/api/v1/auth/register/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\"}".formatted(email)))
                .andExpect(status().isOk());
    }

    private ResultActions complete(String code, String name, String password)
            throws Exception {
        return mvc.perform(post("/api/v1/auth/register/complete")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"email":"%s","code":"%s","name":"%s","password":"%s"}
                        """.formatted(email, code, name, password)));
    }

    // ---- the happy path ---------------------------------------------------

    @Test
    void a_verified_address_and_a_good_password_make_an_account()
            throws Exception {
        askForACode();

        complete(mailer.lastCode(), "Ana Reyes", "Sunrise2Bed!")
                .andExpect(status().isCreated())
                // Signed in on the spot: making somebody type the password they
                // just chose, on the next screen, is a step with no purpose.
                .andExpect(jsonPath("$.accessToken").exists())
                .andExpect(jsonPath("$.name").value("Ana Reyes"));

        assertThat(users.findByEmail(email)).isPresent();
    }

    @Test
    void the_new_account_is_a_tenant_and_nothing_else() throws Exception {
        askForACode();
        String token = json.readTree(
                        complete(mailer.lastCode(), "Ana", "Sunrise2Bed!")
                                .andReturn().getResponse().getContentAsString())
                .get("accessToken").asText();

        // Landlords are invited by an admin. Nobody makes themselves one.
        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());

        // Tested by trying to create a property rather than to list them:
        // listing returns an empty list for somebody who owns nothing, which is
        // correct and proves nothing about whether they could own something.
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Not mine","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    void the_address_is_recorded_as_proved() throws Exception {
        askForACode();
        complete(mailer.lastCode(), "Ana", "Sunrise2Bed!")
                .andExpect(status().isCreated());

        assertThat(users.findByEmail(email).orElseThrow().getEmailVerifiedAt())
                .isNotNull();
    }

    @Test
    void the_name_is_taken_from_this_step_not_the_first() throws Exception {
        askForACode();

        // The address arrives before the name does, which is why the name is
        // asked for here and not at the start.
        complete(mailer.lastCode(), "  Ana Reyes  ", "Sunrise2Bed!")
                .andExpect(jsonPath("$.name").value("Ana Reyes"));
    }

    // ---- nothing exists until this call succeeds --------------------------

    @Test
    void asking_for_a_code_creates_no_account() throws Exception {
        askForACode();

        // The whole reason verification lives in a table of its own. An
        // abandoned sign-up must not squat on the address forever.
        assertThat(users.findByEmail(email)).isEmpty();
    }

    @Test
    void a_refused_password_creates_no_account() throws Exception {
        askForACode();

        complete(mailer.lastCode(), "Ana", "short").andExpect(status().isBadRequest());
        assertThat(users.findByEmail(email)).isEmpty();
    }

    @Test
    void a_refused_password_does_not_spend_the_code() throws Exception {
        askForACode();
        String code = mailer.lastCode();

        complete(code, "Ana", "nodigitsorcaps").andExpect(status().isBadRequest());

        // Checked before the code is even looked at. Somebody who picks a weak
        // password should not lose their one working code over it.
        complete(code, "Ana", "Sunrise2Bed!").andExpect(status().isCreated());
    }

    // ---- the password rule, one failure at a time -------------------------

    @ParameterizedTest(name = "{1}")
    @CsvSource({
        "Ab1!def,     at least 8 characters",
        "sunrise2bed!,a capital letter",
        "SUNRISE2BED!,a small letter",
        "SunriseBed!, a number",
        "Sunrise2Bed, a symbol like ! or @",
    })
    void each_rule_is_named_on_its_own(String password, String expected)
            throws Exception {
        askForACode();

        // One regex would refuse all of these with "password is invalid",
        // leaving somebody to guess which of five rules they broke.
        complete(mailer.lastCode(), "Ana", password)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("WEAK_PASSWORD"))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString(expected)));
    }

    @Test
    void everything_missing_is_named_at_once() throws Exception {
        askForACode();

        // Told one problem at a time, somebody fixing one problem at a time
        // tries four times.
        complete(mailer.lastCode(), "Ana", "abc")
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.allOf(
                                org.hamcrest.Matchers.containsString("8 characters"),
                                org.hamcrest.Matchers.containsString("a capital letter"),
                                org.hamcrest.Matchers.containsString("a number"),
                                org.hamcrest.Matchers.containsString("a symbol"))));
    }

    @Test
    void an_unusual_symbol_still_counts() throws Exception {
        askForACode();

        // A password with a peso sign is a good password. Refusing it because
        // it is not in some list of approved punctuation teaches people to
        // pick a worse one.
        complete(mailer.lastCode(), "Ana", "Sunrise2Bed₱")
                .andExpect(status().isCreated());
    }

    // ---- the code, spent here --------------------------------------------

    @Test
    void a_wrong_code_makes_no_account() throws Exception {
        askForACode();

        complete("000000", "Ana", "Sunrise2Bed!")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("OTP_INCORRECT"));
        assertThat(users.findByEmail(email)).isEmpty();
    }

    @Test
    void an_expired_code_makes_no_account() throws Exception {
        askForACode();
        String code = mailer.lastCode();
        clock.advanceMinutes(11);

        complete(code, "Ana", "Sunrise2Bed!")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("OTP_EXPIRED"));
        assertThat(users.findByEmail(email)).isEmpty();
    }

    @Test
    void the_code_cannot_be_used_for_a_second_account() throws Exception {
        askForACode();
        String code = mailer.lastCode();
        complete(code, "Ana", "Sunrise2Bed!").andExpect(status().isCreated());

        // Even though the address is now taken, the point is that the code
        // itself is spent — this fails on the code, before the address.
        complete(code, "Ana Again", "Sunrise2Bed!")
                .andExpect(status().isBadRequest());
    }

    @Test
    void finishing_without_ever_asking_for_a_code_is_refused() throws Exception {
        complete("123456", "Ana", "Sunrise2Bed!")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("Ask for a code first")));
    }

    @Test
    void a_missing_name_is_refused() throws Exception {
        askForACode();

        // The account needs one: a landlord deciding who to let a room to sees
        // a name, not an email address.
        complete(mailer.lastCode(), "", "Sunrise2Bed!")
                .andExpect(status().isBadRequest());
    }
}
