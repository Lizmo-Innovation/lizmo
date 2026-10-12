package app.lizmo.billing.receipt;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Acknowledgement receipts: one for every payment a landlord confirms or
 * records, numbered per landlord per year, and never changed after.
 */
class ReceiptIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbc;

    private Accounts.Account elena;
    private Accounts.Account ana;
    private String propertyId;
    private String unitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();
        elena = accounts.landlord("Elena");
        ana = accounts.tenant("Ana");

        propertyId = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(property("Sunrise Apartments")))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        unitId = json.readTree(mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        makeReadyForALease(ana.token());
    }

    // ---- when one is issued ------------------------------------------------

    @Test
    void confirming_a_payment_issues_a_receipt() throws Exception {
        String lease = let(null);
        String month = firstMonth(lease);
        String payment = declare(lease, month, 2500);

        confirm(lease, payment)
                .andExpect(jsonPath("$.receiptNumber").value(year() + "-0001"));

        JsonNode receipt = receipts(ana, lease).get(0);
        assertThat(receipt.get("number").asText()).isEqualTo(year() + "-0001");
        assertThat(receipt.get("paymentId").asText()).isEqualTo(payment);
        assertThat(receipt.get("receivedFrom").asText()).isEqualTo("Ana");
        assertThat(receipt.get("receivedBy").asText()).isEqualTo("Elena");
        assertThat(receipt.get("propertyName").asText()).isEqualTo("Sunrise Apartments");
        assertThat(receipt.get("place").asText()).isEqualTo("Bed 1, 2B");
        assertThat(receipt.get("kind").asText()).isEqualTo("RENT");
        assertThat(receipt.get("amount").decimalValue()).isEqualByComparingTo("2500");
        assertThat(receipt.get("paymentMethod").asText()).isEqualTo("GCASH");
        assertThat(receipt.get("paidOn").asText()).isEqualTo(today().toString());
        assertThat(receipt.get("stillOwed").decimalValue()).isEqualByComparingTo("0");
    }

    @Test
    void recording_a_payment_issues_one_too() throws Exception {
        String lease = let(null);

        record(lease, firstMonth(lease), "2500");

        JsonNode receipt = receipts(ana, lease).get(0);
        assertThat(receipt.get("number").asText()).isEqualTo(year() + "-0001");
        assertThat(receipt.get("paymentMethod").asText()).isEqualTo("CASH");
    }

    /** Nothing is acknowledged until the landlord says it arrived. */
    @Test
    void a_payment_still_waiting_has_none() throws Exception {
        String lease = let(null);
        declare(lease, firstMonth(lease), 2500);

        assertThat(receipts(ana, lease)).isEmpty();
        mvc.perform(get("/api/v1/me/leases/" + lease + "/payments")
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(jsonPath("$[0].receiptNumber").doesNotExist());
    }

    @Test
    void nor_does_one_the_landlord_refused() throws Exception {
        String lease = let(null);
        String payment = declare(lease, firstMonth(lease), 2500);

        mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + payment + "/reject")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isOk());

        assertThat(receipts(ana, lease)).isEmpty();
    }

    /** "Thank you" told them nothing they could keep; the number does. */
    @Test
    void the_tenant_is_told_its_number() throws Exception {
        String lease = let(null);
        confirm(lease, declare(lease, firstMonth(lease), 2500));

        assertThat(messagesTo(ana))
                .anyMatch(message -> message.contains("Receipt " + year() + "-0001."));
    }

    // ---- what it says ------------------------------------------------------

    @Test
    void part_of_a_month_says_what_is_left() throws Exception {
        String lease = let(null);
        String month = firstMonth(lease);

        confirm(lease, declare(lease, month, 1000));
        confirm(lease, declare(lease, month, 1500));

        JsonNode both = receipts(ana, lease);
        assertThat(both.get(1).get("stillOwed").decimalValue()).isEqualByComparingTo("1500");
        assertThat(both.get(0).get("stillOwed").decimalValue()).isEqualByComparingTo("0");
    }

    @Test
    void a_deposit_says_it_is_one() throws Exception {
        String lease = let("\"depositAmount\":5000.00");
        String deposit = null;
        for (JsonNode month : months(lease)) {
            if (month.get("kind").asText().equals("DEPOSIT")) {
                deposit = month.get("id").asText();
            }
        }

        record(lease, deposit, "5000");

        JsonNode receipt = receipts(ana, lease).get(0);
        assertThat(receipt.get("kind").asText()).isEqualTo("DEPOSIT");
        assertThat(receipt.get("periodLabel").asText()).isEqualTo("Security deposit");
    }

    /** Handed to an employer, it must say next year what it said this year. */
    @Test
    void it_does_not_change_when_the_property_does() throws Exception {
        String lease = let(null);
        record(lease, firstMonth(lease), "2500");

        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(property("Sunrise Residences")))
                .andExpect(status().isOk());

        assertThat(receipts(ana, lease).get(0).get("propertyName").asText())
                .isEqualTo("Sunrise Apartments");
    }

    // ---- numbering ---------------------------------------------------------

    @Test
    void numbers_go_in_order_newest_first() throws Exception {
        String lease = let(null);
        String month = firstMonth(lease);
        confirm(lease, declare(lease, month, 1000));
        confirm(lease, declare(lease, month, 1000));
        record(lease, month, "500");

        JsonNode all = receipts(elena, lease);
        assertThat(all).hasSize(3);
        assertThat(all.get(0).get("number").asText()).isEqualTo(year() + "-0003");
        assertThat(all.get(1).get("number").asText()).isEqualTo(year() + "-0002");
        assertThat(all.get(2).get("number").asText()).isEqualTo(year() + "-0001");
    }

    /** Each landlord files their own; another's receipts are not in their run. */
    @Test
    void each_landlord_counts_their_own() throws Exception {
        String first = let(null);
        record(first, firstMonth(first), "2500");

        Accounts.Account mario = accounts.landlord("Mario");
        Accounts.Account bea = accounts.tenant("Bea");
        makeReadyForALease(bea.token());
        String marios = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + mario.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(property("Mario's Place")))
                .andReturn().getResponse().getContentAsString()).get("id").asText();
        String unit = json.readTree(mvc.perform(post("/api/v1/properties/" + marios + "/units")
                        .header("Authorization", "Bearer " + mario.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","floor":"1","rentalMode":"WHOLE_UNIT",
                                 "capacity":1,"rent":6000.00}
                                """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();
        String second = json.readTree(letRoom(mario.token(), bea.token(),
                        "{\"unitId\":\"%s\"}".formatted(unit),
                        "{\"startDate\":\"%s\"}".formatted(today())))
                .get("id").asText();
        String month = json.readTree(mvc.perform(get("/api/v1/leases/" + second + "/billing")
                        .header("Authorization", "Bearer " + mario.token()))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();
        mvc.perform(post("/api/v1/leases/" + second + "/payments")
                        .header("Authorization", "Bearer " + mario.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"billingPeriodId\":\"%s\",\"amountPaid\":6000,\"paymentMethod\":\"CASH\"}"
                                .formatted(month)))
                .andExpect(status().isCreated());

        assertThat(receipts(bea, second).get(0).get("number").asText())
                .isEqualTo(year() + "-0001");
        assertThat(receipts(bea, second).get(0).get("place").asText()).isEqualTo("Unit 1A");
    }

    @Test
    void a_new_year_starts_again_at_one() throws Exception {
        String lease = let(null);
        String month = firstMonth(lease);
        confirm(lease, declare(lease, month, 1000));

        int next = year() + 1;
        clock.setTo(Instant.parse(next + "-01-02T02:00:00Z"));
        confirm(lease, declare(lease, month, 1000));

        assertThat(receipts(ana, lease).get(0).get("number").asText()).isEqualTo(next + "-0001");
    }

    /**
     * Payments confirmed before receipts existed get them too, numbered in
     * the order they were confirmed -- and the next one follows on.
     *
     * <p>Runs the migration's own backfill against payments whose receipts
     * have been taken away, which is the state every database was in.
     */
    @Test
    void payments_confirmed_before_receipts_get_them() throws Exception {
        String lease = let(null);
        String month = firstMonth(lease);
        confirm(lease, declare(lease, month, 1000));
        clock.advanceMinutes(5);
        record(lease, month, "500");
        jdbc.update("DELETE FROM receipts WHERE lease_id = ?::uuid", lease);
        jdbc.update("DELETE FROM receipt_counters WHERE landlord_id = ?", elena.id());

        String migration = new String(getClass()
                .getResourceAsStream("/db/migration/V46__receipts.sql").readAllBytes(),
                StandardCharsets.UTF_8);
        jdbc.execute(statement(migration, "WITH confirmed AS"));
        jdbc.execute(statement(migration, "INSERT INTO receipt_counters"));

        JsonNode back = receipts(ana, lease);
        assertThat(back).hasSize(2);
        assertThat(back.get(1).get("number").asText()).isEqualTo(year() + "-0001");
        assertThat(back.get(1).get("stillOwed").decimalValue()).isEqualByComparingTo("1500");
        assertThat(back.get(0).get("number").asText()).isEqualTo(year() + "-0002");
        assertThat(back.get(0).get("stillOwed").decimalValue()).isEqualByComparingTo("1000");
        assertThat(back.get(0).get("receivedFrom").asText()).isEqualTo("Ana");
        assertThat(back.get(0).get("place").asText()).isEqualTo("Bed 1, 2B");

        record(lease, month, "1000");
        assertThat(receipts(ana, lease).get(0).get("number").asText())
                .isEqualTo(year() + "-0003");
    }

    /** One statement of the migration, from where it starts to its semicolon. */
    private static String statement(String migration, String startingWith) {
        int start = migration.indexOf(startingWith);
        // Neither statement has a semicolon of its own inside it.
        return migration.substring(start, migration.indexOf(';', start));
    }

    // ---- who may read them -------------------------------------------------

    @Test
    void nobody_else_can_read_them() throws Exception {
        String lease = let(null);
        record(lease, firstMonth(lease), "2500");
        Accounts.Account stranger = accounts.tenant("Carla");
        Accounts.Account otherLandlord = accounts.landlord("Mario");

        mvc.perform(get("/api/v1/me/leases/" + lease + "/receipts")
                        .header("Authorization", "Bearer " + stranger.token()))
                .andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/leases/" + lease + "/receipts")
                        .header("Authorization", "Bearer " + otherLandlord.token()))
                .andExpect(status().isNotFound());
    }

    /**
     * Gone from the receipt as from the account. The receipt itself stays:
     * it is the landlord's record of money that changed hands too.
     */
    @Test
    void a_closed_account_is_no_longer_named_on_them() throws Exception {
        String lease = let(null);
        record(lease, firstMonth(lease), "2500");
        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\"}".formatted(today())))
                .andExpect(status().isOk());

        mvc.perform(delete("/api/v1/me").header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isNoContent());

        JsonNode receipt = receipts(elena, lease).get(0);
        assertThat(receipt.get("receivedFrom").asText()).isEqualTo("Deleted account");
        assertThat(receipt.get("amount").decimalValue()).isEqualByComparingTo("2500");
    }

    // ---- fixtures ----------------------------------------------------------

    private int year() {
        return LocalDate.now(clock.withZone(ZoneId.of("Asia/Manila"))).getYear();
    }

    private LocalDate today() {
        return LocalDate.now(clock);
    }

    private static String property(String name) {
        return """
                {"name":"%s","address":"12 Mabini St",
                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                """.formatted(name);
    }

    /** Bed 1 in 2B for Ana, from today. */
    private String let(String extra) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString();
        String lease = letRoom(
                elena.token(),
                ana.token(),
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(
                        unitId, json.readTree(beds).get(0).get("id").asText()),
                "{\"rentAmount\":2500.00,\"startDate\":\"%s\"%s}"
                        .formatted(today(), extra == null ? "" : "," + extra));
        return json.readTree(lease).get("id").asText();
    }

    private JsonNode months(String lease) throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString());
    }

    private String firstMonth(String lease) throws Exception {
        for (JsonNode month : months(lease)) {
            if (month.get("kind").asText().equals("RENT")) {
                return month.get("id").asText();
            }
        }
        throw new AssertionError("no rent month");
    }

    /** @return the payment id */
    private String declare(String lease, String month, int amount) throws Exception {
        String made = mvc.perform(multipart("/api/v1/me/leases/" + lease + "/payments")
                        .part(new MockPart("billingPeriodId", month.getBytes()))
                        .part(new MockPart("amountPaid", String.valueOf(amount).getBytes()))
                        .part(new MockPart("paymentMethod", "GCASH".getBytes()))
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(made).get("id").asText();
    }

    private ResultActions confirm(String lease, String payment) throws Exception {
        return mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + payment + "/confirm")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isOk());
    }

    private void record(String lease, String period, String amount) throws Exception {
        mvc.perform(post("/api/v1/leases/" + lease + "/payments")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"billingPeriodId":"%s","amountPaid":%s,"paymentMethod":"CASH"}
                                """.formatted(period, amount)))
                .andExpect(status().isCreated());
    }

    /** As the tenant sees them, or as the landlord does. */
    private JsonNode receipts(Accounts.Account who, String lease) throws Exception {
        String path = who == elena
                ? "/api/v1/leases/" + lease + "/receipts"
                : "/api/v1/me/leases/" + lease + "/receipts";
        return json.readTree(mvc.perform(get(path)
                        .header("Authorization", "Bearer " + who.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private java.util.List<String> messagesTo(Accounts.Account who) throws Exception {
        java.util.List<String> messages = new java.util.ArrayList<>();
        for (JsonNode one : json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + who.token()))
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8))) {
            messages.add(one.get("message").asText());
        }
        return messages;
    }

    private void makeReadyForALease(String token) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
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
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isCreated());
        }
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
