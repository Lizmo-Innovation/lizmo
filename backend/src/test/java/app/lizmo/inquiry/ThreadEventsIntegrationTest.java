package app.lizmo.inquiry;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.MutableClock;
import com.fasterxml.jackson.databind.JsonNode;
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
import org.springframework.mock.web.MockPart;

/**
 * What a conversation is told about its tenancy: the cards between the
 * messages, and the month the panel at the top is about.
 */
class ThreadEventsIntegrationTest extends IntegrationTest {

    @Autowired
    private MutableClock clock;

    private Accounts.Account elena;
    private Accounts.Account ana;
    private String propertyId;
    private String unitId;

    @BeforeEach
    void setUp() throws Exception {
        clock.reset();
        elena = accounts.landlord("Elena");
        ana = tenant("Ana");
        propertyId = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();
        unitId = json.readTree(mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                                 "capacity":2,"rent":2500.00}
                                """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();
    }

    @Test
    void before_a_lease_the_shared_id_is_the_only_card() throws Exception {
        String thread = ask();

        JsonNode read = thread(thread, elena);
        assertThat(kinds(read)).containsExactly("ID_SHARED");
        assertThat(read.get("rent").isNull()).isTrue();
    }

    @Test
    void the_lease_starting_is_a_card_for_both_sides() throws Exception {
        String lease = let(LocalDate.now(clock));
        String thread = threadOf(ana);

        assertThat(kinds(thread(thread, ana))).contains("LEASE_STARTED");
        JsonNode started = find(thread(thread, elena), "LEASE_STARTED");
        assertThat(started.get("entityId").asText()).isEqualTo(lease);
    }

    /** "I have paid", then what came of it: the same payment, twice. */
    @Test
    void a_payment_said_then_confirmed_reads_as_both() throws Exception {
        String lease = let(LocalDate.now(clock));
        String thread = threadOf(ana);
        String payment = declare(lease);

        JsonNode waiting = find(thread(thread, elena), "PAYMENT_REPORTED");
        assertThat(waiting.get("state").asText()).isEqualTo("PENDING_VERIFICATION");
        assertThat(waiting.get("entityId").asText()).isEqualTo(payment);

        mvc.perform(post("/api/v1/leases/" + lease + "/payments/" + payment + "/confirm")
                        .header("Authorization", "Bearer " + elena.token()))
                .andExpect(status().isOk());

        JsonNode after = thread(thread, ana);
        assertThat(find(after, "PAYMENT_REPORTED").get("state").asText()).isEqualTo("CONFIRMED");
        assertThat(find(after, "PAYMENT_CONFIRMED").get("receiptNumber").asText()).isNotBlank();
    }

    @Test
    void a_repair_is_a_card_with_where_it_stands() throws Exception {
        let(LocalDate.now(clock));
        String thread = threadOf(ana);
        mvc.perform(post("/api/v1/me/maintenance")
                        .header("Authorization", "Bearer " + ana.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"description\":\"The ceiling fan grinds and stops\"}"))
                .andExpect(status().isCreated());

        JsonNode repair = find(thread(thread, elena), "REPAIR_REPORTED");
        assertThat(repair.get("label").asText()).isEqualTo("The ceiling fan grinds and stops");
        assertThat(repair.get("state").asText()).isEqualTo("SUBMITTED");
    }

    /** The panel at the top is about the oldest month not paid. */
    @Test
    void a_current_tenancy_says_what_it_owes_next() throws Exception {
        let(LocalDate.now(clock).minusDays(12));
        String thread = threadOf(ana);

        JsonNode rent = thread(thread, ana).get("rent");
        assertThat(rent.get("outstanding").decimalValue()).isEqualByComparingTo("2500");
        assertThat(rent.get("overdue").asBoolean()).isTrue();
        assertThat(rent.get("billingPeriodId").asText()).isNotBlank();
    }

    @Test
    void the_cards_are_oldest_first() throws Exception {
        String lease = let(LocalDate.now(clock));
        String thread = threadOf(ana);
        clock.advanceDays(2);
        declare(lease);

        List<String> kinds = kinds(thread(thread, elena));
        assertThat(kinds.indexOf("LEASE_STARTED")).isLessThan(kinds.indexOf("PAYMENT_REPORTED"));
    }

    // ---- fixtures ----------------------------------------------------------

    private String ask() throws Exception {
        return json.readTree(mvc.perform(post("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + ana.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"propertyId\":\"%s\"}".formatted(propertyId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString())
                .get("inquiry").get("id").asText();
    }

    private String let(LocalDate start) throws Exception {
        String bed = json.readTree(mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();
        return json.readTree(letRoom(elena.token(), ana.token(),
                        "{\"unitId\":\"%s\",\"bedId\":\"%s\"}".formatted(unitId, bed),
                        "{\"startDate\":\"%s\"}".formatted(start)))
                .get("id").asText();
    }

    private String threadOf(Accounts.Account who) throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + who.token()))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();
    }

    private String declare(String lease) throws Exception {
        String month = json.readTree(mvc.perform(get("/api/v1/leases/" + lease + "/billing")
                        .header("Authorization", "Bearer " + elena.token()))
                .andReturn().getResponse().getContentAsString()).get(0).get("id").asText();
        return json.readTree(mvc.perform(multipart("/api/v1/me/leases/" + lease + "/payments")
                        .file(new MockMultipartFile("proof", "gcash.jpg", "image/jpeg", photo()))
                        .part(new MockPart("billingPeriodId", month.getBytes()))
                        .part(new MockPart("amountPaid", "2500".getBytes()))
                        .part(new MockPart("paymentMethod", "GCASH".getBytes()))
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();
    }

    private JsonNode thread(String id, Accounts.Account who) throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/inquiries/" + id)
                        .header("Authorization", "Bearer " + who.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private static List<String> kinds(JsonNode thread) {
        List<String> kinds = new ArrayList<>();
        for (JsonNode event : thread.get("events")) kinds.add(event.get("kind").asText());
        return kinds;
    }

    private static JsonNode find(JsonNode thread, String kind) {
        for (JsonNode event : thread.get("events")) {
            if (event.get("kind").asText().equals(kind)) return event;
        }
        throw new AssertionError("no " + kind + " in " + thread.get("events"));
    }

    private Accounts.Account tenant(String name) throws Exception {
        Accounts.Account tenant = accounts.tenant(name);
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenant.token())
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
                            .header("Authorization", "Bearer " + tenant.token()))
                    .andExpect(status().isCreated());
        }
        return tenant;
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(64, 64, BufferedImage.TYPE_INT_RGB);
        image.createGraphics().setColor(Color.GRAY);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }
}
