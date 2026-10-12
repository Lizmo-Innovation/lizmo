package app.lizmo.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import app.lizmo.support.TestJobAuthoriser;
import com.fasterxml.jackson.databind.JsonNode;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;
import org.springframework.test.web.servlet.ResultActions;

/**
 * The deposit and the advance, owed at move-in and confirmed like rent.
 *
 * <p>Until now both were figures on the lease, assumed taken: the advance was
 * recorded as paid the moment the lease was written, and the deposit was
 * never owed, paid or confirmed at all. A tenant who had handed over nothing
 * looked exactly like one who had handed over everything.
 */
class MoveInChargesIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    @Autowired
    private PaymentRepository payments;

    private String landlordToken;
    private String anaToken;

    private String propertyId;
    private String unitId;
    private String bedId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();

        landlordToken = accounts.landlord("elena").token();
        anaToken = accounts.tenant("ana").token();

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

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        bedId = json.readTree(beds).get(0).get("id").asText();

        makeReadyForALease(anaToken);
    }

    // ---- the deposit ------------------------------------------------------------

    @Test
    void a_deposit_is_owed_at_move_in() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");

        JsonNode deposit = deposit(lease);
        assertThat(deposit.get("label").asText()).isEqualTo("Security deposit");
        assertThat(deposit.get("amountDue").decimalValue()).isEqualByComparingTo("5000");
        assertThat(deposit.get("amountPaid").decimalValue()).isEqualByComparingTo("0");
        assertThat(deposit.get("status").asText()).isEqualTo("UNPAID");
        assertThat(deposit.get("dueDate").asText()).isEqualTo(today().toString());
    }

    /** Both start on move-in day; the order shown is not left to the database. */
    @Test
    void the_deposit_comes_before_the_first_month() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");

        billing(lease)
                .andExpect(jsonPath("$[0].kind").value("DEPOSIT"))
                .andExpect(jsonPath("$[1].kind").value("RENT"));
    }

    @Test
    void a_deposit_is_written_once_however_often_it_is_read() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");

        billing(lease);
        billing(lease);
        clock.advanceDays(40);

        assertThat(ofKind(lease, "DEPOSIT")).hasSize(1);
    }

    @Test
    void no_deposit_no_charge() throws Exception {
        String lease = let(today(), null);

        assertThat(ofKind(lease, "DEPOSIT")).isEmpty();
    }

    /** Like the months: owed from move-in day, not from signing. */
    @Test
    void a_tenancy_not_started_owes_no_deposit_yet() throws Exception {
        String lease = let(today().plusDays(10), "\"depositAmount\":5000.00");

        assertThat(ofKind(lease, "DEPOSIT")).isEmpty();
    }

    /** "P2000 of P5000 received" is common, and the flow already takes parts. */
    @Test
    void a_deposit_can_be_paid_in_parts() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");
        record(lease, deposit(lease).get("id").asText(), "2000.00");

        JsonNode deposit = deposit(lease);
        assertThat(deposit.get("status").asText()).isEqualTo("PARTIALLY_PAID");
        assertThat(deposit.get("outstanding").decimalValue()).isEqualByComparingTo("3000");
    }

    /** The tenant says they paid it, and it counts once the landlord agrees. */
    @Test
    void a_tenant_declares_their_deposit_and_the_landlord_confirms_it() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");
        String payment = declare(lease, deposit(lease).get("id").asText(), 5000);

        assertThat(deposit(lease).get("status").asText()).isEqualTo("UNPAID");

        mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + payment + "/confirm")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        assertThat(deposit(lease).get("status").asText()).isEqualTo("PAID");
    }

    // ---- the advance ------------------------------------------------------------

    /** Owed like any month: nothing is paid until the landlord confirms it was. */
    @Test
    void an_advance_is_owed_at_move_in_not_assumed() throws Exception {
        String lease = let(today(), "\"advanceAmount\":2500.00");

        JsonNode first = ofKind(lease, "RENT").get(0);
        assertThat(first.get("label").asText()).endsWith(" · advance");
        assertThat(first.get("dueDate").asText()).isEqualTo(today().toString());
        assertThat(first.get("status").asText()).isEqualTo("UNPAID");
        assertThat(payments.findByLeaseIdOrderByPaymentDateDesc(UUID.fromString(lease)))
                .isEmpty();
    }

    /** "2 months advance" is the first two months, both owed on move-in day. */
    @Test
    void two_months_advance_are_both_owed_at_move_in() throws Exception {
        String lease = let(today(), "\"advanceAmount\":5000.00");

        List<JsonNode> months = ofKind(lease, "RENT");
        assertThat(months).hasSize(2);
        for (JsonNode month : months) {
            assertThat(month.get("label").asText()).endsWith(" · advance");
            assertThat(month.get("dueDate").asText()).isEqualTo(today().toString());
        }
    }

    /** P3000 on P2500 would pay one month and leave P500 recorded nowhere. */
    @Test
    void an_advance_that_is_not_whole_months_is_refused() throws Exception {
        String thread = askAbout(anaToken, propertyId);

        mvc.perform(post("/api/v1/inquiries/" + thread + "/lease")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitId":"%s","bedId":"%s","rentAmount":2500.00,
                                 "startDate":"%s","advanceAmount":3000.00}
                                """.formatted(unitId, bedId, today())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        "An advance pays for whole months of rent: P2500 or P5000, not P3000."));
    }

    @Test
    void the_advance_month_is_paid_when_the_landlord_confirms_it() throws Exception {
        String lease = let(today(), "\"advanceAmount\":2500.00");
        record(lease, ofKind(lease, "RENT").get(0).get("id").asText(), "2500.00");

        assertThat(ofKind(lease, "RENT").get(0).get("status").asText()).isEqualTo("PAID");
    }

    @Test
    void the_month_after_the_advance_falls_due_as_usual() throws Exception {
        String lease = let(today(), "\"advanceAmount\":2500.00");
        billing(lease);

        clock.advanceDays(32);

        JsonNode second = ofKind(lease, "RENT").get(1);
        assertThat(second.get("label").asText()).doesNotContain("advance");
        assertThat(second.get("dueDate").asText()).isNotEqualTo(today().toString());
    }

    // ---- held, not earned ----------------------------------------------------------

    @Test
    void a_deposit_is_held_not_collected() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");
        record(lease, deposit(lease).get("id").asText(), "5000.00");

        collections()
                .andExpect(jsonPath("$.depositsHeld").value(5000.00))
                .andExpect(jsonPath("$.dueThisMonth").value(2500.00))
                .andExpect(jsonPath("$.collectedThisMonth").value(0));
    }

    /** Something to chase -- said apart from the rent, which here is paid. */
    @Test
    void a_deposit_not_received_lists_the_tenant() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");
        record(lease, ofKind(lease, "RENT").get(0).get("id").asText(), "2500.00");

        clock.advanceDays(1);

        collections()
                .andExpect(jsonPath("$.inArrears.length()").value(1))
                .andExpect(jsonPath("$.inArrears[0].depositOwed").value(5000.00))
                .andExpect(jsonPath("$.inArrears[0].monthsLate").value(0));
    }

    @Test
    void the_rent_roll_is_rent() throws Exception {
        let(today(), "\"depositAmount\":5000.00");

        mvc.perform(get("/api/v1/me/rent-roll?month=" + YearMonth.now(clock))
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.rows.length()").value(1))
                .andExpect(jsonPath("$.due").value(2500.00));
    }

    // ---- reminders --------------------------------------------------------------

    @Test
    void an_overdue_deposit_is_called_a_deposit() throws Exception {
        let(today(), "\"depositAmount\":5000.00");
        clock.advanceDays(3);

        mvc.perform(post("/internal/jobs/rent-reminders")
                        .header("Authorization", "Bearer " + TestJobAuthoriser.PASSWORD))
                .andExpect(status().isOk());

        String feed = mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + anaToken))
                .andReturn().getResponse().getContentAsString();
        assertThat(feed)
                .contains("Your security deposit is overdue")
                .contains("P5000 for the security deposit");
    }

    // ---- moving out ---------------------------------------------------------------

    /** A tenant who handed over P2000 of P5000 cannot be given P5000 back. */
    @Test
    void a_refund_is_capped_at_what_came_in() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");
        record(lease, deposit(lease).get("id").asText(), "2000.00");

        end(lease, "3000.00")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        Matchers.containsString("You received P2000 of the deposit")));

        end(lease, "2000.00").andExpect(status().isOk());
    }

    /** Ended before anybody opened its billing: nothing was received. */
    @Test
    void nothing_received_means_nothing_to_return() throws Exception {
        String lease = let(today(), "\"depositAmount\":5000.00");

        end(lease, "1000.00")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        Matchers.containsString("You received P0 of the deposit")));
    }

    // ---- fixtures -------------------------------------------------------------------

    private LocalDate today() {
        return LocalDate.now(clock);
    }

    /** @return the lease id */
    private String let(LocalDate start, String extraTerms) throws Exception {
        String lease = letRoom(
                landlordToken,
                anaToken,
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bedId),
                "{\"rentAmount\":2500.00,\"startDate\":\"%s\"%s}"
                        .formatted(start, extraTerms == null ? "" : "," + extraTerms));
        return json.readTree(lease).get("id").asText();
    }

    private ResultActions billing(String lease) throws Exception {
        return mvc.perform(get("/api/v1/leases/" + lease + "/billing")
                .header("Authorization", "Bearer " + landlordToken));
    }

    private List<JsonNode> ofKind(String lease, String kind) throws Exception {
        List<JsonNode> found = new ArrayList<>();
        // As UTF-8: without a declared charset the response is read as
        // ISO-8859-1, which mangles the middle dot in "October 2026 · advance".
        for (JsonNode period : json.readTree(billing(lease).andReturn().getResponse()
                .getContentAsString(java.nio.charset.StandardCharsets.UTF_8))) {
            if (period.get("kind").asText().equals(kind)) {
                found.add(period);
            }
        }
        return found;
    }

    private JsonNode deposit(String lease) throws Exception {
        List<JsonNode> deposits = ofKind(lease, "DEPOSIT");
        assertThat(deposits).hasSize(1);
        return deposits.get(0);
    }

    /** The landlord recording money handed to them: confirmed on the spot. */
    private void record(String lease, String period, String amount) throws Exception {
        mvc.perform(post("/api/v1/leases/" + lease + "/payments")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"billingPeriodId":"%s","amountPaid":%s,"paymentMethod":"CASH"}
                                """.formatted(period, amount)))
                .andExpect(status().isCreated());
    }

    /** @return the payment id */
    private String declare(String lease, String period, int amount) throws Exception {
        String made = mvc.perform(multipart("/api/v1/me/leases/" + lease + "/payments")
                        .part(new MockPart("billingPeriodId", period.getBytes()))
                        .part(new MockPart("amountPaid", String.valueOf(amount).getBytes()))
                        .part(new MockPart("paymentMethod", "GCASH".getBytes()))
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(made).get("id").asText();
    }

    private ResultActions collections() throws Exception {
        return mvc.perform(get("/api/v1/me/collections")
                .header("Authorization", "Bearer " + landlordToken));
    }

    private ResultActions end(String lease, String returned) throws Exception {
        return mvc.perform(post("/api/v1/leases/" + lease + "/end")
                .header("Authorization", "Bearer " + landlordToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"endDate\":\"%s\",\"depositReturned\":%s}"
                        .formatted(today(), returned)));
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
