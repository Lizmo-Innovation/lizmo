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
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Recording rent that has been paid.
 *
 * <p>Lizmo does not move the money — this is the agreed note of it afterwards.
 * Which means the tests that matter are about disagreement: who may write a
 * payment down, whose word makes it count, and the several ways confirming
 * could quietly credit a month twice.
 */
class PaymentIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private String landlordToken;
    private String otherLandlordToken;
    private String anaToken;
    private String beaToken;

    private String unitId;
    private String bedId;
    private String leaseId;
    private String october;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();

        landlordToken = accounts.landlord("elena").token();
        otherLandlordToken = accounts.landlord("mario").token();
        anaToken = accounts.tenant("ana").token();
        beaToken = accounts.tenant("bea").token();

        String property = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String unit = mvc.perform(post("/api/v1/properties/"
                        + json.readTree(property).get("id").asText() + "/units")
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
        leaseId = let();
        october = firstPeriod();
    }

    // ---- the landlord writing it down --------------------------------------

    @Test
    void a_landlord_recording_money_moves_the_balance_at_once() throws Exception {
        record(2500, "GCASH")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.periodLabel").isNotEmpty());

        billing()
                .andExpect(jsonPath("$[0].amountPaid").value(2500.00))
                .andExpect(jsonPath("$[0].outstanding").value(0))
                .andExpect(jsonPath("$[0].status").value("PAID"));
    }

    /** People pay half now and half on payday. */
    @Test
    void two_part_payments_add_up() throws Exception {
        record(1000, "CASH").andExpect(status().isCreated());
        billing().andExpect(jsonPath("$[0].status").value("PARTIALLY_PAID"));

        record(1500, "GCASH").andExpect(status().isCreated());
        billing()
                .andExpect(jsonPath("$[0].amountPaid").value(2500.00))
                .andExpect(jsonPath("$[0].status").value("PAID"));
    }

    @Test
    void a_payment_of_nothing_is_refused() throws Exception {
        record(0, "CASH").andExpect(status().isBadRequest());
    }

    @Test
    void the_tenant_is_told_their_landlord_recorded_it() throws Exception {
        record(2500, "CASH").andExpect(status().isCreated());

        // That the tenant was told, not that it is the newest thing in their
        // bell: notifications raised in one moment share a timestamp, so
        // "first" is not a stable way to ask.
        assertThat(typesFor(anaToken)).contains("PAYMENT_CONFIRMED");
    }

    // ---- the tenant claiming it --------------------------------------------

    @Test
    void a_tenant_declaring_a_payment_waits() throws Exception {
        declare(2500, null)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING_VERIFICATION"));

        // Nothing has moved. Only somebody who would know can say it arrived.
        billing()
                .andExpect(jsonPath("$[0].amountPaid").value(0))
                .andExpect(jsonPath("$[0].status").value("UNPAID"));
    }

    @Test
    void confirming_is_what_moves_it() throws Exception {
        String payment = idOf(declare(2500, null));

        mvc.perform(post("/api/v1/leases/" + leaseId + "/payments/" + payment + "/confirm")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CONFIRMED"));

        billing().andExpect(jsonPath("$[0].status").value("PAID"));
    }

    /**
     * The one way this feature could quietly invent money: crediting a month
     * twice for the same payment.
     */
    @Test
    void confirming_twice_is_refused() throws Exception {
        String payment = idOf(declare(2500, null));

        confirm(payment).andExpect(status().isOk());
        confirm(payment)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("already been answered")));

        billing().andExpect(jsonPath("$[0].amountPaid").value(2500.00));
    }

    @Test
    void a_rejected_payment_cannot_then_be_confirmed() throws Exception {
        String payment = idOf(declare(2500, null));

        mvc.perform(post("/api/v1/leases/" + leaseId + "/payments/" + payment + "/reject")
                        .header("Authorization", "Bearer " + landlordToken)
                        .param("remarks", "Nothing arrived in my GCash."))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"));

        confirm(payment).andExpect(status().isBadRequest());
        billing().andExpect(jsonPath("$[0].amountPaid").value(0));
    }

    /**
     * Rejected, not deleted. A tenant who wrote something down and found it
     * gone would not know whether it was refused or lost.
     */
    @Test
    void a_rejected_payment_stays_in_the_list_with_its_reason() throws Exception {
        String payment = idOf(declare(2500, null));
        reject(payment, "Nothing arrived in my GCash.").andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/leases/" + leaseId + "/payments")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].status").value("REJECTED"))
                .andExpect(jsonPath("$[0].remarks").value("Nothing arrived in my GCash."));
    }

    @Test
    void the_tenant_is_told_why_it_was_refused() throws Exception {
        String payment = idOf(declare(2500, null));
        reject(payment, "Nothing arrived in my GCash.").andExpect(status().isOk());

        assertThat(typesFor(anaToken)).contains("PAYMENT_REJECTED");
        assertThat(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + anaToken))
                .andReturn().getResponse().getContentAsString())
                .contains("Nothing arrived in my GCash.");
    }

    @Test
    void the_landlord_is_told_somebody_claims_to_have_paid() throws Exception {
        declare(2500, null).andExpect(status().isCreated());

        assertThat(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString())
                .contains("waiting for you to confirm");
    }

    /**
     * A payment cannot be opened on its own. The landlord told a tenant has
     * paid is led to the tenancy, which is where Confirm is.
     */
    @Test
    void that_notification_leads_to_the_tenancy() throws Exception {
        declare(2500, null).andExpect(status().isCreated());

        var feed = json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString());

        var claim = java.util.stream.StreamSupport.stream(feed.spliterator(), false)
                .filter(row -> "PAYMENT".equals(row.path("relatedEntityType").asText()))
                .findFirst()
                .orElseThrow();
        assertThat(claim.get("leaseId").asText()).isEqualTo(leaseId);
    }

    // ---- proof -------------------------------------------------------------

    @Test
    void a_screenshot_can_be_attached_and_comes_back_as_a_link() throws Exception {
        declare(2500, photo())
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.proofUrl").isNotEmpty());
    }

    /** Cash is real, and a required field nobody can satisfy becomes one people lie in. */
    @Test
    void proof_is_optional() throws Exception {
        declare(2500, null)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.proofUrl").doesNotExist());
    }

    // ---- who may do what ---------------------------------------------------

    @Test
    void another_landlord_can_record_nothing() throws Exception {
        mvc.perform(post("/api/v1/leases/" + leaseId + "/payments")
                        .header("Authorization", "Bearer " + otherLandlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(2500, "CASH")))
                .andExpect(status().isNotFound());
    }

    @Test
    void another_tenant_can_declare_nothing() throws Exception {
        mvc.perform(multipart("/api/v1/me/leases/" + leaseId + "/payments")
                        .file(new MockMultipartFile("payment", "", "application/json",
                                body(2500, "GCASH").getBytes()))
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_confirm_their_own_payment() throws Exception {
        String payment = idOf(declare(2500, null));

        mvc.perform(post("/api/v1/leases/" + leaseId + "/payments/" + payment + "/confirm")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isNotFound());

        billing().andExpect(jsonPath("$[0].amountPaid").value(0));
    }

    /**
     * A month id from one tenancy paid against another the caller happens to
     * own. Both halves of the check matter.
     */
    @Test
    void a_month_from_another_tenancy_cannot_be_paid() throws Exception {
        makeReadyForALease(beaToken);
        String otherLease = letBed(beaToken, 1);
        String otherMonth = json.readTree(mvc.perform(
                        get("/api/v1/leases/" + otherLease + "/billing")
                                .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();

        mvc.perform(post("/api/v1/leases/" + leaseId + "/payments")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"billingPeriodId":"%s","amountPaid":2500.00,
                                 "paymentMethod":"CASH"}
                                """.formatted(otherMonth)))
                .andExpect(status().isNotFound());
    }

    /** Every notification type in somebody's bell, order-independent. */
    private java.util.List<String> typesFor(String token) throws Exception {
        var all = json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + token))
                .andReturn().getResponse().getContentAsString());
        java.util.List<String> types = new java.util.ArrayList<>();
        all.forEach(one -> types.add(one.get("type").asText()));
        return types;
    }

    // ---- fixtures ----------------------------------------------------------

    private ResultActions billing() throws Exception {
        return mvc.perform(get("/api/v1/leases/" + leaseId + "/billing")
                .header("Authorization", "Bearer " + landlordToken));
    }

    private String firstPeriod() throws Exception {
        return json.readTree(billing().andReturn().getResponse().getContentAsString())
                .get(0).get("id").asText();
    }

    private String body(int amount, String method) {
        return """
                {"billingPeriodId":"%s","amountPaid":%d.00,"paymentMethod":"%s"}
                """.formatted(october, amount, method);
    }

    private ResultActions record(int amount, String method) throws Exception {
        return mvc.perform(post("/api/v1/leases/" + leaseId + "/payments")
                .header("Authorization", "Bearer " + landlordToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(amount, method)));
    }

    private ResultActions declare(int amount, byte[] proof) throws Exception {
        // Files first, header last: .header() narrows the builder type and
        // .file() is no longer available after it.
        var call = multipart("/api/v1/me/leases/" + leaseId + "/payments")
                .file(new MockMultipartFile("payment", "", "application/json",
                        body(amount, "GCASH").getBytes()));
        if (proof != null) {
            call = call.file(new MockMultipartFile("proof", "p.jpg", "image/jpeg", proof));
        }
        return mvc.perform(call.header("Authorization", "Bearer " + anaToken));
    }

    private ResultActions confirm(String paymentId) throws Exception {
        return mvc.perform(post("/api/v1/leases/" + leaseId + "/payments/"
                + paymentId + "/confirm")
                .header("Authorization", "Bearer " + landlordToken));
    }

    private ResultActions reject(String paymentId, String why) throws Exception {
        return mvc.perform(post("/api/v1/leases/" + leaseId + "/payments/"
                + paymentId + "/reject")
                .header("Authorization", "Bearer " + landlordToken)
                .param("remarks", why));
    }

    private String idOf(ResultActions actions) throws Exception {
        return json.readTree(actions.andReturn().getResponse().getContentAsString())
                .get("id").asText();
    }

    private String let() throws Exception {
        return letBed(anaToken, 0);
    }

    private String letBed(String tenantToken, int index) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bed = json.readTree(beds).get(index).get("id").asText();

        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bed)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String lease = mvc.perform(post("/api/v1/rental-requests/"
                        + json.readTree(request).get("id").asText() + "/accept")
                        .header("Authorization", "Bearer " + landlordToken)
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
        BufferedImage image = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
