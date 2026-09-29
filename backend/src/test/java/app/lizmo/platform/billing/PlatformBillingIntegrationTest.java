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
import com.fasterxml.jackson.databind.JsonNode;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder;

/**
 * Lizmo billing landlords, and being paid.
 *
 * <p>One statement a month per landlord, itemised by property. The invoices are
 * the statement's lines, and only carry a number once it is settled.
 *
 * <p>Every test that runs the snapshot bills every landlord in the shared
 * database, not only this class's. So nothing here counts globally: each
 * assertion is about Elena's own statement, read back through her own endpoint,
 * or about one payment by id.
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

    private String sunriseId;
    private String bedUnitId;
    private String seaviewId;
    private String seaviewUnitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();

        elena = accounts.landlord("elena");
        landlordToken = elena.token();
        otherLandlordToken = accounts.landlord("mario").token();
        adminToken = accounts.admin("staff").token();
        anaToken = accounts.tenant("ana").token();
        beaToken = accounts.tenant("bea").token();

        sunriseId = createProperty("Sunrise Apartments");
        bedUnitId = createUnit(sunriseId, """
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE","capacity":3,"rent":2500.00}
                """);
        // Left empty on purpose: what is vacant is never billed.
        createUnit(sunriseId, """
                {"unitNumber":"1A","floor":"1","rentalMode":"WHOLE_UNIT","capacity":1,"rent":7000.00}
                """);

        // A second building, empty until a test lets something in it, because a
        // statement covering more than one property is the point of all this.
        seaviewId = createProperty("Seaview Lodge");
        seaviewUnitId = createUnit(seaviewId, """
                {"unitNumber":"G","floor":"G","rentalMode":"WHOLE_UNIT","capacity":1,"rent":9000.00}
                """);

        makeReadyForALease(anaToken);
        makeReadyForALease(beaToken);
    }

    // ---- the statement ----------------------------------------------------------------

    /** One bill for the month, a line per property: P50 a let bed, P150 a let whole unit. */
    @Test
    void one_statement_covers_every_property_the_landlord_has_let() throws Exception {
        letBed(anaToken, 0);
        letWholeUnit(beaToken, seaviewUnitId);

        snapshot();

        mine()
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].label").value(label()))
                .andExpect(jsonPath("$[0].amountDue").value(200.00))
                .andExpect(jsonPath("$[0].outstanding").value(200.00))
                .andExpect(jsonPath("$[0].status").value("UNPAID"))
                .andExpect(jsonPath("$[0].billingDate").value(firstOfMonth().toString()))
                .andExpect(jsonPath("$[0].dueDate").value(firstOfMonth().toString()))
                .andExpect(jsonPath("$[0].lines.length()").value(2))
                .andExpect(jsonPath("$[0].lines[0].propertyName").value("Seaview Lodge"))
                .andExpect(jsonPath("$[0].lines[0].occupiedUnits").value(1))
                .andExpect(jsonPath("$[0].lines[0].occupiedBeds").value(0))
                .andExpect(jsonPath("$[0].lines[0].unitRate").value(150.00))
                .andExpect(jsonPath("$[0].lines[0].amountDue").value(150.00))
                .andExpect(jsonPath("$[0].lines[1].propertyName").value("Sunrise Apartments"))
                .andExpect(jsonPath("$[0].lines[1].occupiedBeds").value(1))
                // Its whole unit stands empty, so it is not on the bill.
                .andExpect(jsonPath("$[0].lines[1].occupiedUnits").value(0))
                .andExpect(jsonPath("$[0].lines[1].bedRate").value(50.00))
                .andExpect(jsonPath("$[0].lines[1].amountDue").value(50.00));
    }

    /** Nothing is invoiced until the statement is paid, so no line has a number yet. */
    @Test
    void an_unpaid_statement_has_no_invoice_numbers() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        mine()
                .andExpect(jsonPath("$[0].lines[0].invoiceNumber").doesNotExist())
                .andExpect(jsonPath("$[0].lines[0].issuedAt").doesNotExist());
    }

    /** Vacant inventory costs nothing, and a line for nothing is noise. */
    @Test
    void a_property_with_nothing_let_is_not_on_the_statement() throws Exception {
        letBed(anaToken, 0);

        snapshot();

        mine()
                .andExpect(jsonPath("$[0].lines.length()").value(1))
                .andExpect(jsonPath("$[0].lines[0].propertyName").value("Sunrise Apartments"))
                .andExpect(jsonPath("$[0].amountDue").value(50.00));
    }

    @Test
    void a_landlord_with_nothing_let_gets_no_statement() throws Exception {
        letBed(anaToken, 0);

        snapshot();

        statements(otherLandlordToken).andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void running_it_twice_bills_once() throws Exception {
        letBed(anaToken, 0);

        snapshot();
        snapshot();

        mine()
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].lines.length()").value(1));
    }

    @Test
    void the_landlord_is_told_a_statement_arrived() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        assertThat(notificationsAbout(landlordToken, statementId(), "PLATFORM_INVOICE_ISSUED"))
                .isEqualTo(1);
    }

    // ---- enforcement --------------------------------------------------------------------

    @Test
    void an_overdue_statement_is_warned_about_once() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        clock.advanceDays(1);

        enforce();
        enforce();

        assertThat(notificationsAbout(landlordToken, statementId(), "PLATFORM_INVOICE_OVERDUE"))
                .isEqualTo(1);
        mine().andExpect(jsonPath("$[0].overdue").value(true));
    }

    /**
     * Ariel's thirty days, not the spec's seven — and the whole account, not
     * only what is on the statement: the debt is the landlord's.
     */
    @Test
    void every_property_locks_thirty_days_after_the_due_date_and_not_before() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        long days = ChronoUnit.DAYS.between(LocalDate.now(clock), firstOfMonth().plusDays(30));
        if (days > 0) {
            clock.advanceDays(days - 1);
            enforce();
            assertThat(accountStatuses()).containsOnly("ACTIVE");
            clock.advanceDays(1);
        }

        enforce();

        // Seaview has nothing let and is not on the statement, and locks anyway.
        assertThat(accountStatuses()).containsOnly("LOCKED");
        mine()
                .andExpect(jsonPath("$[0].locked").value(true))
                .andExpect(jsonPath("$[0].locksOn").doesNotExist());
        assertThat(notificationsAbout(landlordToken, statementId(), "PLATFORM_PROPERTY_LOCKED"))
                .isEqualTo(1);
    }

    // ---- paying -------------------------------------------------------------------------

    @Test
    void a_landlord_pays_with_proof_and_it_waits_for_an_admin() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        pay(landlordToken, statementId(), 50, true)
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

        pay(landlordToken, statementId(), 50, false).andExpect(status().isBadRequest());
    }

    @Test
    void another_landlord_can_neither_see_nor_pay_it() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String statement = statementId();

        statements(otherLandlordToken).andExpect(jsonPath("$.length()").value(0));
        pay(otherLandlordToken, statement, 50, true).andExpect(status().isNotFound());
    }

    // ---- an admin checking it -------------------------------------------------------------

    /** Paying in full is the moment each property gets an invoice of its own. */
    @Test
    void confirming_the_last_of_it_issues_an_invoice_for_each_property() throws Exception {
        letBed(anaToken, 0);
        letWholeUnit(beaToken, seaviewUnitId);
        snapshot();
        String statement = statementId();
        String payment = paymentId(pay(landlordToken, statement, 200, true));

        admin(payment, "confirm", null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.landlordName").value("elena"))
                .andExpect(jsonPath("$.statementLabel").value(label()))
                .andExpect(jsonPath("$.properties").value(2))
                .andExpect(jsonPath("$.statementOutstanding").value(0));

        mine()
                .andExpect(jsonPath("$[0].status").value("PAID"))
                .andExpect(jsonPath("$[0].amountPaid").value(200.00))
                .andExpect(jsonPath("$[0].outstanding").value(0));

        List<String> numbers = new ArrayList<>();
        for (JsonNode line : lines()) {
            assertThat(line.path("issuedAt").isNull()).isFalse();
            numbers.add(line.path("invoiceNumber").asText());
        }
        // One number each, none shared, and each readable on paper.
        assertThat(numbers).hasSize(2).doesNotHaveDuplicates()
                .allMatch(number -> number.matches(
                        "LZM-%s-\\d{4}".formatted(YearMonth.now(clock))));
        assertThat(notificationsAbout(landlordToken, statement, "PLATFORM_PAYMENT_CONFIRMED"))
                .isEqualTo(1);
    }

    @Test
    void the_queue_shows_what_is_waiting_and_not_what_was_answered() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String payment = paymentId(pay(landlordToken, statementId(), 50, true));

        assertThat(queueHas(payment)).isTrue();
        admin(payment, "confirm", null).andExpect(status().isOk());
        assertThat(queueHas(payment)).isFalse();
    }

    @Test
    void a_payment_is_answered_once() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String payment = paymentId(pay(landlordToken, statementId(), 50, true));

        admin(payment, "confirm", null).andExpect(status().isOk());
        admin(payment, "confirm", null).andExpect(status().isBadRequest());
        admin(payment, "reject", "Too late.").andExpect(status().isBadRequest());
    }

    /** Half a statement is not an invoice, so nothing is issued until the rest lands. */
    @Test
    void part_of_it_leaves_the_rest_owed_and_issues_nothing() throws Exception {
        letBed(anaToken, 0);
        letBed(beaToken, 1);
        snapshot();
        String statement = statementId();
        String payment = paymentId(pay(landlordToken, statement, 40, true));

        admin(payment, "confirm", null).andExpect(status().isOk());

        mine()
                .andExpect(jsonPath("$[0].status").value("PARTIALLY_PAID"))
                .andExpect(jsonPath("$[0].outstanding").value(60.00))
                .andExpect(jsonPath("$[0].lines[0].invoiceNumber").doesNotExist());

        // And the rest of it finishes the job.
        String second = paymentId(pay(landlordToken, statement, 60, true));
        admin(second, "confirm", null).andExpect(status().isOk());
        mine()
                .andExpect(jsonPath("$[0].status").value("PAID"))
                .andExpect(jsonPath("$[0].lines[0].invoiceNumber").isNotEmpty());
    }

    @Test
    void refusing_one_tells_the_landlord_why_and_moves_nothing() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        String statement = statementId();
        String payment = paymentId(pay(landlordToken, statement, 50, true));

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
    void paying_in_full_lifts_every_lock_the_statement_caused() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        clock.advanceDays(45);
        enforce();
        assertThat(accountStatuses()).containsOnly("LOCKED");

        String payment = paymentId(pay(landlordToken, statementId(), 50, true));
        admin(payment, "confirm", null).andExpect(status().isOk());

        assertThat(accountStatuses()).containsOnly("ACTIVE");
    }

    @Test
    void paying_part_of_it_leaves_the_properties_locked() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        clock.advanceDays(45);
        enforce();

        String payment = paymentId(pay(landlordToken, statementId(), 20, true));
        admin(payment, "confirm", null).andExpect(status().isOk());

        assertThat(accountStatuses()).containsOnly("LOCKED");
    }

    /** A lock placed by hand is an admin's decision, and paying does not undo it. */
    @Test
    void a_lock_an_admin_placed_is_not_lifted_by_paying() throws Exception {
        letBed(anaToken, 0);
        snapshot();
        mvc.perform(post("/api/v1/admin/properties/" + sunriseId + "/lock")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
        clock.advanceDays(45);
        enforce();

        String payment = paymentId(pay(landlordToken, statementId(), 50, true));
        admin(payment, "confirm", null).andExpect(status().isOk());

        assertThat(statusOf(sunriseId)).isEqualTo("LOCKED");
        assertThat(statusOf(seaviewId)).isEqualTo("ACTIVE");
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
    void the_admin_sees_a_landlords_statements() throws Exception {
        letBed(anaToken, 0);
        snapshot();

        mvc.perform(get("/api/v1/admin/landlords/" + elena.id() + "/statements")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].amountDue").value(50.00))
                .andExpect(jsonPath("$[0].lines[0].propertyName")
                        .value("Sunrise Apartments"));
    }

    // ---- fixtures -----------------------------------------------------------------------------

    private LocalDate firstOfMonth() {
        return YearMonth.now(clock).atDay(1);
    }

    /** "September 2026", as the statement labels itself. */
    private String label() {
        return java.time.format.DateTimeFormatter
                .ofPattern("MMMM yyyy", java.util.Locale.ENGLISH)
                .format(firstOfMonth());
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
        return statements(landlordToken);
    }

    private ResultActions statements(String token) throws Exception {
        return mvc.perform(get("/api/v1/me/platform-statements")
                .header("Authorization", "Bearer " + token));
    }

    private String statementId() throws Exception {
        String body = mine().andReturn().getResponse().getContentAsString();
        return json.readTree(body).get(0).get("id").asText();
    }

    private JsonNode lines() throws Exception {
        String body = mine().andReturn().getResponse().getContentAsString();
        return json.readTree(body).get(0).get("lines");
    }

    /** What the admin console shows for each of Elena's properties. */
    private List<String> accountStatuses() throws Exception {
        List<String> statuses = new ArrayList<>();
        for (JsonNode property : landlordDetail().path("properties")) {
            statuses.add(property.path("accountStatus").asText());
        }
        assertThat(statuses).hasSize(2);
        return statuses;
    }

    private String statusOf(String propertyId) throws Exception {
        for (JsonNode property : landlordDetail().path("properties")) {
            if (propertyId.equals(property.path("id").asText())) {
                return property.path("accountStatus").asText();
            }
        }
        return null;
    }

    private JsonNode landlordDetail() throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/admin/landlords/" + elena.id())
                        .header("Authorization", "Bearer " + adminToken))
                .andReturn().getResponse().getContentAsString());
    }

    private ResultActions pay(String token, String statement, int amount, boolean withProof)
            throws Exception {
        MockMultipartHttpServletRequestBuilder call =
                multipart("/api/v1/me/platform-statements/" + statement + "/payments");
        // Plain text parts with no content type, as the app sends them.
        call.part(new MockPart("amountPaid", String.valueOf(amount).getBytes()));
        call.part(new MockPart("paymentMethod", "GCASH".getBytes()));
        if (withProof) {
            call.file(new MockMultipartFile("proof", "p.jpg", "image/jpeg", photo()));
        }
        return mvc.perform(call.header("Authorization", "Bearer " + token));
    }

    /** The newest payment on the statement that came back. */
    private String paymentId(ResultActions paid) throws Exception {
        String body =
                paid.andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
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

    private void letWholeUnit(String tenantToken, String unitId) throws Exception {
        accept(ask(tenantToken, "{\"unitId\":\"%s\"}".formatted(unitId)));
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
