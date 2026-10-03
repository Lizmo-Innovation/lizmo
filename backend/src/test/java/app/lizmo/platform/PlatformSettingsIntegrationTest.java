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
        setMinimums(accounts.admin("Lizmo Staff").token(), "1.1.1", "1.1.0");

        // No token: the app asks before anybody signs in.
        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.minimumAndroidVersion").value("1.1.1"))
                .andExpect(jsonPath("$.minimumIosVersion").value("1.1.0"));
    }

    /**
     * An operator who has never set one turns nobody away. Asserted on the
     * service rather than the endpoint, because the rows these tests share
     * cannot be unset once another test has written them.
     */
    @Test
    void an_unset_minimum_lets_everybody_in() {
        settings.findById(PlatformSettingsService.MINIMUM_ANDROID_VERSION)
                .ifPresent(settings::delete);

        org.assertj.core.api.Assertions.assertThat(platformSettings.minimumAndroidVersion())
                .isNull();
    }

    @Test
    void an_admin_sets_the_minimum_and_where_to_update() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();

        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.test",
                                 "minimumAndroidVersion":"1.1.1",
                                 "androidUpdateUrl":"https://play.google.com/store/apps/details?id=app.lizmo"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.minimumAndroidVersion").value("1.1.1"));

        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(jsonPath("$.minimumAndroidVersion").value("1.1.1"))
                .andExpect(jsonPath("$.androidUpdateUrl")
                        .value("https://play.google.com/store/apps/details?id=app.lizmo"));
    }

    /**
     * The two platforms are set apart, because they ship apart: an iOS
     * release can sit in review for a week after the Android one is out.
     */
    @Test
    void stopping_android_leaves_ios_alone() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();
        setMinimums(adminToken, "1.2.0", "");

        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(jsonPath("$.minimumAndroidVersion").value("1.2.0"))
                .andExpect(jsonPath("$.minimumIosVersion").doesNotExist());
    }

    /**
     * A console that only saves the support address must not turn the version
     * check off by leaving the field out of what it sends.
     */
    @Test
    void settings_left_out_are_left_alone() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();
        setMinimums(adminToken, "1.1.1", "1.1.0");

        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"supportEmail\":\"help@lizmo.test\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.minimumAndroidVersion").value("1.1.1"))
                .andExpect(jsonPath("$.minimumIosVersion").value("1.1.0"));
    }

    /** Back to letting everybody in, which is what blank is for. */
    @Test
    void the_check_can_be_turned_off_again() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();
        setMinimums(adminToken, "1.1.1", "1.1.0");
        setMinimums(adminToken, "", "");

        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(jsonPath("$.minimumAndroidVersion").doesNotExist())
                .andExpect(jsonPath("$.minimumIosVersion").doesNotExist());
    }

    /**
     * Stored and then quietly ignored by every app that fetches it is the
     * worst outcome: a minimum the operator believes is in force and is not.
     */
    @Test
    void a_version_the_app_could_not_read_is_refused() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();

        for (String bad : new String[] {"v1.1.1", "1.0.0-beta", "1.1.1.1", "latest"}) {
            mvc.perform(put("/api/v1/admin/settings")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"supportEmail":"help@lizmo.test","minimumAndroidVersion":"%s"}
                                    """.formatted(bad)))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.message")
                            .value(org.hamcrest.Matchers.containsString("1.1.1")));
        }
    }

    /** Fewer parts are a version too: 1.2 is as valid as 1.2.0. */
    @Test
    void a_shorter_version_is_fine() throws Exception {
        String adminToken = accounts.admin("Lizmo Staff").token();
        setMinimums(adminToken, "2", "1.2");

        mvc.perform(get("/api/v1/platform/app-version"))
                .andExpect(jsonPath("$.minimumAndroidVersion").value("2"))
                .andExpect(jsonPath("$.minimumIosVersion").value("1.2"));
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

    private void setMinimums(String adminToken, String android, String ios) throws Exception {
        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.test",
                                 "minimumAndroidVersion":"%s",
                                 "minimumIosVersion":"%s"}
                                """.formatted(android, ios)))
                .andExpect(status().isOk());
    }
}
