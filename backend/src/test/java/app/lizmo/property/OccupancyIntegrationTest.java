package app.lizmo.property;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * What is let, what is empty, and what the empty part is costing.
 *
 * <p>Counted in lettable slots rather than units, which is the whole of what
 * makes this worth testing: a four-bed room with one tenant is one let and
 * three empty, and any arithmetic that calls it "one unit occupied" tells a
 * landlord their building is full.
 */
class OccupancyIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String anaToken;
    private String beaToken;

    private String propertyId;

    @BeforeEach
    void setUp() throws Exception {
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
        propertyId = json.readTree(property).get("id").asText();

        makeReadyForALease(anaToken);
        makeReadyForALease(beaToken);
    }

    // ---- counting ----------------------------------------------------------

    @Test
    void a_landlord_with_nothing_has_nothing_to_let() throws Exception {
        occupancy()
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lettable").value(0))
                .andExpect(jsonPath("$.empty").value(0))
                .andExpect(jsonPath("$.vacancies.length()").value(0));
    }

    /** Four beds is four slots, not one unit. */
    @Test
    void a_bedspace_room_counts_by_the_bed() throws Exception {
        addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":4,"rent":2500.00}
                """);

        occupancy()
                .andExpect(jsonPath("$.lettable").value(4))
                .andExpect(jsonPath("$.occupied").value(0))
                .andExpect(jsonPath("$.empty").value(4))
                .andExpect(jsonPath("$.emptyRent").value(10000.00));
    }

    @Test
    void a_whole_unit_is_one_slot_however_many_rooms() throws Exception {
        addUnit("""
                {"unitNumber":"101","floor":"1","rentalMode":"WHOLE_UNIT","rent":12000.00}
                """);

        occupancy()
                .andExpect(jsonPath("$.lettable").value(1))
                .andExpect(jsonPath("$.empty").value(1))
                .andExpect(jsonPath("$.emptyRent").value(12000.00));
    }

    /**
     * The arithmetic this whole endpoint exists to get right. One tenant in a
     * four-bed room is not a full building.
     */
    @Test
    void one_tenant_in_a_four_bed_room_leaves_three_empty() throws Exception {
        String unit = addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":4,"rent":2500.00}
                """);
        let(anaToken, unit, 0);

        occupancy()
                .andExpect(jsonPath("$.lettable").value(4))
                .andExpect(jsonPath("$.occupied").value(1))
                .andExpect(jsonPath("$.empty").value(3))
                .andExpect(jsonPath("$.earningRent").value(2500.00))
                .andExpect(jsonPath("$.emptyRent").value(7500.00));
    }

    @Test
    void beds_and_whole_units_add_together() throws Exception {
        String room = addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":2,"rent":2500.00}
                """);
        addUnit("""
                {"unitNumber":"101","floor":"1","rentalMode":"WHOLE_UNIT","rent":12000.00}
                """);
        let(anaToken, room, 0);

        occupancy()
                .andExpect(jsonPath("$.lettable").value(3))
                .andExpect(jsonPath("$.occupied").value(1))
                .andExpect(jsonPath("$.empty").value(2));
    }

    /**
     * A bed taken off the market on purpose is not a vacancy anybody needs to
     * fill, and folding the two together would make a refurbishment look like
     * a failure to let.
     */
    @Test
    void a_room_out_of_service_is_not_a_vacancy() throws Exception {
        String unit = addUnit("""
                {"unitNumber":"101","floor":"1","rentalMode":"WHOLE_UNIT","rent":12000.00}
                """);

        // The dedicated endpoint, not the general update: taking a unit out
        // of service is its own act and is refused while somebody lives there.
        mvc.perform(put("/api/v1/units/" + unit + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"underMaintenance\":true}"))
                .andExpect(status().isOk());

        occupancy()
                .andExpect(jsonPath("$.outOfService").value(1))
                .andExpect(jsonPath("$.empty").value(0))
                .andExpect(jsonPath("$.lettable").value(0))
                .andExpect(jsonPath("$.emptyRent").value(0));
    }

    // ---- where the vacancy is ----------------------------------------------

    @Test
    void a_full_property_is_not_listed_as_a_vacancy() throws Exception {
        String unit = addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":1,"rent":2500.00}
                """);
        let(anaToken, unit, 0);

        occupancy()
                .andExpect(jsonPath("$.occupied").value(1))
                .andExpect(jsonPath("$.vacancies.length()").value(0));
    }

    @Test
    void a_property_with_space_says_how_much_it_is_not_earning()
            throws Exception {
        addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":3,"rent":2500.00}
                """);

        occupancy()
                .andExpect(jsonPath("$.vacancies.length()").value(1))
                .andExpect(jsonPath("$.vacancies[0].propertyName")
                        .value("Sunrise Apartments"))
                .andExpect(jsonPath("$.vacancies[0].empty").value(3))
                .andExpect(jsonPath("$.vacancies[0].emptyRent").value(7500.00));
    }

    /** The property costing most to leave alone comes first. */
    @Test
    void the_emptiest_money_is_listed_first() throws Exception {
        addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":1,"rent":2500.00}
                """);

        String second = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Aabra Residences","address":"9 Rizal Ave",
                                 "type":"APARTMENT","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        mvc.perform(post("/api/v1/properties/"
                        + json.readTree(second).get("id").asText() + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","floor":"1",
                                 "rentalMode":"WHOLE_UNIT","rent":20000.00}
                                """))
                .andExpect(status().isCreated());

        // Alphabetically Aabra sorts first, so a list ordered by name would
        // pass this by accident. It is ordered by money.
        occupancy()
                .andExpect(jsonPath("$.vacancies[0].propertyName")
                        .value("Aabra Residences"))
                .andExpect(jsonPath("$.vacancies[1].propertyName")
                        .value("Sunrise Apartments"));
    }

    @Test
    void a_bed_freed_by_ending_a_tenancy_is_empty_again() throws Exception {
        String unit = addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":2,"rent":2500.00}
                """);
        String lease = let(anaToken, unit, 0);
        occupancy().andExpect(jsonPath("$.occupied").value(1));

        mvc.perform(post("/api/v1/leases/" + lease + "/end")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());

        occupancy()
                .andExpect(jsonPath("$.occupied").value(0))
                .andExpect(jsonPath("$.empty").value(2));
    }

    @Test
    void another_landlord_sees_their_own() throws Exception {
        addUnit("""
                {"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE",
                 "capacity":4,"rent":2500.00}
                """);

        mvc.perform(get("/api/v1/me/occupancy")
                        .header("Authorization", "Bearer " + accounts.landlord("mario").token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lettable").value(0));
    }

    // ---- fixtures ----------------------------------------------------------

    private ResultActions occupancy() throws Exception {
        return mvc.perform(get("/api/v1/me/occupancy")
                .header("Authorization", "Bearer " + landlordToken));
    }

    private String addUnit(String body) throws Exception {
        String created = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(created).get("id").asText();
    }

    /** @return the lease id */
    private String let(String tenantToken, String unitId, int bedIndex) throws Exception {
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
                        .content("{\"rentAmount\":2500.00,\"startDate\":\"%s\"}"
                                .formatted(LocalDate.now())))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
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
