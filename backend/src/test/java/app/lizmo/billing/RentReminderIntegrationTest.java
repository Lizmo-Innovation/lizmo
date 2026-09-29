package app.lizmo.billing;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import app.lizmo.support.TestJobAuthoriser;
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
 * Telling a tenant rent is coming, and that it is late.
 *
 * <p>Run from a clock rather than when somebody looks, which is the opposite of
 * how billing periods work: a period nobody has opened can wait to be asked
 * for, and a reminder is for the tenant who has stopped asking.
 *
 * <p>Most of these tests are about not saying it twice. Cloud Scheduler retries
 * a failed run three times, and a job that resent everything on each retry
 * would put four identical messages in somebody's bell for one late month.
 */
class RentReminderIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private String landlordToken;
    private String anaToken;

    private String unitId;

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

        makeReadyForALease(anaToken);
    }

    // ---- who may run it ----------------------------------------------------

    /**
     * Being on /internal/ is not protection. Cloud Run serves it as publicly
     * as anything else.
     */
    @Test
    void a_stranger_cannot_run_the_job() throws Exception {
        mvc.perform(post("/internal/jobs/rent-reminders"))
                .andExpect(status().isNotFound());
    }

    @Test
    void neither_can_a_signed_in_tenant() throws Exception {
        mvc.perform(post("/internal/jobs/rent-reminders")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(status().isNotFound());
    }

    // ---- rent coming up ----------------------------------------------------

    @Test
    void nothing_is_said_while_rent_is_still_far_off() throws Exception {
        letStartingIn(20);

        run();
        assertNoReminders();
    }

    @Test
    void a_tenant_is_told_five_days_before_rent_falls_due() throws Exception {
        letStartingIn(5);

        run();

        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isEqualTo(1);
        org.assertj.core.api.Assertions.assertThat(lastReminderType())
                .isEqualTo("RENT_DUE_REMINDER");
        org.assertj.core.api.Assertions.assertThat(
                        mine().andReturn().getResponse().getContentAsString())
                .contains("2500");
    }

    /**
     * Repeating it before the due date has even arrived would be nagging about
     * something nobody is late for.
     */
    @Test
    void the_reminder_is_said_once() throws Exception {
        letStartingIn(5);

        run();
        run();
        clock.advanceDays(2);
        run();

        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isEqualTo(1);
    }

    // ---- rent late ---------------------------------------------------------

    @Test
    void a_late_tenant_is_told_so() throws Exception {
        let(LocalDate.now(clock));
        clock.advanceDays(3);

        run();

        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isEqualTo(1);
        org.assertj.core.api.Assertions.assertThat(lastReminderType())
                .isEqualTo("RENT_OVERDUE");
    }

    /**
     * The retry case. Scheduler retries a failed run three times, and four
     * identical messages for one late month is how somebody learns to ignore
     * the bell.
     */
    @Test
    void running_it_four_times_in_a_row_says_it_once() throws Exception {
        let(LocalDate.now(clock));
        clock.advanceDays(3);

        run();
        run();
        run();
        run();

        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isEqualTo(1);
    }

    @Test
    void it_is_said_again_a_week_later() throws Exception {
        let(LocalDate.now(clock));
        clock.advanceDays(3);
        run();
        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isEqualTo(1);

        // Six days on, still inside the week.
        clock.advanceDays(6);
        run();
        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isEqualTo(1);

        clock.advanceDays(2);
        run();
        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isEqualTo(2);
    }

    @Test
    void a_paid_month_is_not_chased() throws Exception {
        letWithAdvance(LocalDate.now(clock));
        clock.advanceDays(3);

        run();
        assertNoReminders();
    }

    /**
     * Paying stops the chasing. Without this a tenant who settled up on the
     * day would still be told off a week later.
     */
    @Test
    void paying_stops_the_reminders() throws Exception {
        String lease = let(LocalDate.now(clock));
        clock.advanceDays(3);
        run();

        String period = json.readTree(mvc.perform(
                        get("/api/v1/leases/" + lease + "/billing")
                                .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();

        mvc.perform(post("/api/v1/leases/" + lease + "/payments")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"billingPeriodId":"%s","amountPaid":2500.00,
                                 "paymentMethod":"CASH"}
                                """.formatted(period)))
                .andExpect(status().isCreated());

        clock.advanceDays(10);
        run();

        // Still the one reminder from before they paid.
        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isEqualTo(1);
    }

    /**
     * A former tenant is not chased for a room they left. Nothing else stops
     * this: the periods are still there.
     */
    @Test
    void an_ended_tenancy_is_not_chased() throws Exception {
        String lease = let(LocalDate.now(clock));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\"}".formatted(LocalDate.now(clock))))
                .andExpect(status().isOk());

        clock.advanceDays(30);

        run();
        assertNoReminders();
    }

    /** No threat and no penalty: Lizmo does not know what these two agreed. */
    @Test
    void the_overdue_message_invents_no_consequences() throws Exception {
        let(LocalDate.now(clock));
        clock.advanceDays(3);
        run();

        String body = mine().andReturn().getResponse().getContentAsString();
        org.assertj.core.api.Assertions.assertThat(body)
                .doesNotContainIgnoringCase("penalty")
                .doesNotContainIgnoringCase("evict")
                .doesNotContainIgnoringCase("legal");
    }

    // ---- fixtures ----------------------------------------------------------

    /**
     * Runs the job.
     *
     * <p>Deliberately returns nothing. The job's own count is across every
     * landlord in the database, and every test class shares one -- asserting
     * on it would tally reminders sent to tenants left behind by other tests
     * and say nothing about this one. The suite has made that mistake before.
     */
    private void run() throws Exception {
        mvc.perform(post("/internal/jobs/rent-reminders")
                        .header("Authorization", "Bearer " + TestJobAuthoriser.PASSWORD))
                .andExpect(status().isOk());
    }

    /**
     * How many rent reminders this test's own tenant has been sent.
     *
     * <p>Filtered by type, because accepting the request already put a
     * REQUEST_ACCEPTED in Ana's bell -- she is never at zero notifications,
     * and a bare count would say the job had fired when it had not.
     */
    private int remindersToAna() throws Exception {
        var all = json.readTree(mine().andReturn().getResponse().getContentAsString());
        int reminders = 0;
        for (var one : all) {
            String type = one.get("type").asText();
            if (type.equals("RENT_DUE_REMINDER") || type.equals("RENT_OVERDUE")) {
                reminders++;
            }
        }
        return reminders;
    }

    /** The most recent reminder's type, for the tests that care which it was. */
    private String lastReminderType() throws Exception {
        var all = json.readTree(mine().andReturn().getResponse().getContentAsString());
        for (var one : all) {
            String type = one.get("type").asText();
            if (type.equals("RENT_DUE_REMINDER") || type.equals("RENT_OVERDUE")) {
                return type;
            }
        }
        return null;
    }

    private ResultActions mine() throws Exception {
        return mvc.perform(get("/api/v1/me/notifications")
                .header("Authorization", "Bearer " + anaToken));
    }

    private void assertNoReminders() throws Exception {
        org.assertj.core.api.Assertions.assertThat(remindersToAna()).isZero();
    }

    /**
     * A tenancy whose rent falls due in {@code days}. The due day defaults to
     * the start day, so a lease starting then is due then.
     */
    private void letStartingIn(int days) throws Exception {
        let(LocalDate.now(clock).plusDays(days));
    }

    private String let(LocalDate start) throws Exception {
        return letWith(start, null);
    }

    private String letWithAdvance(LocalDate start) throws Exception {
        return letWith(start, "\"advanceAmount\":2500.00");
    }

    private String letWith(LocalDate start, String extra) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bed = json.readTree(beds).get(0).get("id").asText();

        String request = mvc.perform(post("/api/v1/me/rental-requests")
                        .header("Authorization", "Bearer " + anaToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bed)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String lease = mvc.perform(post("/api/v1/rental-requests/"
                        + json.readTree(request).get("id").asText() + "/accept")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rentAmount\":2500.00,\"startDate\":\"%s\"%s}"
                                .formatted(start, extra == null ? "" : "," + extra)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        String id = json.readTree(lease).get("id").asText();

        // The schedule is written when somebody looks, and the job reads what
        // is there rather than creating it -- a reminder for a month nobody
        // has generated would be a reminder about nothing.
        mvc.perform(get("/api/v1/leases/" + id + "/billing")
                .header("Authorization", "Bearer " + landlordToken));
        return id;
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
