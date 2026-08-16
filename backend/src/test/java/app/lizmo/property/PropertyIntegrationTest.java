package app.lizmo.property;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Property, unit and bed endpoints against real Postgres.
 *
 * <p>The isolation tests matter most: a landlord seeing another landlord's
 * portfolio is the worst failure this API can have, and it is the kind of bug
 * that only appears once two accounts exist.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class PropertyIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("lizmo.jwt.secret", () -> "test-secret-that-is-long-enough-for-hmac-sha256-signing");
    }

    @Autowired
    MockMvc mvc;

    @Autowired
    ObjectMapper json;

    private String landlordToken;
    private String otherLandlordToken;
    private String tenantToken;

    @BeforeEach
    void signUpEveryone() throws Exception {
        landlordToken = register("elena", true);
        otherLandlordToken = register("rodel", true);
        tenantToken = register("ana", false);
    }

    private String register(String prefix, boolean asLandlord) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"%s","email":"%s%d@example.com",
                                 "password":"correct-horse-battery","asLandlord":%s}
                                """.formatted(prefix, prefix, System.nanoTime(), asLandlord)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("accessToken").asText();
    }

    private String createProperty(String token, String name) throws Exception {
        String body = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"%s","address":"12 Mabini St","type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """.formatted(name)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("id").asText();
    }

    private String createUnit(String token, String propertyId, String number, String mode, int capacity)
            throws Exception {
        String body = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"%s","rentalMode":"%s","capacity":%d}
                                """.formatted(number, mode, capacity)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("id").asText();
    }

    // ---------- Isolation ----------

    @Test
    void a_landlord_sees_only_their_own_properties() throws Exception {
        createProperty(landlordToken, "Sunrise Apartments");
        createProperty(otherLandlordToken, "Mercado Boarding House");

        mvc.perform(get("/api/v1/properties").header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("Sunrise Apartments"));
    }

    @Test
    void another_landlords_property_reads_as_missing_not_forbidden() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        // 404 rather than 403: a 403 would confirm the property exists, letting
        // one landlord enumerate a competitor's portfolio by trying ids.
        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("NOT_FOUND"));
    }

    @Test
    void another_landlord_cannot_modify_or_delete() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + otherLandlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Stolen","address":"Somewhere","type":"CONDO","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isNotFound());

        mvc.perform(delete("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void another_landlord_cannot_reach_units_or_beds() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        // Units carry no owner of their own, so this proves the hop through the
        // property is actually happening.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());

        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_create_properties() throws Exception {
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Not Mine","address":"12 Mabini St","type":"CONDO","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("FORBIDDEN"));
    }

    @Test
    void unauthenticated_requests_are_rejected() throws Exception {
        mvc.perform(get("/api/v1/properties"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHENTICATED"));
    }

    // ---------- Properties ----------

    @Test
    void creates_and_updates_a_property() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Residences","address":"14 Mabini St","type":"APARTMENT","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Sunrise Residences"))
                .andExpect(jsonPath("$.type").value("APARTMENT"));
    }

    @Test
    void rejects_a_property_without_a_name() throws Exception {
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"","address":"12 Mabini St","type":"CONDO","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fields.name").exists());
    }

    @Test
    void a_property_with_units_cannot_be_deleted() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        createUnit(landlordToken, propertyId, "2B", "WHOLE_UNIT", 1);

        // Deleting would strand the units' leases and billing history.
        mvc.perform(delete("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("units")));
    }

    // ---------- Units ----------

    @Test
    void unit_numbers_are_unique_within_a_property() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2b","rentalMode":"BEDSPACE","capacity":2}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void the_same_unit_number_is_fine_in_a_different_property() throws Exception {
        String first = createProperty(landlordToken, "Sunrise Apartments");
        String second = createProperty(landlordToken, "Sunset Apartments");

        createUnit(landlordToken, first, "2B", "WHOLE_UNIT", 1);
        createUnit(landlordToken, second, "2B", "WHOLE_UNIT", 1);
    }

    @Test
    void rental_mode_cannot_be_changed_after_creation() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        // Switching would orphan the beds or the unit's own lease.
        mvc.perform(put("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"WHOLE_UNIT","capacity":1}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("rental mode")));
    }

    @Test
    void whole_units_report_capacity_one_whatever_was_sent() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","rentalMode":"WHOLE_UNIT","capacity":6}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.capacity").value(1));
    }

    @Test
    void an_empty_unit_can_be_deleted() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "WHOLE_UNIT", 1);

        mvc.perform(delete("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());

        // The property survives, and stops counting the unit.
        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.unitCount").value(0));
    }

    @Test
    void a_unit_with_beds_cannot_be_deleted() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1"}
                                """))
                .andExpect(status().isCreated());

        // Deleting would strand the bed's occupancy and billing history.
        mvc.perform(delete("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("beds")));

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());
    }

    @Test
    void another_landlord_cannot_delete_a_unit() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "WHOLE_UNIT", 1);

        // 404 rather than 403, so this does not confirm the unit exists.
        mvc.perform(delete("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk());
    }

    // ---------- Beds ----------

    @Test
    void beds_can_be_added_to_a_bedspace_unit() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 3);

        for (String label : new String[] {"Bed 1", "Bed 2", "Bed 3"}) {
            mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                            .header("Authorization", "Bearer " + landlordToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"bedLabel":"%s"}
                                    """.formatted(label)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.status").value("VACANT"));
        }

        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3));
    }

    @Test
    void beds_cannot_be_added_to_a_whole_unit() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "1A", "WHOLE_UNIT", 1);

        // The unit itself is the lettable thing; a bed lease would compete with
        // the unit's own.
        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("bedspace")));
    }

    @Test
    void beds_cannot_exceed_capacity() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 1);

        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1"}
                                """))
                .andExpect(status().isCreated());

        // Capacity is what the landlord said the room holds; silently exceeding
        // it would inflate the platform bill too.
        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 2"}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void bed_labels_are_unique_within_a_unit() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1"}
                                """))
                .andExpect(status().isCreated());

        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"bed 1"}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void capacity_cannot_drop_below_the_beds_already_defined() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 3);

        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1"}
                                """))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 2"}
                                """))
                .andExpect(status().isCreated());

        mvc.perform(put("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":1}
                                """))
                .andExpect(status().isBadRequest());
    }

    // ---------- Unit rent ----------

    @Test
    void a_unit_can_carry_its_asking_rent() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":4,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.rent").value(2500.00));
    }

    @Test
    void rent_is_optional_and_stays_null_rather_than_zero() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        // A landlord may set a unit up before deciding what to charge. Zero
        // would read as free, which is a different claim from "not decided".
        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","rentalMode":"WHOLE_UNIT"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.rent").doesNotExist());
    }

    @Test
    void rent_must_be_positive() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":2,"rent":0}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void rent_can_be_changed_without_touching_anything_else() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        // Raising the asking price is routine; it must not disturb the unit's
        // identity or mode.
        mvc.perform(put("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":4,"rent":2750.50}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rent").value(2750.50))
                .andExpect(jsonPath("$.unitNumber").value("2B"))
                .andExpect(jsonPath("$.rentalMode").value("BEDSPACE"));
    }

    // ---------- Residential vs commercial ----------

    @Test
    void a_property_is_residential_or_commercial() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usage").value("RESIDENTIAL"));
    }

    @Test
    void a_commercial_property_can_be_created() throws Exception {
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Mabini Arcade","address":"14 Mabini St","type":"RETAIL_SPACE","usage":"COMMERCIAL"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.usage").value("COMMERCIAL"))
                .andExpect(jsonPath("$.type").value("RETAIL_SPACE"));
    }

    @Test
    void a_type_from_the_wrong_usage_is_refused() throws Exception {
        // A commercial boarding house is not a thing. The database says so too,
        // in chk_properties_usage_type; this proves the caller gets a message
        // rather than a constraint violation.
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Nonsense","address":"14 Mabini St","type":"BOARDING_HOUSE","usage":"COMMERCIAL"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("commercial")));

        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Nonsense","address":"14 Mabini St","type":"WAREHOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void usage_is_required() throws Exception {
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St","type":"CONDO"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields.usage").exists());
    }

    @Test
    void a_property_can_be_converted_to_commercial() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        // Conversions happen, so this is not locked the way rental mode is --
        // but the type has to move with it.
        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Mabini Arcade","address":"12 Mabini St","type":"OFFICE","usage":"COMMERCIAL"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usage").value("COMMERCIAL"))
                .andExpect(jsonPath("$.type").value("OFFICE"));
    }

    @Test
    void converting_without_moving_the_type_is_refused() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St","type":"BOARDING_HOUSE","usage":"COMMERCIAL"}
                                """))
                .andExpect(status().isBadRequest());

        // Unchanged.
        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.usage").value("RESIDENTIAL"));
    }

    @Test
    void a_unit_in_a_commercial_property_is_always_a_whole_unit() throws Exception {
        String body = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Mabini Arcade","address":"14 Mabini St","type":"RETAIL_SPACE","usage":"COMMERCIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String propertyId = json.readTree(body).get("id").asText();

        // BEDSPACE is coerced rather than refused -- a shop cannot be let by the
        // bed, and the request is answerable without an error.
        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"Stall 1","rentalMode":"BEDSPACE","capacity":6}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.rentalMode").value("WHOLE_UNIT"))
                // Capacity follows the coerced mode, not the 6 that was sent.
                .andExpect(jsonPath("$.capacity").value(1));
    }

    @Test
    void beds_cannot_be_added_in_a_commercial_property() throws Exception {
        String body = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Mabini Arcade","address":"14 Mabini St","type":"WAREHOUSE","usage":"COMMERCIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String propertyId = json.readTree(body).get("id").asText();

        String unitId = createUnit(landlordToken, propertyId, "Bay 1", "BEDSPACE", 4);

        // Falls out of the coercion: the unit is a whole unit, and whole units
        // refuse beds.
        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1"}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void a_property_with_bedspace_units_cannot_be_converted_to_commercial() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        // A unit's rental mode cannot change after creation, so converting would
        // strand the bedspace unit in a state nothing else allows.
        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Mabini Arcade","address":"12 Mabini St","type":"OFFICE","usage":"COMMERCIAL"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("bedspace")));
    }

    @Test
    void a_property_with_only_whole_units_can_still_be_converted() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        createUnit(landlordToken, propertyId, "2B", "WHOLE_UNIT", 1);

        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Mabini Arcade","address":"12 Mabini St","type":"OFFICE","usage":"COMMERCIAL"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usage").value("COMMERCIAL"));
    }
}
