package app.lizmo.billing.channel;

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
import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
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
 * How a tenant pays their landlord.
 *
 * <p>Every landlord here is a fresh account, so each test's channels are its
 * own and nothing needs clearing between them.
 */
class LandlordPaymentChannelIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    @Autowired
    private LandlordPaymentChannelRepository channels;

    @Autowired
    private StoredDocumentRepository documents;

    private Accounts.Account elena;
    private Accounts.Account mario;
    private String anaToken;
    private String beaToken;

    private String propertyId;
    private String unitId;
    private String leaseId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();

        elena = accounts.landlord("elena");
        mario = accounts.landlord("mario");
        anaToken = accounts.tenant("ana").token();
        beaToken = accounts.tenant("bea").token();

        String property = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        propertyId = json.readTree(property).get("id").asText();

        String unit = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        unitId = json.readTree(unit).get("id").asText();

        makeReadyForALease(anaToken);
        leaseId = letBed(anaToken);
    }

    // ---- what a tenant sees ------------------------------------------------------------

    @Test
    void a_landlord_adds_channels_and_their_tenant_sees_them_in_order() throws Exception {
        add(elena, "GCash", "Elena Reyes", "09171112222").andExpect(status().isCreated());
        add(elena, "BPI", "Elena Reyes", "1234 5678 90").andExpect(status().isCreated());

        details(anaToken)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.channels.length()").value(2))
                .andExpect(jsonPath("$.channels[0].channel").value("GCash"))
                .andExpect(jsonPath("$.channels[0].accountName").value("Elena Reyes"))
                .andExpect(jsonPath("$.channels[0].accountNumber").value("09171112222"))
                .andExpect(jsonPath("$.channels[1].channel").value("BPI"));
    }

    /** Taken down for the month, not gone: it comes back without retyping. */
    @Test
    void a_hidden_channel_is_kept_for_the_landlord_and_not_shown_to_tenants() throws Exception {
        String gcash = idOf(add(elena, "GCash", "Elena Reyes", "09171112222"));
        add(elena, "Maya", "Elena Reyes", "09173334444");

        change(elena, gcash, "GCash", "Elena Reyes", "09171112222", false)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.visible").value(false));

        details(anaToken)
                .andExpect(jsonPath("$.channels.length()").value(1))
                .andExpect(jsonPath("$.channels[0].channel").value("Maya"));
        mine(elena)
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].visible").value(false));
    }

    /** A tenant sees their own landlord's accounts, and nobody else's. */
    @Test
    void a_tenant_sees_only_their_own_landlords_channels() throws Exception {
        add(elena, "GCash", "Elena Reyes", "09171112222");
        add(mario, "GCash", "Mario Santos", "09995556666");

        details(anaToken)
                .andExpect(jsonPath("$.channels.length()").value(1))
                .andExpect(jsonPath("$.channels[0].accountName").value("Elena Reyes"));

        // Not Bea's lease, so not Bea's to read.
        details(beaToken).andExpect(status().isNotFound());
    }

    @Test
    void the_note_reads_back_for_the_tenant_and_blank_clears_it() throws Exception {
        note(elena, "Cash to Aling Nena at unit 1A").andExpect(status().isOk());

        details(anaToken)
                .andExpect(jsonPath("$.note").value("Cash to Aling Nena at unit 1A"))
                .andExpect(jsonPath("$.channels.length()").value(0));

        note(elena, "   ").andExpect(status().isOk());
        details(anaToken).andExpect(jsonPath("$.note").doesNotExist());
    }

    @Test
    void a_qr_reads_back_as_a_link_and_a_channel_without_one_has_none() throws Exception {
        String gcash = idOf(add(elena, "GCash", "Elena Reyes", "09171112222"));
        add(elena, "BPI", "Elena Reyes", "1234 5678 90");

        uploadQr(elena, gcash, image())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.qrUrl").isNotEmpty());

        details(anaToken)
                .andExpect(jsonPath("$.channels[0].qrUrl").isNotEmpty())
                .andExpect(jsonPath("$.channels[1].qrUrl").doesNotExist());
    }

    /** Some people move out owing a month, and still need to know where to send it. */
    @Test
    void a_tenant_who_has_moved_out_still_sees_how_to_pay() throws Exception {
        add(elena, "GCash", "Elena Reyes", "09171112222");
        mvc.perform(post("/api/v1/leases/" + leaseId + "/end")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\",\"reason\":\"Moved out\"}"
                                .formatted(LocalDate.now(clock))))
                .andExpect(status().isOk());

        details(anaToken)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.channels.length()").value(1));
    }

    // ---- keeping the list -----------------------------------------------------------------

    @Test
    void blank_account_details_are_refused() throws Exception {
        add(elena, "GCash", "Elena Reyes", "").andExpect(status().isBadRequest());
        add(elena, "GCash", "   ", "09171112222").andExpect(status().isBadRequest());

        mine(elena).andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void reordering_shows_them_in_the_order_given_and_a_partial_order_is_refused()
            throws Exception {
        String gcash = idOf(add(elena, "GCash", "Elena Reyes", "09171112222"));
        String bpi = idOf(add(elena, "BPI", "Elena Reyes", "1234 5678 90"));

        reorder(elena, List.of(gcash)).andExpect(status().isBadRequest());
        reorder(elena, List.of(bpi, gcash)).andExpect(status().isOk());

        details(anaToken)
                .andExpect(jsonPath("$.channels[0].channel").value("BPI"))
                .andExpect(jsonPath("$.channels[1].channel").value("GCash"));
    }

    /** An unpaid Lizmo statement stops a landlord growing, never a tenant paying. */
    @Test
    void a_locked_landlord_can_still_keep_their_channels() throws Exception {
        mvc.perform(post("/api/v1/admin/properties/" + propertyId + "/lock")
                        .header("Authorization", "Bearer " + accounts.admin("staff").token()))
                .andExpect(status().isOk());

        add(elena, "GCash", "Elena Reyes", "09171112222").andExpect(status().isCreated());
        details(anaToken).andExpect(jsonPath("$.channels.length()").value(1));
    }

    // ---- who may do what ----------------------------------------------------------------

    @Test
    void another_landlord_cannot_change_or_delete_a_channel() throws Exception {
        String gcash = idOf(add(elena, "GCash", "Elena Reyes", "09171112222"));

        change(mario, gcash, "GCash", "Mario Santos", "09995556666", null)
                .andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/me/payment-channels/" + gcash)
                        .header("Authorization", "Bearer " + mario.token()))
                .andExpect(status().isNotFound());

        details(anaToken).andExpect(jsonPath("$.channels[0].accountNumber").value("09171112222"));
    }

    @Test
    void a_tenant_cannot_keep_a_list_of_their_own() throws Exception {
        mvc.perform(post("/api/v1/me/payment-channels")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body("GCash", "Ana Cruz", "09170000000", null)))
                .andExpect(status().isNotFound());
    }

    @Test
    void nobody_signed_out_reads_where_rent_goes() throws Exception {
        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/payment-details"))
                .andExpect(status().isUnauthorized());
    }

    // ---- saying where it went -------------------------------------------------------------

    @Test
    void a_tenant_says_which_account_they_paid_and_the_landlord_sees_it() throws Exception {
        String gcash = idOf(add(elena, "GCash", "Elena Reyes", "09171112222"));

        declare(gcash)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.sentTo").value("GCash · Elena Reyes · 09171112222"));

        mvc.perform(get("/api/v1/leases/" + leaseId + "/payments")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(jsonPath("$[0].sentTo").value("GCash · Elena Reyes · 09171112222"));
    }

    @Test
    void cash_says_nowhere() throws Exception {
        declare(null)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.sentTo").doesNotExist());
    }

    /** What a payment claimed stays what it claimed, whatever happens to the channel. */
    @Test
    void the_record_survives_the_channel_being_changed_and_deleted() throws Exception {
        String gcash = idOf(add(elena, "GCash", "Elena Reyes", "09171112222"));
        declare(gcash).andExpect(status().isCreated());

        change(elena, gcash, "GCash", "Elena Reyes", "09179998888", null)
                .andExpect(status().isOk());
        mvc.perform(delete("/api/v1/me/payment-channels/" + gcash)
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/payments")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$[0].sentTo").value("GCash · Elena Reyes · 09171112222"));
    }

    /** A tenant picks from the list they were shown, and nothing else. */
    @Test
    void a_hidden_channel_or_another_landlords_cannot_be_picked() throws Exception {
        String hidden = idOf(add(elena, "GCash", "Elena Reyes", "09171112222"));
        change(elena, hidden, "GCash", "Elena Reyes", "09171112222", false);
        String marios = idOf(add(mario, "GCash", "Mario Santos", "09995556666"));

        declare(hidden).andExpect(status().isNotFound());
        declare(marios).andExpect(status().isNotFound());
    }

    // ---- closing an account --------------------------------------------------------------

    /** Account numbers and QR codes are personal details, and go with the account. */
    @Test
    void closing_a_landlord_account_removes_their_channels_and_qr_codes() throws Exception {
        String gcash = idOf(add(mario, "GCash", "Mario Santos", "09995556666"));
        uploadQr(mario, gcash, image()).andExpect(status().isOk());
        note(mario, "Cash at the store").andExpect(status().isOk());

        mvc.perform(delete("/api/v1/me")
                        .header("Authorization", "Bearer " + mario.token()))
                .andExpect(status().isNoContent());

        assertThat(channels.findByLandlordIdOrderBySortOrderAsc(mario.id())).isEmpty();
        assertThat(documents.findByOwnerTypeAndOwnerId(
                        DocumentOwnerType.LANDLORD_PAYMENT_CHANNEL, UUID.fromString(gcash)))
                .isEmpty();
    }

    // ---- fixtures -----------------------------------------------------------------------------

    private ResultActions add(Accounts.Account landlord, String channel, String name, String number)
            throws Exception {
        return mvc.perform(post("/api/v1/me/payment-channels")
                .header("Authorization", "Bearer " + landlord.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(channel, name, number, null)));
    }

    private ResultActions change(
            Accounts.Account landlord, String id, String channel, String name, String number,
            Boolean visible) throws Exception {
        return mvc.perform(put("/api/v1/me/payment-channels/" + id)
                .header("Authorization", "Bearer " + landlord.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(channel, name, number, visible)));
    }

    private ResultActions reorder(Accounts.Account landlord, List<String> ids) throws Exception {
        return mvc.perform(put("/api/v1/me/payment-channels/order")
                .header("Authorization", "Bearer " + landlord.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("ids", ids))));
    }

    private ResultActions note(Accounts.Account landlord, String note) throws Exception {
        return mvc.perform(put("/api/v1/me/payment-note")
                .header("Authorization", "Bearer " + landlord.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("note", note))));
    }

    private ResultActions uploadQr(Accounts.Account landlord, String id, byte[] bytes)
            throws Exception {
        return mvc.perform(multipart("/api/v1/me/payment-channels/" + id + "/qr")
                .file(new MockMultipartFile("qr", "qr.png", "image/png", bytes))
                .header("Authorization", "Bearer " + landlord.token()));
    }

    private ResultActions mine(Accounts.Account landlord) throws Exception {
        return mvc.perform(get("/api/v1/me/payment-channels")
                .header("Authorization", "Bearer " + landlord.token()));
    }

    private ResultActions details(String tenantToken) throws Exception {
        return mvc.perform(get("/api/v1/me/leases/" + leaseId + "/payment-details")
                .header("Authorization", "Bearer " + tenantToken));
    }

    private ResultActions declare(String channelId) throws Exception {
        String period = json.readTree(mvc.perform(get("/api/v1/leases/" + leaseId + "/billing")
                                .header("Authorization", "Bearer " + elena.token()))
                        .andReturn().getResponse().getContentAsString())
                .get(0).get("id").asText();

        var fields = new LinkedHashMap<String, Object>();
        fields.put("billingPeriodId", period);
        fields.put("amountPaid", 2500.00);
        fields.put("paymentMethod", "GCASH");
        if (channelId != null) {
            fields.put("channelId", channelId);
        }

        return mvc.perform(multipart("/api/v1/me/leases/" + leaseId + "/payments")
                .file(new MockMultipartFile("payment", "", "application/json",
                        json.writeValueAsBytes(fields)))
                .header("Authorization", "Bearer " + anaToken));
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
        return json.readTree(added.andReturn().getResponse().getContentAsString())
                .get("id").asText();
    }

    private String letBed(String tenantToken) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString();
        String bed = json.readTree(beds).get(0).get("id").asText();

        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bed)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String lease = mvc.perform(post("/api/v1/rental-requests/"
                        + json.readTree(request).get("id").asText() + "/accept")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rentAmount\":2500.00,\"startDate\":\"%s\"}"
                                .formatted(LocalDate.now(clock))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(lease).get("id").asText();
    }

    private void makeReadyForALease(String token) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"emergencyContactName":"Rosa Dela Cruz",
                                 "emergencyContactPhone":"09171234567",
                                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                                """))
                .andExpect(status().isOk());

        for (String kind : new String[] {"VALID_ID", "TENANT_PHOTO"}) {
            mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                            .file(new MockMultipartFile("file", "p.jpg", "image/jpeg", photo()))
                            .param("docType", kind)
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isCreated());
        }
    }

    private static byte[] photo() throws Exception {
        BufferedImage picture = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        picture.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(picture, "jpg", out);
        return out.toByteArray();
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
