package app.lizmo.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.auth.verification.EmailVerificationService;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import app.lizmo.support.RecordingMailer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Sending somebody a code, and everything that stops that being abused.
 *
 * <p>Every rule here is measured in time or in tries, which is exactly what
 * gets left untested and shipped broken. The clock is moved rather than waited
 * on, and the codes are read out of a recording mailer rather than an inbox.
 */
class EmailVerificationIntegrationTest extends IntegrationTest {

    @Autowired
    private RecordingMailer mailer;

    @Autowired
    private MutableClock clock;

    @Autowired
    private EmailVerificationService verifications;

    private String email;

    @BeforeEach
    void setUp() {
        mailer.clear();
        clock.reset();
        // A fresh address per test: the rules are per-address, and a shared one
        // would make every test depend on the order they ran in.
        email = "ana%d@example.com".formatted(System.nanoTime());
    }

    private ResultActions start(String address) throws Exception {
        return mvc.perform(post("/api/v1/auth/register/start")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"%s\"}".formatted(address)));
    }

    // ---- sending ----------------------------------------------------------

    @Test
    void a_code_is_emailed_to_the_address_that_asked() throws Exception {
        start(email)
                .andExpect(status().isOk())
                // So the screen can count down rather than guess, and the rule
                // lives in one place instead of in every client.
                .andExpect(jsonPath("$.resendAfterSeconds").value(60));

        assertThat(mailer.count()).isEqualTo(1);
        assertThat(mailer.last().to()).isEqualTo(email);
        assertThat(mailer.lastCode()).hasSize(6).containsOnlyDigits();
        assertThat(mailer.last().validMinutes()).isEqualTo(10);
    }

    @Test
    void the_address_is_taken_as_written_but_matched_however_it_was_typed()
            throws Exception {
        start("  ANA" + email.substring(3).toUpperCase() + "  ")
                .andExpect(status().isOk());

        // Ana@ and ana@ are the same person, including to the check for an
        // existing account.
        assertThat(mailer.last().to()).isEqualTo(email.toLowerCase());
    }

    @Test
    void nonsense_is_refused_before_any_email_goes_out() throws Exception {
        start("not-an-address").andExpect(status().isBadRequest());
        assertThat(mailer.count()).isZero();
    }

    @Test
    void an_address_that_already_has_an_account_is_told_plainly()
            throws Exception {
        mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Ana","email":"%s",
                                 "password":"correct-horse-battery","asLandlord":false}
                                """.formatted(email)))
                .andExpect(status().isCreated());

        start(email)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("Sign in instead")));
        assertThat(mailer.count()).isZero();
    }

    // ---- asking again -----------------------------------------------------

    @Test
    void a_second_code_inside_a_minute_is_refused() throws Exception {
        start(email).andExpect(status().isOk());

        // Otherwise the resend button is a tap-tap-tap and every tap is an
        // email somebody else has to receive.
        start(email)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.code").value("OTP_TOO_SOON"));
        assertThat(mailer.count()).isEqualTo(1);
    }

    @Test
    void after_a_minute_a_new_code_is_sent() throws Exception {
        start(email).andExpect(status().isOk());
        clock.advanceSeconds(61);

        start(email).andExpect(status().isOk());
        assertThat(mailer.count()).isEqualTo(2);
    }

    @Test
    void a_new_code_kills_the_one_before_it() throws Exception {
        start(email).andExpect(status().isOk());
        String first = mailer.lastCode();

        clock.advanceSeconds(61);
        start(email).andExpect(status().isOk());
        String second = mailer.lastCode();

        // "Send a new code" has to mean the old one is dead. Two live codes
        // would also split the attempt count between them.
        assertThat(first).isNotEqualTo(second);
        assertThat(verifications.consume(email, second)).isEqualTo(email);
    }

    @Test
    void five_codes_a_day_is_enough() throws Exception {
        for (int i = 0; i < 5; i++) {
            start(email).andExpect(status().isOk());
            clock.advanceSeconds(61);
        }

        // An open resend loop is unlimited mail, at Lizmo's cost, to any
        // address somebody cares to type.
        start(email)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.code").value("OTP_TOO_MANY"));
        assertThat(mailer.count()).isEqualTo(5);
    }

    @Test
    void tomorrow_the_allowance_comes_back() throws Exception {
        for (int i = 0; i < 5; i++) {
            start(email).andExpect(status().isOk());
            clock.advanceSeconds(61);
        }
        clock.advanceDays(1);

        start(email).andExpect(status().isOk());
    }

    // ---- checking ---------------------------------------------------------

    @Test
    void the_right_code_verifies_the_address() throws Exception {
        start(email).andExpect(status().isOk());

        assertThat(verifications.consume(email, mailer.lastCode())).isEqualTo(email);
    }

    @Test
    void a_code_works_once_and_never_again() throws Exception {
        start(email).andExpect(status().isOk());
        String code = mailer.lastCode();
        verifications.consume(email, code);

        // Otherwise the same digits verify again tomorrow, out of an inbox
        // that is no longer private.
        assertThatCode(email, code).hasMessageContaining("Ask for a code first");
    }

    @Test
    void a_code_expires_after_ten_minutes() throws Exception {
        start(email).andExpect(status().isOk());
        String code = mailer.lastCode();

        clock.advanceMinutes(11);
        assertThatCode(email, code).hasMessageContaining("expired");
    }

    @Test
    void nine_minutes_is_still_in_time() throws Exception {
        start(email).andExpect(status().isOk());
        String code = mailer.lastCode();

        clock.advanceMinutes(9);
        assertThat(verifications.consume(email, code)).isEqualTo(email);
    }

    @Test
    void expiry_is_checked_before_correctness() throws Exception {
        start(email).andExpect(status().isOk());
        clock.advanceMinutes(11);

        // A wrong code on an expired verification is told it expired, not that
        // it was wrong. Which means a right one gets the same answer -- so a
        // guesser never learns that a code was correct but late.
        assertThatCode(email, "000000").hasMessageContaining("expired");
    }

    @Test
    void a_wrong_code_says_how_many_tries_are_left() throws Exception {
        start(email).andExpect(status().isOk());

        assertThatCode(email, "000000").hasMessageContaining("4 tries left");
        assertThatCode(email, "000000").hasMessageContaining("3 tries left");
    }

    @Test
    void the_last_try_reads_as_one_try() throws Exception {
        start(email).andExpect(status().isOk());
        for (int i = 0; i < 3; i++) {
            assertThatCode(email, "000000");
        }

        // "1 tries left" is the kind of thing that makes an app feel unfinished.
        assertThatCode(email, "000000").hasMessageContaining("1 try left");
    }

    @Test
    void five_wrong_tries_burns_the_code() throws Exception {
        start(email).andExpect(status().isOk());
        String real = mailer.lastCode();

        for (int i = 0; i < 4; i++) {
            assertThatCode(email, "000000");
        }
        assertThatCode(email, "000000").hasMessageContaining("Too many wrong tries");

        // Six digits guessed freely falls in minutes. After the cap even the
        // correct code is worthless.
        assertThatCode(email, real).hasMessageContaining("Ask for a code first");
    }

    @Test
    void a_burned_code_does_not_block_a_new_one() throws Exception {
        start(email).andExpect(status().isOk());
        for (int i = 0; i < 5; i++) {
            assertThatCode(email, "000000");
        }

        // The dead row must be out of the way of the one-live-code index, or
        // somebody who mistyped five times could never sign up at all.
        clock.advanceSeconds(61);
        start(email).andExpect(status().isOk());
        assertThat(verifications.consume(email, mailer.lastCode())).isEqualTo(email);
    }

    @Test
    void a_code_for_an_address_that_never_asked_is_refused() throws Exception {
        assertThatCode("nobody@example.com", "123456")
                .hasMessageContaining("Ask for a code first");
    }

    private org.assertj.core.api.AbstractThrowableAssert<?, ?> assertThatCode(
            String address, String code) {
        return org.assertj.core.api.Assertions
                .assertThatThrownBy(() -> verifications.consume(address, code));
    }
}
