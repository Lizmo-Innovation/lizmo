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
}
