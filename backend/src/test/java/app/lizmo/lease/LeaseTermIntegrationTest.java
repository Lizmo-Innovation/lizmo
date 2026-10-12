package app.lizmo.lease;

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
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * When a lease is meant to end, and warning both of them as it nears.
 *
 * <p>Month to month is the usual case here, so most leases have no end date
 * and are never warned about. One agreed for a term is warned a month out and
 * in the last week, to both sides; once the date has gone by with nothing
 * done, to the landlord alone. Passing it ends nothing.
 */
class LeaseTermIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private Accounts.Account elena;
    private Accounts.Account ana;
    private String propertyId;
    private String unitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();
        elena = accounts.landlord("elena");
        ana = accounts.tenant("ana");

        String property = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        propertyId = json.readTree(property).get("id").asText();
        String unit = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + elena.token())
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

    // ---- the date itself ---------------------------------------------------

    @Test
    void a_lease_is_month_to_month_unless_given_an_end() throws Exception {
        String lease = let(null);

        mvc.perform(get("/api/v1/me/leases").header("Authorization", "Bearer " + ana.token()))
                .andExpect(jsonPath("$[0].id").value(lease))
                .andExpect(jsonPath("$[0].termEndsOn").doesNotExist());
    }

    @Test
    void a_lease_can_be_written_for_a_term() throws Exception {
        LocalDate ends = today().plusYears(1);
        let(ends);

        mvc.perform(get("/api/v1/me/leases").header("Authorization", "Bearer " + ana.token()))
                .andExpect(jsonPath("$[0].termEndsOn").value(ends.toString()))
                // Not the date it ended: it has not.
                .andExpect(jsonPath("$[0].endDate").doesNotExist())
                .andExpect(jsonPath("$[0].status").value("ACTIVE"));
    }

    @Test
    void a_term_cannot_end_before_it_starts() throws Exception {
        String thread = askAbout(ana.token(), propertyId);
        String bed = json.readTree(mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();

        mvc.perform(post("/api/v1/inquiries/" + thread + "/lease")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(("{\"unitId\":\"%s\",\"bedId\":\"%s\","
                                + "\"startDate\":\"%s\",\"endsOn\":\"%s\"}")
                                .formatted(unitId, bed, today(), today())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("The lease has to end after it starts."));
    }

    @Test
    void the_landlord_can_set_one_later() throws Exception {
        String lease = let(null);
        LocalDate ends = today().plusMonths(6);

        setTerm(elena, lease, ends)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.termEndsOn").value(ends.toString()));

        assertThat(titlesTo(ana)).contains("Your lease has an end date");
    }

    /** Extending is the answer to "can I stay?", and the tenant is told it. */
    @Test
    void a_later_date_extends_it_and_the_tenant_is_told() throws Exception {
        String lease = let(today().plusMonths(6));

        setTerm(elena, lease, today().plusMonths(18)).andExpect(status().isOk());

        assertThat(titlesTo(ana)).contains("Your lease was extended");
        assertThat(messagesTo(ana)).anyMatch(message -> message.contains("now runs until"));
    }

    @Test
    void the_end_date_can_be_taken_away() throws Exception {
        String lease = let(today().plusMonths(6));

        setTerm(elena, lease, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.termEndsOn").doesNotExist());

        assertThat(titlesTo(ana)).contains("Your lease no longer has an end date");
    }

    /** Somebody who has already gone is ended, which frees the room. */
    @Test
    void a_date_already_gone_is_refused() throws Exception {
        String lease = let(null);
        clock.advanceDays(10);

        setTerm(elena, lease, today().minusDays(1)).andExpect(status().isBadRequest());
    }

    @Test
    void the_same_date_again_tells_nobody_anything() throws Exception {
        LocalDate ends = today().plusMonths(6);
        String lease = let(ends);
        int before = titlesTo(ana).size();

        setTerm(elena, lease, ends).andExpect(status().isOk());

        assertThat(titlesTo(ana)).hasSize(before);
    }

    @Test
    void only_the_landlord_can_change_it() throws Exception {
        String lease = let(null);
        Accounts.Account stranger = accounts.landlord("mario");

        setTerm(ana, lease, today().plusYears(1)).andExpect(status().isNotFound());
        setTerm(stranger, lease, today().plusYears(1)).andExpect(status().isNotFound());
    }

    @Test
    void an_ended_tenancy_has_no_term_to_change() throws Exception {
        String lease = let(null);
        end(lease);

        setTerm(elena, lease, today().plusYears(1)).andExpect(status().isBadRequest());
    }

    // ---- the warnings ------------------------------------------------------

    @Test
    void month_to_month_is_never_warned_about() throws Exception {
        let(null);

        run();

        assertThat(warningsTo(ana)).isEmpty();
        assertThat(warningsTo(elena)).isEmpty();
    }

    @Test
    void nothing_is_said_while_the_end_is_far_off() throws Exception {
        let(today().plusDays(31));

        run();

        assertThat(warningsTo(ana)).isEmpty();
    }

    @Test
    void both_are_told_a_month_out() throws Exception {
        LocalDate ends = today().plusDays(30);
        let(ends);

        run();

        assertThat(warningsTo(ana)).containsExactly("Your lease ends in 30 days");
        assertThat(warningsTo(elena)).containsExactly("A lease ends in 30 days");
        assertThat(messagesTo(ana)).anyMatch(message -> message.contains(
                LeaseDates.spoken(ends)) && message.contains("Sunrise Apartments"));
        // The room, not her name: it is read on a lock screen.
        assertThat(messagesTo(elena)).anyMatch(message -> message.contains("Bed")
                && message.contains("2B") && !message.contains("ana"));
    }

    /** Cloud Scheduler retries a failed run; a warning must not go four times. */
    @Test
    void each_warning_is_said_once() throws Exception {
        let(today().plusDays(30));

        run();
        run();
        clock.advanceDays(1);
        run();

        assertThat(warningsTo(ana)).hasSize(1);
        assertThat(warningsTo(elena)).hasSize(1);
    }

    @Test
    void and_again_in_the_last_week() throws Exception {
        let(today().plusDays(30));
        run();

        clock.advanceDays(23);
        run();

        assertThat(warningsTo(ana))
                .containsExactly("Your lease ends in 7 days", "Your lease ends in 30 days");
        assertThat(warningsTo(elena)).hasSize(2);
    }

    /** Set five days out, a month's warning would be stale before it was read. */
    @Test
    void a_date_set_close_goes_straight_to_the_last_week() throws Exception {
        let(today().plusDays(5));

        run();

        assertThat(warningsTo(ana)).containsExactly("Your lease ends in 5 days");
    }

    @Test
    void the_day_before_says_tomorrow() throws Exception {
        let(today().plusDays(1));
        run();
        clock.advanceDays(1);

        // Already warned for the week: the day itself adds nothing new.
        run();
        assertThat(warningsTo(ana)).containsExactly("Your lease ends tomorrow");
    }

    /**
     * Nothing ends on its own: somebody may still be sleeping in the bed. The
     * landlord alone is asked to say which.
     */
    @Test
    void once_it_has_gone_by_the_landlord_is_asked_to_act() throws Exception {
        String lease = let(today().plusDays(5));
        run();

        clock.advanceDays(6);
        run();
        run();

        assertThat(warningsTo(elena)).containsExactly(
                "A lease has reached its end date", "A lease ends in 5 days");
        assertThat(warningsTo(ana)).containsExactly("Your lease ends in 5 days");

        mvc.perform(get("/api/v1/me/leases").header("Authorization", "Bearer " + ana.token()))
                .andExpect(jsonPath("$[0].id").value(lease))
                .andExpect(jsonPath("$[0].status").value("ACTIVE"));
    }

    /** An extended lease is warned about again, a year from now. */
    @Test
    void extending_starts_the_warnings_over() throws Exception {
        String lease = let(today().plusDays(5));
        run();

        LocalDate later = today().plusDays(40);
        setTerm(elena, lease, later).andExpect(status().isOk());
        run();
        assertThat(warningsTo(ana)).containsExactly("Your lease ends in 5 days");

        clock.advanceDays(10);
        run();
        assertThat(warningsTo(ana))
                .containsExactly("Your lease ends in 30 days", "Your lease ends in 5 days");
    }

    @Test
    void an_ended_tenancy_is_not_warned_about() throws Exception {
        String lease = let(today().plusDays(30));
        end(lease);

        run();

        assertThat(warningsTo(ana)).isEmpty();
        assertThat(warningsTo(elena)).isEmpty();
    }

    // ---- fixtures ----------------------------------------------------------

    private LocalDate today() {
        return LocalDate.now(clock);
    }

    /** A bed for Ana from today, ending when given, or month to month. */
    private String let(LocalDate endsOn) throws Exception {
        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString();
        String lease = letRoom(
                elena.token(),
                ana.token(),
                "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(
                        unitId, json.readTree(beds).get(0).get("id").asText()),
                endsOn == null
                        ? "{\"startDate\":\"%s\"}".formatted(today())
                        : "{\"startDate\":\"%s\",\"endsOn\":\"%s\"}".formatted(today(), endsOn));
        return json.readTree(lease).get("id").asText();
    }

    private ResultActions setTerm(Accounts.Account who, String lease, LocalDate endsOn)
            throws Exception {
        return mvc.perform(put("/api/v1/leases/" + lease + "/term")
                .header("Authorization", "Bearer " + who.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(endsOn == null
                        ? "{\"endsOn\":null}"
                        : "{\"endsOn\":\"%s\"}".formatted(endsOn)));
    }

    private void end(String lease) throws Exception {
        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"endDate\":\"%s\"}".formatted(today())))
                .andExpect(status().isOk());
    }

    private void run() throws Exception {
        mvc.perform(post("/internal/jobs/rent-reminders")
                        .header("Authorization", "Bearer " + TestJobAuthoriser.PASSWORD))
                .andExpect(status().isOk());
    }

    /** Warnings about the end, newest first -- not the changes to it. */
    private List<String> warningsTo(Accounts.Account who) throws Exception {
        return titles(who, true);
    }

    private List<String> titlesTo(Accounts.Account who) throws Exception {
        return titles(who, false);
    }

    private List<String> titles(Accounts.Account who, boolean warningsOnly) throws Exception {
        List<String> titles = new ArrayList<>();
        for (var one : notifications(who)) {
            String title = one.get("title").asText();
            boolean warning = title.contains(" ends ") || title.contains("reached its end");
            if (one.get("type").asText().equals("LEASE_EXPIRING") && (warning || !warningsOnly)) {
                titles.add(title);
            }
        }
        return titles;
    }

    private List<String> messagesTo(Accounts.Account who) throws Exception {
        List<String> messages = new ArrayList<>();
        for (var one : notifications(who)) {
            if (one.get("type").asText().equals("LEASE_EXPIRING")) {
                messages.add(one.get("message").asText());
            }
        }
        return messages;
    }

    private com.fasterxml.jackson.databind.JsonNode notifications(Accounts.Account who)
            throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + who.token()))
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
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
