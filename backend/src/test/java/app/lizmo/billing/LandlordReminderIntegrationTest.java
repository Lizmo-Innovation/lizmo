package app.lizmo.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import com.fasterxml.jackson.databind.JsonNode;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;
import org.springframework.test.web.servlet.ResultActions;

/**
 * A landlord reminding a tenant by hand, and what Today is told about the
 * payments and tenancies it lists.
 */
class LandlordReminderIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private Accounts.Account elena;
    private Accounts.Account ana;
    private String unitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();
        elena = accounts.landlord("Elena");
        ana = tenant("Ana");
        String property = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();
        unitId = json.readTree(mvc.perform(post("/api/v1/properties/" + property + "/units")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();
    }

    // ---- reminding ---------------------------------------------------------

    @Test
    void a_tenant_behind_is_told_what_is_owed_and_nothing_else() throws Exception {
        String lease = let(ana, 0, LocalDate.now(clock).minusDays(12));

        remind(lease).andExpect(status().isOk()).andExpect(jsonPath("$.sentAt").isNotEmpty());

        JsonNode told = reminderTo(ana);
        assertThat(told.get("message").asText()).contains("P2500 is overdue");
        assertThat(told.get("message").asText().toLowerCase())
                .doesNotContain("penalty").doesNotContain("fee").doesNotContain("evict");
    }

    /** Tapped twice, or every hour: it would stop being a reminder. */
    @Test
    void once_a_day_at_most() throws Exception {
        String lease = let(ana, 0, LocalDate.now(clock).minusDays(12));
        remind(lease).andExpect(status().isOk());

        remind(lease).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("You reminded them today. Another can go tomorrow."));

        clock.advanceDays(1);
        remind(lease).andExpect(status().isOk());
    }

    @Test
    void nothing_late_is_nothing_to_remind() throws Exception {
        String lease = let(ana, 0, LocalDate.now(clock).plusDays(3));

        remind(lease).andExpect(status().isBadRequest());
    }

    @Test
    void only_their_landlord_can() throws Exception {
        String lease = let(ana, 0, LocalDate.now(clock).minusDays(12));

        mvc.perform(post("/api/v1/leases/" + lease + "/remind")
                        .header("Authorization", "Bearer " + accounts.landlord("Mario").token()))
                .andExpect(status().isNotFound());
    }

    // ---- what Today is told ------------------------------------------------

    @Test
    void today_knows_who_was_reminded() throws Exception {
        String lease = let(ana, 0, LocalDate.now(clock).minusDays(12));
        JsonNode before = behind(lease);
        assertThat(before.get("remindedAt").isNull()).isTrue();

        remind(lease).andExpect(status().isOk());

        assertThat(behind(lease).get("remindedAt").isNull()).isFalse();
    }

    /** Oldest first: the month late longest is the one to deal with. */
    @Test
    void behind_is_oldest_first() throws Exception {
        Accounts.Account bea = tenant("Bea");
        String recent = let(ana, 0, LocalDate.now(clock).minusDays(5));
        String older = let(bea, 1, LocalDate.now(clock).minusDays(20));

        JsonNode rows = collections().get("inArrears");
        int recentAt = -1;
        int olderAt = -1;
        for (int i = 0; i < rows.size(); i++) {
            String id = rows.get(i).get("leaseId").asText();
            if (id.equals(recent)) recentAt = i;
            if (id.equals(older)) olderAt = i;
        }
        assertThat(olderAt).isLessThan(recentAt);
    }

    @Test
    void a_payment_to_confirm_carries_how_and_its_screenshot() throws Exception {
        String lease = let(ana, 0, LocalDate.now(clock));
        String month = json.readTree(mvc.perform(get("/api/v1/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();
        mvc.perform(multipart("/api/v1/me/leases/" + lease + "/payments")
                        .file(new MockMultipartFile("proof", "gcash.jpg", "image/jpeg", photo()))
                        .part(new MockPart("billingPeriodId", month.getBytes()))
                        .part(new MockPart("amountPaid", "2500".getBytes()))
                        .part(new MockPart("paymentMethod", "GCASH".getBytes()))
                        .part(new MockPart("remarks", "Ref 0042 1234".getBytes()))
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isCreated());

        JsonNode waiting = null;
        for (JsonNode row : collections().get("awaiting")) {
            if (row.get("leaseId").asText().equals(lease)) waiting = row;
        }
        assertThat(waiting).isNotNull();
        assertThat(waiting.get("paymentMethod").asText()).isEqualTo("GCASH");
        assertThat(waiting.get("remarks").asText()).isEqualTo("Ref 0042 1234");
        assertThat(waiting.get("proofUrl").asText()).isNotBlank();
    }

    // ---- fixtures ----------------------------------------------------------

    private ResultActions remind(String lease) throws Exception {
        return mvc.perform(post("/api/v1/leases/" + lease + "/remind")
                .header("Authorization", "Bearer " + elena.token()));
    }

    private JsonNode collections() throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/me/collections")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private JsonNode behind(String lease) throws Exception {
        for (JsonNode row : collections().get("inArrears")) {
            if (row.get("leaseId").asText().equals(lease)) return row;
        }
        throw new AssertionError("not behind");
    }

    private JsonNode reminderTo(Accounts.Account who) throws Exception {
        JsonNode all = json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + who.token()))
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        for (JsonNode one : all) {
            if (one.get("title").asText().equals("A reminder from your landlord")) return one;
        }
        throw new AssertionError("no reminder in " + all);
    }

    /** Bed {@code index} of 2B, from {@code start}. */
    private String let(Accounts.Account tenant, int index, LocalDate start) throws Exception {
        String bed = json.readTree(mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString()).get(index).get("id").asText();
        return json.readTree(letRoom(elena.token(), tenant.token(),
                        "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bed),
                        "{\"startDate\":\"%s\"}".formatted(start)))
                .get("id").asText();
    }

    private Accounts.Account tenant(String name) throws Exception {
        Accounts.Account tenant = accounts.tenant(name);
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenant.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
                                 "emergencyContactPhone":"09171234567",
                                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                                """))
                .andExpect(status().isOk());
        for (String kind : new String[] {"VALID_ID", "TENANT_PHOTO"}) {
            mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                            .file(new MockMultipartFile("file", "p.jpg", "image/jpeg", photo()))
                            .param("docType", kind)
                            .header("Authorization", "Bearer " + tenant.token()))
                    .andExpect(status().isCreated());
        }
        return tenant;
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
