package app.lizmo.maintenance;

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
 * Reporting something broken, and following what happens to it.
 *
 * <p>The spec calls a report the landlord never sees a suggestion box. These
 * tests are about the conversation reaching the other side at every step, the
 * last word on "fixed" being the tenant's, and nobody reading a report that is
 * not theirs.
 */
class MaintenanceIntegrationTest extends IntegrationTest {

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

    // ---- reporting ---------------------------------------------------------------

    @Test
    void a_tenant_reports_something_and_the_landlord_sees_it() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The tap will not stop dripping.");

        mvc.perform(get("/api/v1/me/maintenance")
                        .header("Authorization", "Bearer " + anaToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(report))
                .andExpect(jsonPath("$[0].status").value("SUBMITTED"))
                .andExpect(jsonPath("$[0].reopened").value(false));

        mvc.perform(get("/api/v1/maintenance")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].description").value("The tap will not stop dripping."))
                .andExpect(jsonPath("$[0].tenantName").value("ana"))
                .andExpect(jsonPath("$[0].propertyName").value("Sunrise Apartments"))
                .andExpect(jsonPath("$[0].unitNumber").value("2B"))
                .andExpect(jsonPath("$[0].bedLabel").isNotEmpty());
    }

    /** A report the landlord never hears about is a suggestion box. */
    @Test
    void the_landlord_is_told_something_was_reported() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The tap will not stop dripping.");

        assertThat(notificationsAbout(landlordToken, report, "MAINTENANCE_REPORTED")).isEqualTo(1);
    }

    @Test
    void somebody_with_no_tenancy_has_nothing_to_report_on() throws Exception {
        reportCall(beaToken, "The tap.").andExpect(status().isBadRequest());
    }

    @Test
    void a_report_has_to_say_something() throws Exception {
        let(anaToken, 0);
        reportCall(anaToken, "   ").andExpect(status().isBadRequest());
    }

    // ---- photos ---------------------------------------------------------------------

    @Test
    void up_to_three_photos_and_no_more() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "Water on the floor.");

        for (int i = 0; i < 3; i++) {
            addPhoto(anaToken, report).andExpect(status().isCreated());
        }
        addPhoto(anaToken, report).andExpect(status().isBadRequest());

        mvc.perform(get("/api/v1/maintenance/" + report)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.photoUrls.length()").value(3));
    }

    /** Once somebody is working from what was sent, what was sent stops changing. */
    @Test
    void photos_only_before_work_starts() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "Water on the floor.");
        landlord(report, "start", null).andExpect(status().isOk());

        addPhoto(anaToken, report).andExpect(status().isBadRequest());
    }

    // ---- whose it is -------------------------------------------------------------------

    @Test
    void another_tenant_can_neither_see_nor_touch_it() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The tap.");

        mvc.perform(get("/api/v1/me/maintenance")
                        .header("Authorization", "Bearer " + beaToken))
                .andExpect(jsonPath("$.length()").value(0));
        tenant(beaToken, report, "withdraw", null).andExpect(status().isNotFound());
        addPhoto(beaToken, report).andExpect(status().isNotFound());
    }

    @Test
    void another_landlord_can_neither_see_nor_touch_it() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The tap.");

        mvc.perform(get("/api/v1/maintenance")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(jsonPath("$.length()").value(0));
        mvc.perform(get("/api/v1/maintenance/" + report)
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/maintenance/" + report + "/start")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    // ---- withdrawing ---------------------------------------------------------------------

    @Test
    void a_report_nobody_has_started_on_can_be_taken_back() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The tap fixed itself.");

        tenant(anaToken, report, "withdraw", null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("WITHDRAWN"));

        // Kept, not deleted: the landlord saw it arrive and can see it go.
        mvc.perform(get("/api/v1/maintenance")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].status").value("WITHDRAWN"));
    }

    @Test
    void once_work_has_started_it_cannot_be_taken_back() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The tap.");
        landlord(report, "start", null).andExpect(status().isOk());

        tenant(anaToken, report, "withdraw", null).andExpect(status().isBadRequest());
    }

    // ---- the landlord dealing with it -------------------------------------------------------

    @Test
    void the_landlord_moves_it_along_and_the_tenant_is_told_each_time() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The tap.");

        landlord(report, "start", "The plumber comes Saturday.")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"))
                .andExpect(jsonPath("$.landlordRemarks").value("The plumber comes Saturday."));

        landlord(report, "resolve", "New washer fitted.")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RESOLVED"))
                .andExpect(jsonPath("$.landlordRemarks").value("New washer fitted."))
                .andExpect(jsonPath("$.resolvedAt").isNotEmpty());

        assertThat(notificationsAbout(anaToken, report, "MAINTENANCE_STATUS_CHANGED")).isEqualTo(2);
    }

    /** Some things are fixed before anybody has formally started. */
    @Test
    void it_can_be_marked_fixed_straight_away() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The light.");

        landlord(report, "resolve", null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RESOLVED"));
    }

    @Test
    void something_already_fixed_cannot_be_fixed_again() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The light.");
        landlord(report, "resolve", null).andExpect(status().isOk());

        landlord(report, "resolve", null).andExpect(status().isBadRequest());
        landlord(report, "start", null).andExpect(status().isBadRequest());
    }

    // ---- the tenant has the last word -----------------------------------------------------

    @Test
    void the_tenant_closes_it_by_saying_it_is_fixed() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The light.");
        landlord(report, "resolve", null).andExpect(status().isOk());

        tenant(anaToken, report, "fixed", null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CLOSED"))
                .andExpect(jsonPath("$.closedAt").isNotEmpty());
    }

    /** A landlord saying it is fixed and it being fixed are different things. */
    @Test
    void still_broken_puts_it_back_in_front_of_the_landlord() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The light.");
        landlord(report, "resolve", null).andExpect(status().isOk());

        tenant(anaToken, report, "reopen", "It flickers again after an hour.")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUBMITTED"))
                .andExpect(jsonPath("$.reopened").value(true))
                .andExpect(jsonPath("$.reopenReason").value("It flickers again after an hour."));

        assertThat(notificationsAbout(landlordToken, report, "MAINTENANCE_STATUS_CHANGED"))
                .isEqualTo(1);
    }

    @Test
    void saying_it_is_still_broken_needs_a_reason() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The light.");
        landlord(report, "resolve", null).andExpect(status().isOk());

        tenant(anaToken, report, "reopen", "  ").andExpect(status().isBadRequest());
    }

    @Test
    void only_something_marked_fixed_can_be_closed_or_reopened() throws Exception {
        let(anaToken, 0);
        String report = report(anaToken, "The light.");

        tenant(anaToken, report, "fixed", null).andExpect(status().isBadRequest());
        tenant(anaToken, report, "reopen", "Still broken.").andExpect(status().isBadRequest());
    }

    @Test
    void reporting_requires_signing_in() throws Exception {
        mvc.perform(get("/api/v1/me/maintenance")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/maintenance")).andExpect(status().isUnauthorized());
    }

    // ---- fixtures -------------------------------------------------------------------------

    private ResultActions reportCall(String token, String description) throws Exception {
        return mvc.perform(post("/api/v1/me/maintenance")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(
                        java.util.Map.of("description", description))));
    }

    /** @return the report id */
    private String report(String token, String description) throws Exception {
        String body = reportCall(token, description)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("id").asText();
    }

    private ResultActions addPhoto(String token, String report) throws Exception {
        return mvc.perform(multipart("/api/v1/me/maintenance/" + report + "/photos")
                .file(new MockMultipartFile("photo", "p.jpg", "image/jpeg", photo()))
                .header("Authorization", "Bearer " + token));
    }

    private ResultActions tenant(String token, String report, String action, String text)
            throws Exception {
        var call = post("/api/v1/me/maintenance/" + report + "/" + action)
                .header("Authorization", "Bearer " + token);
        if (text != null) {
            call.contentType(MediaType.APPLICATION_JSON)
                    .content(json.writeValueAsString(java.util.Map.of("text", text)));
        }
        return mvc.perform(call);
    }

    private ResultActions landlord(String report, String action, String text) throws Exception {
        var call = post("/api/v1/maintenance/" + report + "/" + action)
                .header("Authorization", "Bearer " + landlordToken);
        if (text != null) {
            call.contentType(MediaType.APPLICATION_JSON)
                    .content(json.writeValueAsString(java.util.Map.of("text", text)));
        }
        return mvc.perform(call);
    }

    /** Scoped to the one report, so other tests' notifications never count. */
    private long notificationsAbout(String token, String report, String type) throws Exception {
        var feed = json.readTree(mvc.perform(get("/api/v1/me/notifications")
                        .header("Authorization", "Bearer " + token))
                .andReturn().getResponse().getContentAsString());
        long count = 0;
        for (var row : feed) {
            if (report.equals(row.path("relatedEntityId").asText())
                    && type.equals(row.path("type").asText())) {
                count++;
            }
        }
        return count;
    }

    private void let(String tenantToken, int bedIndex) throws Exception {
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

        mvc.perform(post("/api/v1/rental-requests/"
                        + json.readTree(request).get("id").asText() + "/accept")
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
