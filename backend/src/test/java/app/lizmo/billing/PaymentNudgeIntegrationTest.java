package app.lizmo.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import app.lizmo.support.TestJobAuthoriser;
import com.fasterxml.jackson.databind.JsonNode;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;

/**
 * Chasing a payment a tenant has declared and nobody has answered.
 *
 * <p>The landlord was told once, the moment the tenant tapped. Missed, the
 * month stayed unpaid on both sides -- and the tenant, who had paid, was told
 * every week that their rent was overdue.
 *
 * <p>Waits are counted from when the tenant told the app, by the same clock
 * the job reads -- so exactly three days later is three days.
 */
class PaymentNudgeIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private String landlordToken;
    private Accounts.Account ana;

    private String propertyId;
    private String unitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();

        landlordToken = accounts.landlord("elena").token();
        ana = accounts.tenant("ana");

        String property = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        propertyId = json.readTree(property).get("id").asText();

        String unit = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        unitId = json.readTree(unit).get("id").asText();

        makeReadyForALease(ana.token());
    }

    // ---- the tenant is not blamed ---------------------------------------------

    /** They paid and are waiting; being told weekly they are late was the bug. */
    @Test
    void a_month_declared_in_full_is_not_called_overdue() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 2500);

        later(3);
        run();

        assertThat(ofType(ana.token(), "RENT_OVERDUE")).isEmpty();
    }

    /** Part declared: only the rest is owed, and the rest of it is said. */
    @Test
    void a_part_declared_month_is_chased_for_the_rest_only() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 1000);

        later(3);
        run();

        List<JsonNode> overdue = ofType(ana.token(), "RENT_OVERDUE");
        assertThat(overdue).hasSize(1);
        assertThat(overdue.get(0).get("message").asText())
                .startsWith("P1500 for")
                .contains("P1000 more is waiting for your landlord to confirm");
    }

    // ---- the landlord is reminded ------------------------------------------------

    @Test
    void the_landlord_is_reminded_after_three_days_and_not_before() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 2500);

        clock.advanceDays(2);
        run();
        assertThat(ofType(landlordToken, "PAYMENT_AWAITING_CONFIRMATION")).isEmpty();

        later(1);
        run();
        assertThat(ofType(landlordToken, "PAYMENT_AWAITING_CONFIRMATION")).hasSize(1);
    }

    /** Cloud Scheduler retries a failed run; a retry must not say it again. */
    @Test
    void running_it_again_the_same_day_says_nothing_more() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 2500);
        later(3);

        run();
        run();
        run();

        assertThat(ofType(landlordToken, "PAYMENT_AWAITING_CONFIRMATION")).hasSize(1);
    }

    @Test
    void then_weekly_until_it_is_answered() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 2500);
        later(3);
        run();

        clock.advanceDays(6);
        run();
        assertThat(ofType(landlordToken, "PAYMENT_AWAITING_CONFIRMATION")).hasSize(1);

        later(1);
        run();
        assertThat(ofType(landlordToken, "PAYMENT_AWAITING_CONFIRMATION")).hasSize(2);
    }

    @Test
    void confirming_it_stops_the_reminders() throws Exception {
        String lease = let();
        String payment = declare(lease, firstMonth(lease), 2500);
        later(3);
        run();

        mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + payment + "/confirm")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        later(14);
        run();
        assertThat(ofType(landlordToken, "PAYMENT_AWAITING_CONFIRMATION")).hasSize(1);
        assertThat(ofType(ana.token(), "PAYMENT_STILL_UNCONFIRMED")).isEmpty();
    }

    /** "It did not arrive" is an answer too. */
    @Test
    void saying_it_did_not_arrive_stops_them_too() throws Exception {
        String lease = let();
        String payment = declare(lease, firstMonth(lease), 2500);
        later(3);
        run();

        mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + payment + "/reject")
                        .header("Authorization", "Bearer " + landlordToken)
                        .param("remarks", "Nothing arrived in my GCash."))
                .andExpect(status().isOk());

        later(14);
        run();
        assertThat(ofType(landlordToken, "PAYMENT_AWAITING_CONFIRMATION")).hasSize(1);
    }

    /** Read on a lock screen: the room, not the person. */
    @Test
    void the_landlord_reminder_names_the_room_not_the_tenant() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 2500);
        later(3);
        run();

        String message = ofType(landlordToken, "PAYMENT_AWAITING_CONFIRMATION")
                .get(0).get("message").asText();
        assertThat(message)
                .contains("Bed 1, 2B")
                .contains("Sunrise Apartments")
                .contains("P2500")
                .contains("3 days ago")
                .doesNotContain(ana.name());
    }

    // ---- the tenant is told it is worth asking -----------------------------------

    @Test
    void after_a_week_the_tenant_is_pointed_at_their_conversation() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 2500);

        later(7);
        run();

        List<JsonNode> told = ofType(ana.token(), "PAYMENT_STILL_UNCONFIRMED");
        assertThat(told).hasSize(1);
        assertThat(told.get(0).get("relatedEntityType").asText()).isEqualTo("INQUIRY");
        assertThat(told.get(0).get("relatedEntityId").asText()).isEqualTo(threadOf(ana.token()));
        assertThat(told.get(0).get("message").asText()).contains("worth asking");
    }

    @Test
    void the_tenant_is_told_once() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 2500);
        later(7);
        run();

        later(14);
        run();

        assertThat(ofType(ana.token(), "PAYMENT_STILL_UNCONFIRMED")).hasSize(1);
    }

    /** Once per payment, not once ever: a later one that waits is told again. */
    @Test
    void a_later_payment_that_waits_is_told_again() throws Exception {
        String lease = let();
        String first = declare(lease, firstMonth(lease), 2500);
        later(7);
        run();
        mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + first + "/confirm")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        // The next month, written by the job, declared, and left.
        clock.advanceDays(30);
        run();
        declare(lease, unpaidMonth(lease), 2500);
        later(7);
        run();

        assertThat(ofType(ana.token(), "PAYMENT_STILL_UNCONFIRMED")).hasSize(2);
    }

    // ---- how long, on what the app reads ------------------------------------------

    @Test
    void both_sides_can_see_how_long_it_has_waited() throws Exception {
        String lease = let();
        declare(lease, firstMonth(lease), 2500);

        JsonNode collections = json.readTree(mvc.perform(get("/api/v1/me/collections")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString());
        assertThat(collections.get("awaiting").get(0).get("declaredAt").asText()).isNotBlank();

        JsonNode mine = json.readTree(mvc.perform(get("/api/v1/me/leases/" + lease + "/payments")
                        .header("Authorization", "Bearer " + ana.token()))
                .andReturn().getResponse().getContentAsString());
        assertThat(mine.get(0).get("declaredAt").asText()).isNotBlank();
    }

    // ---- fixtures -------------------------------------------------------------------

    private void later(int days) {
        clock.advanceDays(days);
    }

    private void run() throws Exception {
        mvc.perform(post("/internal/jobs/rent-reminders")
                        .header("Authorization", "Bearer " + TestJobAuthoriser.PASSWORD))
                .andExpect(status().isOk());
    }

    /** Bed 1 in 2B, from today, so the first month falls due today. */
    private String let() throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bed = json.readTree(beds).get(0).get("id").asText();

        String lease = letRoom(
                landlordToken,
                ana.token(),
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bed),
                "{\"rentAmount\":2500.00,\"startDate\":\"%s\"}".formatted(LocalDate.now(clock)));
        return json.readTree(lease).get("id").asText();
    }

    private JsonNode months(String lease) throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString());
    }

    private String firstMonth(String lease) throws Exception {
        return months(lease).get(0).get("id").asText();
    }

    private String unpaidMonth(String lease) throws Exception {
        for (JsonNode month : months(lease)) {
            if (!month.get("status").asText().equals("PAID")) {
                return month.get("id").asText();
            }
        }
        throw new AssertionError("every month is paid");
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

    private List<JsonNode> ofType(String token, String type) throws Exception {
        JsonNode all = json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + token))
                .andReturn().getResponse().getContentAsString());
        List<JsonNode> found = new ArrayList<>();
        for (JsonNode one : all) {
            if (one.get("type").asText().equals(type)) {
                found.add(one);
            }
        }
        return found;
    }

    private String threadOf(String token) throws Exception {
        JsonNode threads = json.readTree(mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + token))
                .andReturn().getResponse().getContentAsString());
        for (JsonNode thread : threads) {
            if (thread.get("propertyId").asText().equals(propertyId)) {
                return thread.get("id").asText();
            }
        }
        throw new AssertionError("no conversation about the property");
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
        BufferedImage image = new BufferedImage(8, 8, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
