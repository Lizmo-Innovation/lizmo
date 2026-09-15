package app.lizmo.platform.payment;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Where landlords send money to Lizmo.
 *
 * <p>The channel table is global, and only this class writes to it, so each
 * test starts from an empty list rather than scoping every assertion.
 */
class PaymentChannelIntegrationTest extends IntegrationTest {

    @Autowired
    private PaymentChannelRepository channels;

    @Autowired
    private StoredDocumentRepository documents;

    private String adminToken;
    private String landlordToken;

    @BeforeEach
    void setUp() {
        channels.deleteAll();
        adminToken = accounts.admin("staff").token();
        landlordToken = accounts.landlord("elena").token();
    }

    // ---- what a landlord sees --------------------------------------------------------

    @Test
    void an_admin_adds_channels_and_a_landlord_sees_them_in_order() throws Exception {
        add("GCash", "Ariel Asebias", "09771231234").andExpect(status().isCreated());
        add("BPI", "Lizmo Innovation", "1234 5678 90").andExpect(status().isCreated());

        details()
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.channels.length()").value(2))
                .andExpect(jsonPath("$.channels[0].channel").value("GCash"))
                .andExpect(jsonPath("$.channels[0].accountName").value("Ariel Asebias"))
                .andExpect(jsonPath("$.channels[0].accountNumber").value("09771231234"))
                .andExpect(jsonPath("$.channels[1].channel").value("BPI"));
    }

    /** Taken down for the month, not gone: it comes back without retyping. */
    @Test
    void a_hidden_channel_is_kept_for_the_admin_and_not_shown_to_landlords() throws Exception {
        String gcash = idOf(add("GCash", "Ariel Asebias", "09771231234"));
        add("Maya", "Ariel Asebias", "09170000000");

        change(gcash, "GCash", "Ariel Asebias", "09771231234", false)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.visible").value(false));

        details()
                .andExpect(jsonPath("$.channels.length()").value(1))
                .andExpect(jsonPath("$.channels[0].channel").value("Maya"));
        adminList()
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].visible").value(false));

        change(gcash, "GCash", "Ariel Asebias", "09771231234", true);
        details().andExpect(jsonPath("$.channels.length()").value(2));
    }

    /** Changing the number without saying whether it is shown leaves it shown. */
    @Test
    void editing_details_leaves_visibility_alone() throws Exception {
        String gcash = idOf(add("GCash", "Ariel Asebias", "09771231234"));

        change(gcash, "GCash", "Ariel Asebias", "09179999999", null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accountNumber").value("09179999999"))
                .andExpect(jsonPath("$.visible").value(true));
    }

    @Test
    void the_note_reads_back_beside_the_channels() throws Exception {
        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.app",
                                 "paymentInstructions":"Put your property name in the reference."}
                                """))
                .andExpect(status().isOk());

        details().andExpect(jsonPath("$.note").value("Put your property name in the reference."));
    }

    // ---- the QR ---------------------------------------------------------------------------

    @Test
    void a_qr_reads_back_as_a_link_and_a_channel_without_one_has_none() throws Exception {
        String gcash = idOf(add("GCash", "Ariel Asebias", "09771231234"));
        add("BPI", "Lizmo Innovation", "1234 5678 90");

        uploadQr(gcash, image())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.qrUrl").isNotEmpty());

        details()
                .andExpect(jsonPath("$.channels[0].qrUrl").isNotEmpty())
                .andExpect(jsonPath("$.channels[0].qrUrlExpiresInSeconds").value(600))
                .andExpect(jsonPath("$.channels[1].qrUrl").doesNotExist());
    }

    /** One QR per channel, so "which code do I scan" has one answer. */
    @Test
    void a_new_qr_replaces_the_old_one_and_can_be_removed() throws Exception {
        String gcash = idOf(add("GCash", "Ariel Asebias", "09771231234"));
        uploadQr(gcash, image()).andExpect(status().isOk());
        uploadQr(gcash, image()).andExpect(status().isOk());

        assertThat(documents.findByOwnerTypeAndOwnerId(
                        DocumentOwnerType.PLATFORM_PAYMENT_CHANNEL, UUID.fromString(gcash)))
                .hasSize(1);

        mvc.perform(delete("/api/v1/admin/platform-payment-channels/" + gcash + "/qr")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.qrUrl").doesNotExist())
                .andExpect(jsonPath("$.accountNumber").value("09771231234"));
    }

    @Test
    void a_qr_that_is_not_an_image_is_refused() throws Exception {
        String gcash = idOf(add("GCash", "Ariel Asebias", "09771231234"));

        uploadQr(gcash, "not a picture".getBytes()).andExpect(status().isBadRequest());
    }

    // ---- keeping the list ------------------------------------------------------------------

    /** A channel with no number is a landlord told to pay and unable to. */
    @Test
    void blank_account_details_are_refused() throws Exception {
        add("GCash", "Ariel Asebias", "").andExpect(status().isBadRequest());
        add("GCash", "   ", "09771231234").andExpect(status().isBadRequest());
        add("", "Ariel Asebias", "09771231234").andExpect(status().isBadRequest());

        adminList().andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void deleting_one_leaves_the_rest() throws Exception {
        String gcash = idOf(add("GCash", "Ariel Asebias", "09771231234"));
        uploadQr(gcash, image());
        add("Maya", "Ariel Asebias", "09170000000");

        mvc.perform(delete("/api/v1/admin/platform-payment-channels/" + gcash)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNoContent());

        details()
                .andExpect(jsonPath("$.channels.length()").value(1))
                .andExpect(jsonPath("$.channels[0].channel").value("Maya"));
    }

    @Test
    void reordering_shows_them_in_the_order_given() throws Exception {
        String gcash = idOf(add("GCash", "Ariel Asebias", "09771231234"));
        String maya = idOf(add("Maya", "Ariel Asebias", "09170000000"));
        String bpi = idOf(add("BPI", "Lizmo Innovation", "1234 5678 90"));

        reorder(List.of(bpi, gcash, maya))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].channel").value("BPI"));

        details()
                .andExpect(jsonPath("$.channels[0].channel").value("BPI"))
                .andExpect(jsonPath("$.channels[1].channel").value("GCash"))
                .andExpect(jsonPath("$.channels[2].channel").value("Maya"));
    }

    /** Half an order leaves the rest colliding, so it is refused whole. */
    @Test
    void an_order_missing_a_channel_or_repeating_one_is_refused() throws Exception {
        add("GCash", "Ariel Asebias", "09771231234");
        String maya = idOf(add("Maya", "Ariel Asebias", "09170000000"));

        reorder(List.of(maya)).andExpect(status().isBadRequest());
        reorder(List.of(maya, maya)).andExpect(status().isBadRequest());

        // Untouched: GCash still first.
        details().andExpect(jsonPath("$.channels[0].channel").value("GCash"));
    }

    @Test
    void a_channel_that_does_not_exist_is_not_found() throws Exception {
        change("00000000-0000-0000-0000-000000000000", "GCash", "A", "1", null)
                .andExpect(status().isNotFound());
    }

    // ---- who may do what --------------------------------------------------------------------

    @Test
    void a_landlord_cannot_manage_channels_or_see_hidden_ones() throws Exception {
        mvc.perform(post("/api/v1/admin/platform-payment-channels")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body("GCash", "Somebody Else", "09990000000", null)))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/platform-payment-channels")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isForbidden());

        adminList().andExpect(jsonPath("$.length()").value(0));
    }

    /** Tenants never pay Lizmo, so they are not shown where Lizmo is paid. */
    @Test
    void a_tenant_is_not_told_where_lizmo_is_paid() throws Exception {
        add("GCash", "Ariel Asebias", "09771231234");

        mvc.perform(get("/api/v1/me/platform-payment-details")
                        .header("Authorization", "Bearer " + accounts.tenant("ana").token()))
                .andExpect(status().isNotFound());
    }

    @Test
    void nobody_signed_out_reads_where_the_money_goes() throws Exception {
        mvc.perform(get("/api/v1/me/platform-payment-details"))
                .andExpect(status().isUnauthorized());
    }

    // ---- fixtures -----------------------------------------------------------------------------

    private ResultActions add(String channel, String name, String number) throws Exception {
        return mvc.perform(post("/api/v1/admin/platform-payment-channels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(channel, name, number, null)));
    }

    private ResultActions change(
            String id, String channel, String name, String number, Boolean visible)
            throws Exception {
        return mvc.perform(put("/api/v1/admin/platform-payment-channels/" + id)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(channel, name, number, visible)));
    }

    private ResultActions reorder(List<String> ids) throws Exception {
        return mvc.perform(put("/api/v1/admin/platform-payment-channels/order")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("ids", ids))));
    }

    private ResultActions uploadQr(String id, byte[] bytes) throws Exception {
        return mvc.perform(multipart("/api/v1/admin/platform-payment-channels/" + id + "/qr")
                .file(new MockMultipartFile("qr", "qr.png", "image/png", bytes))
                .header("Authorization", "Bearer " + adminToken));
    }

    private ResultActions details() throws Exception {
        return mvc.perform(get("/api/v1/me/platform-payment-details")
                .header("Authorization", "Bearer " + landlordToken));
    }

    private ResultActions adminList() throws Exception {
        return mvc.perform(get("/api/v1/admin/platform-payment-channels")
                .header("Authorization", "Bearer " + adminToken));
    }

    private String body(String channel, String name, String number, Boolean visible)
            throws Exception {
        var fields = new LinkedHashMap<String, Object>();
        fields.put("channel", channel);
        fields.put("accountName", name);
        fields.put("accountNumber", number);
        if (visible != null) {
            fields.put("visible", visible);
        }
        return json.writeValueAsString(fields);
    }

    private String idOf(ResultActions added) throws Exception {
        String body = added.andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("id").asText();
    }

    private static byte[] image() throws Exception {
        BufferedImage picture = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        var graphics = picture.createGraphics();
        graphics.setColor(Color.WHITE);
        graphics.fillRect(0, 0, 64, 64);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(picture, "png", out);
        return out.toByteArray();
    }
}
