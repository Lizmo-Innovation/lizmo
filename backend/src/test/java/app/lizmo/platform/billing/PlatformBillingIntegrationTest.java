package app.lizmo.platform.billing;

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
import app.lizmo.support.TestJobAuthoriser;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.ChronoUnit;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder;

/**
 * Lizmo billing landlords, and being paid.
 *
 * <p>Every test that runs the snapshot bills every property in the shared
 * database, not only this class's. So nothing here counts invoices globally:
 * each assertion is about Elena's own properties, read back through her own
 * endpoint, or about one payment by id.
 */
class PlatformBillingIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private Accounts.Account elena;
    private String landlordToken;
    private String otherLandlordToken;
    private String adminToken;
    private String anaToken;
    private String beaToken;

    private String propertyId;
    private String bedUnitId;
    private String wholeUnitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();

        elena = accounts.landlord("elena");
        landlordToken = elena.token();
        otherLandlordToken = accounts.landlord("mario").token();
        adminToken = accounts.admin("staff").token();
        anaToken = accounts.tenant("ana").token();
        beaToken = accounts.tenant("bea").token();

        propertyId = createProperty("Sunrise Apartments");
        bedUnitId = createUnit(propertyId, """
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE","capacity":3,"rent":2500.00}
                """);
        wholeUnitId = createUnit(propertyId, """
                {"unitNumber":"1A","floor":"1","rentalMode":"WHOLE_UNIT","capacity":1,"rent":7000.00}
                """);

        makeReadyForALease(anaToken);
        makeReadyForALease(beaToken);
    }

    // ---- the snapshot -----------------------------------------------------------------

    /** P50 a let bed, P150 a let whole unit, and nothing for what is empty. */
    @Test
    void a_property_is_billed_for_what_it_has_let() throws Exception {
        letBed(anaToken, 0);
        letWholeUnit(beaToken);

        snapshot();

        mine()
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].propertyName").value("Sunrise Apartments"))
                .andExpect(jsonPath("$[0].occupiedBeds").value(1))
                .andExpect(jsonPath("$[0].occupiedUnits").value(1))
                .andExpect(jsonPath("$[0].unitRate").value(150.00))
                .andExpect(jsonPath("$[0].bedRate").value(50.00))
                .andExpect(jsonPath("$[0].amountDue").value(200.00))
                .andExpect(jsonPath("$[0].status").value("UNPAID"))
                .andExpect(jsonPath("$[0].billingDate").value(firstOfMonth().toString()))
                .andExpect(jsonPath("$[0].dueDate").value(firstOfMonth().toString()));
    }

    /** Vacant inventory costs nothing, and an invoice for nothing is noise. */
    @Test
    void a_property_with_nothing_let_gets_no_invoice() throws Exception {
        createProperty("Empty House");
        letBed(anaToken, 0);

        snapshot();

        mine()
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].propertyName").value("Sunrise Apartments"));
    }

    @Test
    void running_it_twice_bills_once() throws Exception {
        letBed(anaToken, 0);

        snapshot();
        snapshot();

        mine().andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void the_landlord_is_told_an_invoice_arrived() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        assertThat(notificationsAbout(landlordToken, invoiceId(), "PLATFORM_INVOICE_ISSUED"))
                .isEqualTo(1);
    }

    // ---- enforcement --------------------------------------------------------------------

    @Test
    void an_overdue_invoice_is_warned_about_once() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        clock.advanceDays(1);

        enforce();
        enforce();

        assertThat(notificationsAbout(landlordToken, invoiceId(), "PLATFORM_INVOICE_OVERDUE"))
                .isEqualTo(1);
        mine().andExpect(jsonPath("$[0].overdue").value(true));
    }

    /** Ariel's thirty days, not the spec's seven. */
    @Test
    void the_property_locks_thirty_days_after_the_due_date_and_not_before() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        long days = ChronoUnit.DAYS.between(LocalDate.now(clock), firstOfMonth().plusDays(30));
        if (days > 0) {
            clock.advanceDays(days - 1);
            enforce();
            propertyStatus().andExpect(jsonPath("$.properties[0].accountStatus").value("ACTIVE"));
            clock.advanceDays(1);
        }

        enforce();

        propertyStatus().andExpect(jsonPath("$.properties[0].accountStatus").value("LOCKED"));
        mine()
                .andExpect(jsonPath("$[0].lockedByThis").value(true))
                .andExpect(jsonPath("$[0].locksOn").isEmpty());
        assertThat(notificationsAbout(landlordToken, invoiceId(), "PLATFORM_PROPERTY_LOCKED"))
                .isEqualTo(1);
    }

    // ---- paying -------------------------------------------------------------------------

    @Test
    void a_landlord_pays_with_proof_and_it_waits_for_an_admin() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        pay(landlordToken, invoiceId(), 50, true)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.payments.length()").value(1))
                .andExpect(jsonPath("$.payments[0].status").value("PENDING_VERIFICATION"))
                .andExpect(jsonPath("$.payments[0].proofUrl").isNotEmpty())
                // A claim is not money until somebody at Lizmo agrees.
                .andExpect(jsonPath("$.amountPaid").value(0))
                .andExpect(jsonPath("$.status").value("UNPAID"));
    }

    @Test
    void paying_lizmo_needs_proof() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        pay(landlordToken, invoiceId(), 50, false).andExpect(status().isBadRequest());
    }

    @Test
    void another_landlord_can_neither_see_nor_pay_it() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String invoice = invoiceId();

        mvc.perform(get("/api/v1/me/platform-invoices")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(jsonPath("$.length()").value(0));
        pay(otherLandlordToken, invoice, 50, true).andExpect(status().isNotFound());
    }

    // ---- an admin checking it -------------------------------------------------------------

    @Test
    void confirming_pays_the_invoice_and_tells_the_landlord() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String invoice = invoiceId();
        String payment = paymentId(pay(landlordToken, invoice, 50, true));

        admin(payment, "confirm", null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.landlordName").value("elena"))
                .andExpect(jsonPath("$.propertyName").value("Sunrise Apartments"));

        mine()
                .andExpect(jsonPath("$[0].status").value("PAID"))
                .andExpect(jsonPath("$[0].amountPaid").value(50.00))
                .andExpect(jsonPath("$[0].outstanding").value(0));
        assertThat(notificationsAbout(landlordToken, invoice, "PLATFORM_PAYMENT_CONFIRMED"))
                .isEqualTo(1);
    }

    @Test
    void the_queue_shows_what_is_waiting_and_not_what_was_answered() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String payment = paymentId(pay(landlordToken, invoiceId(), 50, true));

        assertThat(queueHas(payment)).isTrue();
        admin(payment, "confirm", null).andExpect(status().isOk());
        assertThat(queueHas(payment)).isFalse();
    }

    @Test
    void a_payment_is_answered_once() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String payment = paymentId(pay(landlordToken, invoiceId(), 50, true));

        admin(payment, "confirm", null).andExpect(status().isOk());
        admin(payment, "confirm", null).andExpect(status().isBadRequest());
        admin(payment, "reject", "Too late.").andExpect(status().isBadRequest());
    }

    @Test
    void part_of_it_leaves_the_rest_owed() throws Exception {
        letBed(anaToken, 0);
        letBed(beaToken, 1);
        snapshot();
        String payment = paymentId(pay(landlordToken, invoiceId(), 40, true));

        admin(payment, "confirm", null).andExpect(status().isOk());

        mine()
                .andExpect(jsonPath("$[0].status").value("PARTIALLY_PAID"))
                .andExpect(jsonPath("$[0].outstanding").value(60.00));
    }

    @Test
    void refusing_one_tells_the_landlord_why_and_moves_nothing() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String invoice = invoiceId();
        String payment = paymentId(pay(landlordToken, invoice, 50, true));

        admin(payment, "reject", "Nothing arrived under that reference.")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"));

        mine()
                .andExpect(jsonPath("$[0].status").value("UNPAID"))
                .andExpect(jsonPath("$[0].payments[0].remarks")
                        .value("Nothing arrived under that reference."));
        String feed = mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        assertThat(feed).contains("Nothing arrived under that reference.");
    }

    // ---- the lock lifting ---------------------------------------------------------------------

    @Test
    void paying_in_full_lifts_the_lock_the_invoice_caused() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        clock.advanceDays(45);
        enforce();
        propertyStatus().andExpect(jsonPath("$.properties[0].accountStatus").value("LOCKED"));

        String payment = paymentId(pay(landlordToken, invoiceId(), 50, true));
        admin(payment, "confirm", null).andExpect(status().isOk());

        propertyStatus().andExpect(jsonPath("$.properties[0].accountStatus").value("ACTIVE"));
    }

    @Test
    void paying_part_of_it_leaves_the_property_locked() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        clock.advanceDays(45);
        enforce();

        String payment = paymentId(pay(landlordToken, invoiceId(), 20, true));
        admin(payment, "confirm", null).andExpect(status().isOk());

        propertyStatus().andExpect(jsonPath("$.properties[0].accountStatus").value("LOCKED"));
    }

    /** A lock placed by hand is an admin's decision, and paying an invoice does not undo it. */
    @Test
    void a_lock_an_admin_placed_is_not_lifted_by_paying() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        mvc.perform(post("/api/v1/admin/properties/" + propertyId + "/lock")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
        clock.advanceDays(45);
        enforce();

        String payment = paymentId(pay(landlordToken, invoiceId(), 50, true));
        admin(payment, "confirm", null).andExpect(status().isOk());

        propertyStatus().andExpect(jsonPath("$.properties[0].accountStatus").value("LOCKED"));
    }

    // ---- who may do what --------------------------------------------------------------------

    @Test
    void only_lizmos_admins_see_the_queue() throws Exception {
        mvc.perform(get("/api/v1/admin/platform-payments")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void only_the_scheduler_runs_the_jobs() throws Exception {
        mvc.perform(post("/internal/jobs/platform-billing-snapshot"))
                .andExpect(status().isNotFound());
        mvc.perform(post("/internal/jobs/platform-billing-enforcement")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void the_admin_sees_a_landlords_invoices() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        mvc.perform(get("/api/v1/admin/landlords/" + elena.id() + "/invoices")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].amountDue").value(50.00));
    }

    @Test
    void a_landlord_reads_the_payment_details_an_admin_wrote() throws Exception {
        mvc.perform(put("/api/v1/admin/settings")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"supportEmail":"help@lizmo.app",
                                 "paymentInstructions":"GCash 0917 123 4567 (Lizmo)"}
                                """))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/me/platform-payment-instructions")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.instructions").value("GCash 0917 123 4567 (Lizmo)"));
    }

    // ---- fixtures -----------------------------------------------------------------------------

    private LocalDate firstOfMonth() {
        return YearMonth.now(clock).atDay(1);
    }

    private void snapshot() throws Exception {
        mvc.perform(post("/internal/jobs/platform-billing-snapshot")
                        .header("Authorization", "Bearer " + TestJobAuthoriser.PASSWORD))
                .andExpect(status().isOk());
    }

    private void enforce() throws Exception {
        mvc.perform(post("/internal/jobs/platform-billing-enforcement")
                        .header("Authorization", "Bearer " + TestJobAuthoriser.PASSWORD))
                .andExpect(status().isOk());
    }

    private ResultActions mine() throws Exception {
        return mvc.perform(get("/api/v1/me/platform-invoices")
                .header("Authorization", "Bearer " + landlordToken));
    }

    private String invoiceId() throws Exception {
        String body = mine().andReturn().getResponse().getContentAsString();
        return json.readTree(body).get(0).get("id").asText();
    }

    private ResultActions propertyStatus() throws Exception {
        return mvc.perform(get("/api/v1/admin/landlords/" + elena.id())
                .header("Authorization", "Bearer " + adminToken));
    }

    private ResultActions pay(String token, String invoice, int amount, boolean withProof)
            throws Exception {
        MockMultipartHttpServletRequestBuilder call =
                multipart("/api/v1/me/platform-invoices/" + invoice + "/payments");
        call.file(new MockMultipartFile("payment", "", "application/json",
                "{\"amountPaid\":%d.00,\"paymentMethod\":\"GCASH\"}".formatted(amount).getBytes()));
        if (withProof) {
            call.file(new MockMultipartFile("proof", "p.jpg", "image/jpeg", photo()));
        }
        return mvc.perform(call.header("Authorization", "Bearer " + token));
    }

    /** The newest payment on the invoice that came back. */
    private String paymentId(ResultActions paid) throws Exception {
        String body = paid.andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        var sent = json.readTree(body).get("payments");
        return sent.get(sent.size() - 1).get("id").asText();
    }

    private ResultActions admin(String payment, String action, String reason) throws Exception {
        var call = post("/api/v1/admin/platform-payments/" + payment + "/" + action)
                .header("Authorization", "Bearer " + adminToken);
        if (reason != null) {
            call.contentType(MediaType.APPLICATION_JSON)
                    .content(json.writeValueAsString(java.util.Map.of("remarks", reason)));
        }
        return mvc.perform(call);
    }

    private boolean queueHas(String payment) throws Exception {
        var queue = json.readTree(mvc.perform(get("/api/v1/admin/platform-payments")
                        .header("Authorization", "Bearer " + adminToken))
                .andReturn().getResponse().getContentAsString());
        for (var row : queue) {
            if (payment.equals(row.path("id").asText())) {
                return true;
            }
        }
        return false;
    }

    private long notificationsAbout(String token, String entity, String type) throws Exception {
        var feed = json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + token))
                .andReturn().getResponse().getContentAsString());
        long count = 0;
        for (var row : feed) {
            if (entity.equals(row.path("relatedEntityId").asText())
                    && type.equals(row.path("type").asText())) {
                count++;
            }
        }
        return count;
    }

    private String createProperty(String name) throws Exception {
        String body = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(java.util.Map.of(
                                "name", name, "address", "12 Mabini St",
                                "type", "BOARDING_HOUSE", "usage", "RESIDENTIAL"))))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("id").asText();
    }

    private String createUnit(String property, String unit) throws Exception {
        String body = mvc.perform(post("/api/v1/properties/" + property + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(unit))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("id").asText();
    }

    private void letBed(String tenantToken, int bedIndex) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + bedUnitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bed = json.readTree(beds).get(bedIndex).get("id").asText();
        accept(ask(tenantToken, "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(bedUnitId, bed)));
    }

    private void letWholeUnit(String tenantToken) throws Exception {
        accept(ask(tenantToken, "{\"unitId\":\"%s\"}".formatted(wholeUnitId)));
    }

    private String ask(String tenantToken, String body) throws Exception {
        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(request).get("id").asText();
    }

    private void accept(String request) throws Exception {
        mvc.perform(post("/api/v1/rental-requests/" + request + "/accept")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rentAmount\":2500.00,\"startDate\":\"%s\"}"
                                .formatted(LocalDate.now(clock))))
                .andExpect(status().isOk());
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
