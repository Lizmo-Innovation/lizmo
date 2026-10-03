package app.lizmo.platform;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/**
 * The address a stranger is told to write to.
 *
 * <p>Published on a page that must work for somebody who has already
 * uninstalled the app, and changeable without a deploy — an address that can
 * only be corrected by rebuilding is one that stays wrong for a week.
 */
class PlatformSettingsIntegrationTest extends IntegrationTest {

    @org.springframework.beans.factory.annotation.Autowired
    private PlatformSettingRepository settings;

    @org.springframework.beans.factory.annotation.Autowired
    private PlatformSettingsService platformSettings;

    @Test
    void anybody_can_read_where_to_write() throws Exception {
        // No token: the account deletion page is public by requirement.
        mvc.perform(get("/api/v1/platform/support"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(org.hamcrest.Matchers.containsString("@")));
    }

    @Test
    void only_staff_can_change_it() throws Exception {
        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + accounts.landlord("elena").token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"supportEmail\":\"someone@example.com\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void an_admin_changes_it_and_the_public_page_follows() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();

        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"supportEmail\":\"help@lizmo.test\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.supportEmail").value("help@lizmo.test"));

        mvc.perform(get("/api/v1/platform/support"))
                .andExpect(jsonPath("$.email").value("help@lizmo.test"));
    }

    @Test
    void nonsense_is_refused() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();

        // A typo here is a deletion request nobody ever receives.
        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"supportEmail\":\"not-an-address\"}"))
                .andExpect(status().isBadRequest());
    }

    // ---- the app people are running ------------------------------------------------

    /**
     * Asked on the splash screen, before anybody signs in: an app too old to
     * be allowed in cannot first be made to log in.
     */
    @Test
    void anybody_can_ask_what_the_oldest_allowed_app_is() throws Exception {
        setMinimum(accounts.admin("Lizmo Staff").token(), 7);

        // No token: the app asks before anybody signs in.
        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.minimumBuild").value(7));
    }

    /**
     * An operator who has never set one turns nobody away. Asserted on the
     * service rather than the endpoint, because the row these tests share
     * cannot be unset once another test has written it.
     */
    @Test
    void an_unset_minimum_lets_everybody_in() {
        settings.findById(PlatformSettingsService.MINIMUM_APP_BUILD)
                .ifPresent(settings::delete);

        org.assertj.core.api.Assertions.assertThat(platformSettings.minimumAppBuild())
                .isZero();
    }

    @Test
    void an_admin_sets_the_minimum_and_where_to_update() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();

        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.test",
                                 "minimumAppBuild":7,
                                 "androidUpdateUrl":"https://play.google.com/store/apps/details?id=app.lizmo"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.minimumAppBuild").value(7));

        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(jsonPath("$.minimumBuild").value(7))
                .andExpect(jsonPath("$.androidUpdateUrl")
                        .value("https://play.google.com/store/apps/details?id=app.lizmo"));
    }

    /**
     * A console that only saves the support address must not turn the version
     * check off by leaving the field out of what it sends.
     */
    @Test
    void settings_left_out_are_left_alone() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();
        setMinimum(adminToken, 7);

        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"supportEmail\":\"help@lizmo.test\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.minimumAppBuild").value(7));

        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(jsonPath("$.minimumBuild").value(7));
    }

    /** Back to letting everybody in, which is what zero is for. */
    @Test
    void the_check_can_be_turned_off_again() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();
        setMinimum(adminToken, 7);
        setMinimum(adminToken, 0);

        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(jsonPath("$.minimumBuild").value(0));
    }

    /**
     * An app told to update, with an address it cannot follow, is a dead end.
     */
    @Test
    void an_update_link_that_is_not_a_link_is_refused() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();

        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.test",
                                 "androidUpdateUrl":"play.google.com/lizmo"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.containsString("https://")));
    }

    /** How an operator stops pointing at a store that has not published yet. */
    @Test
    void a_blank_link_clears_it() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();
        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.test",
                                 "iosUpdateUrl":"https://apps.apple.com/app/lizmo"}
                                """))
                .andExpect(jsonPath("$.iosUpdateUrl").value("https://apps.apple.com/app/lizmo"));

        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.test","iosUpdateUrl":""}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.iosUpdateUrl").doesNotExist());
    }

    @Test
    void a_negative_build_is_refused() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();

        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.test","minimumAppBuild":-1}
                                """))
                .andExpect(status().isBadRequest());
    }

    private void setMinimum(String adminToken, int build) throws Exception {
        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.test","minimumAppBuild":%d}
                                """.formatted(build)))
                .andExpect(status().isOk());
    }
}
