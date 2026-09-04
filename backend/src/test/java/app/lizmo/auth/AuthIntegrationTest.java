package app.lizmo.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.RecordingMailer;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

/**
 * Signing in, staying signed in, and being turned away.
 *
 * <p>What happens after an account exists. Making one is
 * {@link CompleteRegistrationIntegrationTest}'s subject, and is done here only
 * to have somebody to sign in as.
 */
class AuthIntegrationTest extends IntegrationTest {

    @Autowired
    private RecordingMailer mailer;

    @Test
    void signing_up_then_signing_in_and_refreshing() throws Exception {
        String email = "ana%d@example.com".formatted(System.nanoTime());
        String password = "Sunrise2Bed!";

        mvc.perform(post("/api/v1/auth/register/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"%s\"}".formatted(email)))
                .andExpect(status().isOk());

        mvc.perform(post("/api/v1/auth/register/complete")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s","name":"Ana Reyes","password":"%s"}
                                """.formatted(email, mailer.lastCode(), password)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                // A tenant and nothing else. There is no longer any way to hand
                // yourself a landlord profile on the way in.
                .andExpect(jsonPath("$.profiles[0]").value("TENANT"))
                .andExpect(jsonPath("$.profiles.length()").value(1));

        String loginBody = mvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"identifier":"%s","password":"%s"}
                                """.formatted(email, password)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        String refreshToken = json.readTree(loginBody).get("refreshToken").asText();

        JsonNode refreshed = json.readTree(mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(refreshToken)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());

        // Rotation: the new refresh token must differ from the one spent.
        assertThat(refreshed.get("refreshToken").asText()).isNotEqualTo(refreshToken);

        // And the spent one must no longer work.
        mvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}
                                """.formatted(refreshToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("REFRESH_TOKEN_INVALID"));
    }

    @Test
    void an_account_can_be_signed_in_with_the_password_it_was_given()
            throws Exception {
        // Tests everywhere else are handed a token rather than signing in. If
        // the seeded accounts were not real accounts, that shortcut would be
        // hiding something, so one of them signs in here for real.
        var ana = accounts.tenant("Ana");

        mvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"identifier":"%s","password":"%s"}
                                """.formatted(ana.email(), Accounts.PASSWORD)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(ana.id().toString()));
    }

    @Test
    void wrong_password_gives_the_same_error_as_unknown_account() throws Exception {
        mvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"identifier":"nobody@example.com","password":"whatever-goes-here"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
    }

    @Test
    void protected_route_without_a_token_is_401_not_403() throws Exception {
        // The clients rely on this distinction to decide whether to route to login.
        mvc.perform(get("/api/v1/properties"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHENTICATED"));
    }

    @Test
    void the_old_one_shot_registration_is_gone() throws Exception {
        // It took a name, a password and an unverified address, and would make
        // a landlord out of anyone who asked. An old build of the app still
        // pointing here must fail outright rather than half-work.
        mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Elena","email":"elena%d@example.com",
                                 "password":"correct-horse-battery","asLandlord":true}
                                """.formatted(System.nanoTime())))
                .andExpect(status().isNotFound());
    }
}
