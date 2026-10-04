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
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Rent across a whole portfolio.
 *
 * <p>The dashboard has promised this since the beginning under a placeholder
 * reading "Needs leases and billing". Both now exist, so the tests are about
 * the arithmetic being right across several tenancies at once — and about the
 * numbers agreeing with what each tenant's own screen says.
 */
class CollectionsIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private String landlordToken;
    private String anaToken;
    private String beaToken;

    private String unitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();

        landlordToken = accounts.landlord("elena").token();
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

    // ---- the figures -------------------------------------------------------

    @Test
    void a_landlord_with_nothing_let_is_owed_nothing() throws Exception {
        collections()
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dueThisMonth").value(0))
                .andExpect(jsonPath("$.outstandingAllTime").value(0))
                .andExpect(jsonPath("$.inArrears.length()").value(0));
    }

    @Test
    void two_tenancies_add_up() throws Exception {
        let(anaToken, 0, LocalDate.now(clock));
        let(beaToken, 1, LocalDate.now(clock));

        collections()
                .andExpect(jsonPath("$.dueThisMonth").value(5000.00))
                .andExpect(jsonPath("$.collectedThisMonth").value(0))
                .andExpect(jsonPath("$.outstandingAllTime").value(5000.00));
    }

    @Test
    void an_advance_counts_as_collected() throws Exception {
        letWith(anaToken, 0, LocalDate.now(clock), "\"advanceAmount\":2500.00");

        collections()
                .andExpect(jsonPath("$.dueThisMonth").value(2500.00))
                .andExpect(jsonPath("$.collectedThisMonth").value(2500.00))
                .andExpect(jsonPath("$.outstandingAllTime").value(0));
    }

    /**
     * A tenant's unverified claim is not money. Counting it would tell a
     * landlord they had been paid on the strength of somebody saying so.
     */
    @Test
    void an_unconfirmed_claim_is_not_collected() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock));
        declare(lease, 2500);

        collections()
                .andExpect(jsonPath("$.collectedThisMonth").value(0))
                .andExpect(jsonPath("$.outstandingAllTime").value(2500.00))
                // But the landlord is told somebody is waiting on them.
                .andExpect(jsonPath("$.awaitingConfirmation").value(1));
    }

    /**
     * The count alone told a landlord somebody was waiting and gave them no
     * way to find out who. Each claim names the tenancy to open.
     */
    @Test
    void a_waiting_claim_says_whose_it_is() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock));
        String payment = declare(lease, 2500);

        collections()
                .andExpect(jsonPath("$.awaiting.length()").value(1))
                .andExpect(jsonPath("$.awaiting[0].leaseId").value(lease))
                .andExpect(jsonPath("$.awaiting[0].paymentId").value(payment))
                .andExpect(jsonPath("$.awaiting[0].tenantName").isNotEmpty())
                .andExpect(jsonPath("$.awaiting[0].unitNumber").value("2B"))
                .andExpect(jsonPath("$.awaiting[0].bedLabel").value("Bed 1"))
                .andExpect(jsonPath("$.awaiting[0].amount").value(2500.00));
    }

    @Test
    void confirming_moves_it_into_collected() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock));
        String payment = declare(lease, 2500);

        mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + payment + "/confirm")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        collections()
                .andExpect(jsonPath("$.collectedThisMonth").value(2500.00))
                .andExpect(jsonPath("$.outstandingAllTime").value(0))
                .andExpect(jsonPath("$.awaitingConfirmation").value(0))
                .andExpect(jsonPath("$.awaiting.length()").value(0));
    }

    // ---- who is behind -----------------------------------------------------

    @Test
    void nobody_is_in_arrears_before_rent_falls_due() throws Exception {
        let(anaToken, 0, LocalDate.now(clock));

        collections()
                .andExpect(jsonPath("$.tenanciesInArrears").value(0))
                .andExpect(jsonPath("$.inArrears.length()").value(0));
    }

    @Test
    void a_late_tenant_appears_with_how_far_behind_they_are() throws Exception {
        let(anaToken, 0, LocalDate.now(clock));

        // Two periods: the one that started on day zero, and the one a month
        // later. Both fell due before day forty.
        clock.advanceDays(40);

        collections()
                .andExpect(jsonPath("$.tenanciesInArrears").value(1))
                .andExpect(jsonPath("$.inArrears[0].tenantName").value("ana"))
                .andExpect(jsonPath("$.inArrears[0].monthsLate").value(2))
                .andExpect(jsonPath("$.inArrears[0].outstanding").value(5000.00))
                .andExpect(jsonPath("$.inArrears[0].bedLabel").isNotEmpty());
    }

    /**
     * Worst first. The tenant furthest behind is the one a landlord has to deal
     * with, and a list sorted by anything else buries them.
     */
    @Test
    void the_furthest_behind_comes_first() throws Exception {
        let(anaToken, 0, LocalDate.now(clock).minusMonths(3));
        let(beaToken, 1, LocalDate.now(clock));

        clock.advanceDays(40);

        collections()
                .andExpect(jsonPath("$.tenanciesInArrears").value(2))
                .andExpect(jsonPath("$.inArrears[0].tenantName").value("ana"))
                .andExpect(jsonPath("$.inArrears[1].tenantName").value("bea"));
    }

    /**
     * Rent owed by somebody who moved out is a debt, not a collection problem.
     * Mixing them would make the dashboard read worse every time a tenancy
     * ended badly.
     */
    @Test
    void an_ended_tenancy_leaves_the_dashboard() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock));
        clock.advanceDays(40);
        collections().andExpect(jsonPath("$.tenanciesInArrears").value(1));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\"}".formatted(LocalDate.now(clock))))
                .andExpect(status().isOk());

        collections()
                .andExpect(jsonPath("$.tenanciesInArrears").value(0))
                .andExpect(jsonPath("$.outstandingAllTime").value(0));
    }

    @Test
    void another_landlord_sees_their_own_figures() throws Exception {
        let(anaToken, 0, LocalDate.now(clock));

        mvc.perform(get("/api/v1/me/collections")
                        .header("Authorization", "Bearer " + accounts.landlord("mario").token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dueThisMonth").value(0));
    }

    /**
     * The dashboard reads the same billing periods a tenant's own screen
     * shows, so the two can never disagree about the same money. Asking is
     * also what brings a schedule up to date -- a tenancy nobody has opened
     * this month still has to be counted.
     */
    @Test
    void the_dashboard_counts_a_tenancy_nobody_has_opened() throws Exception {
        String lease = let(anaToken, 0, LocalDate.now(clock).minusMonths(2));

        // Nothing has read this tenancy's rent since the lease was created.
        collections().andExpect(jsonPath("$.outstandingAllTime").value(7500.00));

        mvc.perform(get("/api/v1/me/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(3));
    }

    // ---- fixtures ----------------------------------------------------------

    private ResultActions collections() throws Exception {
        return mvc.perform(get("/api/v1/me/collections")
                .header("Authorization", "Bearer " + landlordToken));
    }

    private String let(String tenantToken, int bedIndex, LocalDate start) throws Exception {
        return letWith(tenantToken, bedIndex, start, null);
    }

    private String letWith(
            String tenantToken, int bedIndex, LocalDate start, String extra) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bed = json.readTree(beds).get(bedIndex).get("id").asText();

        String lease = letRoom(
                landlordToken,
                tenantToken,
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bed),
                "{\"rentAmount\":2500.00,\"startDate\":\"%s\"%s}"
                                .formatted(start, extra == null ? "" : "," + extra));
        return json.readTree(lease).get("id").asText();
    }

    /** @return the payment id */
    private String declare(String leaseId, int amount) throws Exception {
        String months = mvc.perform(get("/api/v1/leases/" + leaseId + "/billing")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String period = json.readTree(months).get(0).get("id").asText();

        String declared = mvc.perform(multipart("/api/v1/me/leases/" + leaseId + "/payments")
                        .part(new MockPart("billingPeriodId", period.getBytes()))
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
