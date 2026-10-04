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
 * Rent, month by month, on a real tenancy.
 *
 * <p>Months are written the first time somebody looks rather than by a
 * scheduled job, so most of what matters here is that looking twice does not
 * produce two Octobers, and that time passing produces November.
 */
class BillingIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    @Autowired
    private BillingPeriodRepository periods;

    @Autowired
    private PaymentRepository payments;

    private String landlordToken;
    private String anaToken;

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
    }

    // ---- the months exist --------------------------------------------------

    @Test
    void a_new_tenancy_owes_for_its_first_month() throws Exception {
        String lease = let(today(), null);

        billing(lease)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].amountDue").value(2500.00))
                .andExpect(jsonPath("$[0].amountPaid").value(0))
                .andExpect(jsonPath("$[0].outstanding").value(2500.00))
                .andExpect(jsonPath("$[0].status").value("UNPAID"));
    }

    /**
     * Months are written on read, so this is the property everything else
     * rests on: looking twice must not produce two Octobers.
     */
    @Test
    void looking_twice_does_not_create_the_month_twice() throws Exception {
        String lease = let(today(), null);

        billing(lease).andExpect(jsonPath("$.length()").value(1));
        billing(lease).andExpect(jsonPath("$.length()").value(1));
        billing(lease).andExpect(jsonPath("$.length()").value(1));

        assertThat(periods.findByLeaseIdOrderByPeriodStartAsc(java.util.UUID.fromString(lease)))
                .hasSize(1);
    }

    @Test
    void a_month_appears_once_it_begins() throws Exception {
        String lease = let(today(), null);
        billing(lease).andExpect(jsonPath("$.length()").value(1));

        clock.advanceDays(32);

        billing(lease).andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void the_tenant_sees_the_same_months() throws Exception {
        String lease = let(today(), null);

        mvc.perform(get("/api/v1/me/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].amountDue").value(2500.00));
    }

    @Test
    void another_landlord_sees_nothing() throws Exception {
        String lease = let(today(), null);

        mvc.perform(get("/api/v1/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + accounts.landlord("mario").token()))
                .andExpect(status().isNotFound());
    }

    @Test
    void another_tenant_sees_nothing() throws Exception {
        String lease = let(today(), null);

        mvc.perform(get("/api/v1/me/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + accounts.tenant("bea").token()))
                .andExpect(status().isNotFound());
    }

    // ---- the advance -------------------------------------------------------

    /**
     * Ariel's call: rent handed over before moving in pays the first month. A
     * tenant who paid an advance and then sees month one marked UNPAID would
     * reasonably conclude the app had lost their money.
     */
    @Test
    void an_advance_pays_the_first_month() throws Exception {
        String lease = let(today(), "\"advanceAmount\":2500.00");

        billing(lease)
                .andExpect(jsonPath("$[0].amountPaid").value(2500.00))
                .andExpect(jsonPath("$[0].outstanding").value(0))
                .andExpect(jsonPath("$[0].status").value("PAID"));
    }

    /**
     * Recorded as a payment rather than by marking the period paid: amount_paid
     * has to agree with the payments behind it, or a tenant's history shows a
     * month settled by nothing at all.
     */
    @Test
    void the_advance_leaves_a_payment_behind_it() throws Exception {
        String lease = let(today(), "\"advanceAmount\":2500.00");
        billing(lease).andExpect(status().isOk());

        assertThat(payments.findByLeaseIdOrderByPaymentDateDesc(
                java.util.UUID.fromString(lease)))
                .singleElement()
                .satisfies(payment -> {
                    assertThat(payment.getPaymentMethod()).isEqualTo(PaymentMethod.ADVANCE);
                    assertThat(payment.isConfirmed()).isTrue();
                    assertThat(payment.getAmountPaid())
                            .isEqualByComparingTo(new java.math.BigDecimal("2500.00"));
                });
    }

    @Test
    void a_part_advance_leaves_the_rest_owing() throws Exception {
        String lease = let(today(), "\"advanceAmount\":1000.00");

        billing(lease)
                .andExpect(jsonPath("$[0].amountPaid").value(1000.00))
                .andExpect(jsonPath("$[0].outstanding").value(1500.00))
                .andExpect(jsonPath("$[0].status").value("PARTIALLY_PAID"));
    }

    /**
     * An advance bigger than a month settles that month and stops. Spilling it
     * forward would be a guess about an agreement nobody wrote down.
     */
    @Test
    void a_large_advance_does_not_spill_into_next_month() throws Exception {
        String lease = let(today(), "\"advanceAmount\":6000.00");
        billing(lease).andExpect(status().isOk());

        clock.advanceDays(32);

        billing(lease)
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].status").value("PAID"))
                .andExpect(jsonPath("$[1].status").value("UNPAID"))
                .andExpect(jsonPath("$[1].outstanding").value(2500.00));
    }

    @Test
    void the_advance_is_applied_once_however_often_it_is_read() throws Exception {
        String lease = let(today(), "\"advanceAmount\":2500.00");

        billing(lease).andExpect(status().isOk());
        billing(lease).andExpect(status().isOk());
        clock.advanceDays(32);
        billing(lease).andExpect(status().isOk());

        assertThat(payments.findByLeaseIdOrderByPaymentDateDesc(
                java.util.UUID.fromString(lease))).hasSize(1);
        billing(lease).andExpect(jsonPath("$[0].amountPaid").value(2500.00));
    }

    @Test
    void a_tenancy_with_no_advance_owes_the_lot() throws Exception {
        String lease = let(today(), null);

        billing(lease)
                .andExpect(jsonPath("$[0].amountPaid").value(0))
                .andExpect(jsonPath("$[0].status").value("UNPAID"));
    }

    // ---- being late --------------------------------------------------------

    /**
     * Worked out against today rather than stored. A period that fell due
     * yesterday is late this morning without anything having run overnight.
     */
    @Test
    void rent_becomes_overdue_on_its_own() throws Exception {
        String lease = let(today(), null);

        billing(lease).andExpect(jsonPath("$[0].overdue").value(false));

        clock.advanceDays(5);

        billing(lease).andExpect(jsonPath("$[0].overdue").value(true));
    }

    @Test
    void a_month_that_was_paid_is_never_late() throws Exception {
        String lease = let(today(), "\"advanceAmount\":2500.00");
        billing(lease).andExpect(status().isOk());

        clock.advanceDays(40);

        billing(lease).andExpect(jsonPath("$[0].overdue").value(false));
    }

    // ---- after the tenancy -------------------------------------------------

    @Test
    void an_ended_tenancy_stops_accruing() throws Exception {
        String lease = let(today(), null);
        billing(lease).andExpect(jsonPath("$.length()").value(1));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\"}".formatted(today())))
                .andExpect(status().isOk());

        clock.advanceDays(200);

        // A former tenant does not go on owing rent for a room they left.
        billing(lease).andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void a_former_tenant_keeps_their_rent_history() throws Exception {
        String lease = let(today(), "\"advanceAmount\":2500.00");
        billing(lease).andExpect(status().isOk());

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\"}".formatted(today())))
                .andExpect(status().isOk());

        // What you paid is worth having after you move out.
        mvc.perform(get("/api/v1/me/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].status").value("PAID"));
    }

    // ---- fixtures ----------------------------------------------------------

    private LocalDate today() {
        return LocalDate.now(clock);
    }

    private ResultActions billing(String leaseId) throws Exception {
        return mvc.perform(get("/api/v1/leases/" + leaseId + "/billing")
                .header("Authorization", "Bearer " + landlordToken));
    }

    /** @return the lease id */
    private String let(LocalDate start, String extraTerms) throws Exception {
        String terms = "{\"rentAmount\":2500.00,\"startDate\":\"%s\"%s}".formatted(
                start, extraTerms == null ? "" : "," + extraTerms);

        String lease = letRoom(
                landlordToken,
                anaToken,
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}"
                                .formatted(unitId, bedId),
                terms);
        return json.readTree(lease).get("id").asText();
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
