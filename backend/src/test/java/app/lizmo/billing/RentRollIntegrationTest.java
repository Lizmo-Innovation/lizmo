package app.lizmo.billing;

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
import java.time.YearMonth;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Rent for one month, room by room.
 *
 * <p>The ledger a landlord kept in a notebook. The tests are about which month
 * a rent belongs to, the month's figures agreeing with the dashboard, and a
 * past month staying as it was after somebody moves out.
 */
class RentRollIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private String landlordToken;
    private String otherLandlordToken;
    private String anaToken;
    private String beaToken;

    private String unitId;

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

        makeReadyForALease(anaToken);
        makeReadyForALease(beaToken);
    }

    // ---- which month a rent belongs to --------------------------------------

    @Test
    void a_landlord_with_nothing_let_has_an_empty_month() throws Exception {
        roll(null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.month").value(thisMonth()))
                .andExpect(jsonPath("$.earliestMonth").isEmpty())
                .andExpect(jsonPath("$.rows.length()").value(0));
    }

    @Test
    void a_tenancy_appears_in_the_month_its_rent_falls_due() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock));

        roll(null)
                .andExpect(jsonPath("$.rows.length()").value(1))
                .andExpect(jsonPath("$.rows[0].leaseId").value(lease))
                .andExpect(jsonPath("$.rows[0].tenantName").value("ana"))
                .andExpect(jsonPath("$.rows[0].propertyName").value("Sunrise Apartments"))
                .andExpect(jsonPath("$.rows[0].unitNumber").value("2B"))
                .andExpect(jsonPath("$.rows[0].bedLabel").isNotEmpty())
                .andExpect(jsonPath("$.rows[0].current").value(true))
                .andExpect(jsonPath("$.rows[0].period.amountDue").value(2500.00))
                .andExpect(jsonPath("$.rows[0].period.status").value("UNPAID"))
                .andExpect(jsonPath("$.earliestMonth").value(thisMonth()));
    }

    /** A month nothing has begun in, and a month before anybody moved in. */
    @Test
    void a_month_nothing_fell_due_in_is_empty() throws Exception {
        let(anaToken, 0, LocalDate.now(clock));

        roll(YearMonth.now(clock).plusMonths(1).toString())
                .andExpect(jsonPath("$.rows.length()").value(0));
        roll(YearMonth.now(clock).minusMonths(1).toString())
                .andExpect(jsonPath("$.rows.length()").value(0))
                // Still says how far back there is anything to see.
                .andExpect(jsonPath("$.earliestMonth").value(thisMonth()));
    }

    // ---- the month's figures ----------------------------------------------------

    /** The Rent tab and Today must never disagree about the same money. */
    @Test
    void the_month_adds_up_the_same_as_the_dashboard() throws Exception {
        String anas = let(anaToken, 0, LocalDate.now(clock));
        let(beaToken, 1, LocalDate.now(clock));
        record(anas, 2500);

        roll(null)
                .andExpect(jsonPath("$.due").value(5000.00))
                .andExpect(jsonPath("$.collected").value(2500.00))
                .andExpect(jsonPath("$.outstanding").value(2500.00));

        mvc.perform(get("/api/v1/me/collections")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.dueThisMonth").value(5000.00))
                .andExpect(jsonPath("$.collectedThisMonth").value(2500.00));
    }

    @Test
    void a_payment_the_tenant_declared_waits_on_its_row() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock));
        String payment = declare(lease, 2500);

        roll(null)
                .andExpect(jsonPath("$.rows[0].waiting.length()").value(1))
                .andExpect(jsonPath("$.rows[0].waiting[0].paymentId").value(payment))
                .andExpect(jsonPath("$.rows[0].waiting[0].amount").value(2500.00))
                .andExpect(jsonPath("$.rows[0].waiting[0].method").value("GCASH"))
                // A claim is not money until the landlord agrees.
                .andExpect(jsonPath("$.rows[0].period.status").value("UNPAID"))
                .andExpect(jsonPath("$.collected").value(0));
    }

    @Test
    void confirming_it_settles_the_row() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock));
        String payment = declare(lease, 2500);

        mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + payment + "/confirm")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        roll(null)
                .andExpect(jsonPath("$.rows[0].waiting.length()").value(0))
                .andExpect(jsonPath("$.rows[0].period.status").value("PAID"))
                .andExpect(jsonPath("$.collected").value(2500.00));
    }

    @Test
    void a_month_left_unpaid_is_marked_late() throws Exception {
        String month = thisMonth();
        let(anaToken, 0, LocalDate.now(clock));

        clock.advanceDays(40);

        roll(month)
                .andExpect(jsonPath("$.rows[0].period.overdue").value(true));
    }

    // ---- the past stays as it was ---------------------------------------------

    /**
     * Leaving somebody out once they move out would rewrite the month every
     * time a tenancy ended, and a landlord looking back wants it as it was.
     */
    @Test
    void somebody_who_moved_out_stays_in_the_month_they_owed() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\"}".formatted(LocalDate.now(clock))))
                .andExpect(status().isOk());

        roll(null)
                .andExpect(jsonPath("$.rows.length()").value(1))
                .andExpect(jsonPath("$.rows[0].leaseId").value(lease))
                .andExpect(jsonPath("$.rows[0].current").value(false));
    }

    // ---- whose it is ------------------------------------------------------------

    @Test
    void another_landlord_sees_none_of_it() throws Exception {
        let(anaToken, 0, LocalDate.now(clock));

        mvc.perform(get("/api/v1/me/rent-roll")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rows.length()").value(0));
    }

    @Test
    void a_month_that_is_not_a_month_is_refused() throws Exception {
        roll("September").andExpect(status().isBadRequest());
    }

    @Test
    void reading_it_requires_signing_in() throws Exception {
        mvc.perform(get("/api/v1/me/rent-roll"))
                .andExpect(status().isUnauthorized());
    }

    // ---- fixtures ---------------------------------------------------------------

    private String thisMonth() {
        return YearMonth.now(clock).toString();
    }

    private ResultActions roll(String month) throws Exception {
        return mvc.perform(get("/api/v1/me/rent-roll"
                        + (month == null ? "" : "?month=" + month))
                .header("Authorization", "Bearer " + landlordToken));
    }

    private String let(String tenantToken, int bedIndex, LocalDate start) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bed = json.readTree(beds).get(bedIndex).get("id").asText();

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
                        .content("{\"rentAmount\":2500.00,\"startDate\":\"%s\"}".formatted(start)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(lease).get("id").asText();
    }

    private String firstPeriod(String leaseId) throws Exception {
        String months = mvc.perform(get("/api/v1/leases/" + leaseId + "/billing")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        return json.readTree(months).get(0).get("id").asText();
    }

    /** Money the landlord received themselves: confirmed on the spot. */
    private void record(String leaseId, int amount) throws Exception {
        mvc.perform(post("/api/v1/leases/" + leaseId + "/payments")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"billingPeriodId\":\"%s\",\"amountPaid\":%d.00,\"paymentMethod\":\"CASH\"}"
                                .formatted(firstPeriod(leaseId), amount)))
                .andExpect(status().isCreated());
    }

    /** @return the payment id */
    private String declare(String leaseId, int amount) throws Exception {
        String declared = mvc.perform(multipart("/api/v1/me/leases/" + leaseId + "/payments")
                        .part(new MockPart("billingPeriodId", firstPeriod(leaseId).getBytes()))
                        .part(new MockPart("amountPaid", String.valueOf(amount).getBytes()))
                        .part(new MockPart("paymentMethod", "GCASH".getBytes()))
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(declared).get("id").asText();
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
