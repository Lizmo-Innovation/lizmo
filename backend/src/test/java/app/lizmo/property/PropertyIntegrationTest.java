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
    void an_empty_property_can_be_deleted() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(delete("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());

        mvc.perform(get("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void a_property_becomes_deletable_once_its_units_are_gone() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        // The refusal is not a dead end: the unit can be deleted, beds and all,
        // and the property then goes with it.
        mvc.perform(delete("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        mvc.perform(delete("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());
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
    void a_bedspace_unit_is_deleted_together_with_its_beds() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        // Beds are no longer set up by hand, so refusing while any exist would
        // leave every bedspace unit undeletable.
        mvc.perform(delete("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());
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
    void beds_are_created_with_a_bedspace_unit() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 3);

        // Capacity is the bed count -- the form asks "How many beds?" -- so the
        // landlord does not have to say the same number twice.
        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[0].bedLabel").value("Bed 1"))
                .andExpect(jsonPath("$[2].bedLabel").value("Bed 3"))
                .andExpect(jsonPath("$[0].status").value("VACANT"));

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.bedCount").value(3));
    }

    @Test
    void a_whole_unit_gets_no_beds() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "1A", "WHOLE_UNIT", 1);

        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
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
    void adding_a_bed_directly_raises_capacity() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 1);

        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 2"}
                                """))
                .andExpect(status().isCreated());

        // Capacity and bed count are two views of the same number, so whichever
        // end moves, the other follows. Letting them disagree would mean the
        // next edit of the unit silently deleted this bed again.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.capacity").value(2))
                .andExpect(jsonPath("$.bedCount").value(2));
    }

    @Test
    void bed_labels_are_unique_within_a_unit() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        // "Bed 1" through "Bed 4" already exist, created with the unit. The
        // index is case-insensitive, so this collides with one of them.
        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"bed 1"}
                                """))
                .andExpect(status().isBadRequest());

        // A label the auto-created set did not take is accepted.
        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Upper bunk"}
                                """))
                .andExpect(status().isCreated());
    }

    @Test
    void raising_capacity_adds_beds() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        mvc.perform(put("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":4}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bedCount").value(4));

        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(4))
                .andExpect(jsonPath("$[3].bedLabel").value("Bed 4"));
    }

    @Test
    void lowering_capacity_removes_beds() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        mvc.perform(put("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":2}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bedCount").value(2));

        // The lowest-numbered beds survive: those are the ones a landlord is
        // most likely to have already written down somewhere.
        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].bedLabel").value("Bed 1"))
                .andExpect(jsonPath("$[1].bedLabel").value("Bed 2"));
    }

    @Test
    void resizing_twice_does_not_duplicate_labels() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 3);

        for (int capacity : new int[] {1, 3, 2, 4}) {
            mvc.perform(put("/api/v1/units/" + unitId)
                            .header("Authorization", "Bearer " + landlordToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":%d}
                                    """.formatted(capacity)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.bedCount").value(capacity));
        }

        // Labels are unique per unit and the index is case-insensitive, so
        // refilling has to skip numbers already taken rather than restart at 1.
        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(4));
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

    @Test
    void a_bed_can_be_renamed() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        String bedId = json.readTree(beds).get(0).get("id").asText();

        // "Bed 1" says nothing about the room; a landlord letting bunks knows
        // the difference between the upper and the lower one.
        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1 upper bunk"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bedLabel").value("Bed 1 upper bunk"));
    }

    @Test
    void renaming_a_bed_cannot_take_another_beds_label() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bedId = json.readTree(beds).get(0).get("id").asText();

        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"bed 2"}
                                """))
                .andExpect(status().isBadRequest());

        // Saving a bed under its own name is not a clash with itself.
        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1"}
                                """))
                .andExpect(status().isOk());
    }

    @Test
    void another_landlord_cannot_rename_a_bed() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bedId = json.readTree(beds).get(0).get("id").asText();

        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + otherLandlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Mine now"}
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void shrinking_removes_default_named_beds_before_renamed_ones() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        // Rename the last one, which plain label ordering would delete first.
        String lastBedId = json.readTree(beds).get(3).get("id").asText();

        mvc.perform(put("/api/v1/beds/" + lastBedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Upper bunk"}
                                """))
                .andExpect(status().isOk());

        mvc.perform(put("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":2}
                                """))
                .andExpect(status().isOk());

        // A renamed bed is one the landlord told us matters; "Bed 3" is just the
        // number we gave it.
        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].bedLabel").value("Bed 1"))
                .andExpect(jsonPath("$[1].bedLabel").value("Upper bunk"));
    }

    // ---------- Beds out of service ----------

    private String firstBedId(String unitId) throws Exception {
        String body = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get(0).get("id").asText();
    }

    @Test
    void a_bed_can_be_taken_out_of_service_and_put_back() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 4);
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("MAINTENANCE"));

        // The bed still exists and still counts towards capacity -- it is out
        // of service, not gone.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.bedCount").value(4))
                .andExpect(jsonPath("$.capacity").value(4))
                .andExpect(jsonPath("$.bedsUnderMaintenance").value(1));

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":false}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("VACANT"));

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.bedsUnderMaintenance").value(0));
    }

    @Test
    void maintenance_is_reported_per_unit_in_the_list() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 3);
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk());

        // The list is what the property screen totals, so the figure has to be
        // there too, not only on the single-unit response.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].bedCount").value(3))
                .andExpect(jsonPath("$[0].bedsUnderMaintenance").value(1));
    }

    @Test
    void maintenance_requires_a_value() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void another_landlord_cannot_change_maintenance() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + otherLandlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_bed_out_of_service_can_still_be_removed_by_lowering_the_count()
            throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 3);
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk());

        // Only occupancy blocks shrinking. A bed out of service has no tenant
        // behind it, so it is fair game.
        mvc.perform(put("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":1}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bedCount").value(1));
    }

    // ---------- Per-bed rent ----------

    @Test
    void a_bed_starts_on_the_units_rate() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        String body = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"BEDSPACE","capacity":2,"rent":2500.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String unitId = json.readTree(body).get("id").asText();

        // Null, not zero: the beds are let at whatever the unit asks, and a
        // figure here would be a claim the landlord never made.
        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].rent").doesNotExist())
                .andExpect(jsonPath("$[1].rent").doesNotExist());
    }

    @Test
    void one_bed_can_be_priced_differently_from_the_rest() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 3);
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1 lower bunk","rent":2000.00}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rent").value(2000.00))
                .andExpect(jsonPath("$.bedLabel").value("Bed 1 lower bunk"));

        // Its neighbours are untouched.
        mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[1].rent").doesNotExist())
                .andExpect(jsonPath("$[2].rent").doesNotExist());
    }

    @Test
    void omitting_the_rent_returns_a_bed_to_the_units_rate() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1","rent":2000.00}
                                """))
                .andExpect(status().isOk());

        // A PUT carries the whole bed, so leaving the rent out clears it. That
        // is how a landlord undoes a per-bed price.
        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rent").doesNotExist());
    }

    @Test
    void a_bed_cannot_be_priced_at_zero() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);
        String bedId = firstBedId(unitId);

        // Zero would read as free rather than unset, which is what null means.
        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1","rent":0}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void a_bed_added_by_hand_can_carry_its_own_rent() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 1);

        mvc.perform(post("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Upper bunk","rent":1800.50}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.rent").value(1800.50));
    }

    @Test
    void a_bed_keeps_its_rent_through_maintenance() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1","rent":2000.00}
                                """))
                .andExpect(status().isOk());

        // Out of service is a state, not an edit. The price survives it, or
        // taking a bed out for repairs would quietly reprice it on return.
        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rent").value(2000.00));
    }

    // ---------- What a unit can bring in ----------

    private String createBedspaceWithRent(String propertyId, String number, int beds, String rent)
            throws Exception {
        String body = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"%s","rentalMode":"BEDSPACE","capacity":%d,"rent":%s}
                                """.formatted(number, beds, rent)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("id").asText();
    }

    @Test
    void a_bedspace_totals_what_all_its_beds_would_bring_in() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createBedspaceWithRent(propertyId, "2B", 4, "2500.00");

        // Four beds at the unit's rate.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.potentialMonthlyRent").value(10000.00));
    }

    @Test
    void a_whole_unit_reports_its_own_rent() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        String body = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","rentalMode":"WHOLE_UNIT","rent":7000.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String unitId = json.readTree(body).get("id").asText();

        // One tenancy, so there is nothing to sum.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.potentialMonthlyRent").value(7000.00));
    }

    @Test
    void a_bed_priced_on_its_own_changes_the_total() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createBedspaceWithRent(propertyId, "2B", 3, "2500.00");
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1","rent":2000.00}
                                """))
                .andExpect(status().isOk());

        // 2000 + 2500 + 2500.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.potentialMonthlyRent").value(7000.00));
    }

    @Test
    void a_bed_out_of_service_is_left_out_of_the_total() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createBedspaceWithRent(propertyId, "2B", 4, "2500.00");
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk());

        // It cannot be let, so counting it would overstate what the unit earns.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.potentialMonthlyRent").value(7500.00));
    }

    @Test
    void a_unit_with_no_rent_set_totals_nothing_rather_than_zero() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 3);

        // Null, not 0: the landlord has not said what these beds cost, and 0
        // would claim they are free.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.potentialMonthlyRent").doesNotExist());
    }

    @Test
    void the_total_appears_in_the_unit_list_too() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        createBedspaceWithRent(propertyId, "2B", 2, "2500.00");

        // The property screen reads the list, not the single-unit response.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].potentialMonthlyRent").value(5000.00));
    }

    // ---------- Units out of service ----------

    @Test
    void a_unit_can_be_taken_out_of_service_and_put_back() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createBedspaceWithRent(propertyId, "2B", 4, "2500.00");

        mvc.perform(put("/api/v1/units/" + unitId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("MAINTENANCE"))
                // Nothing here can be let, so there is nothing to total.
                .andExpect(jsonPath("$.potentialMonthlyRent").doesNotExist());

        // The beds are untouched: the room is shut, not dismantled.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.bedCount").value(4))
                .andExpect(jsonPath("$.bedsUnderMaintenance").value(0));

        mvc.perform(put("/api/v1/units/" + unitId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":false}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("VACANT"))
                .andExpect(jsonPath("$.potentialMonthlyRent").value(10000.00));
    }

    @Test
    void a_whole_unit_out_of_service_earns_nothing() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        String body = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","rentalMode":"WHOLE_UNIT","rent":7000.00}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String unitId = json.readTree(body).get("id").asText();

        mvc.perform(put("/api/v1/units/" + unitId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.potentialMonthlyRent").doesNotExist())
                // The asking rent survives; it is the earning that stops.
                .andExpect(jsonPath("$.rent").value(7000.00));
    }

    @Test
    void unit_maintenance_requires_a_value() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        mvc.perform(put("/api/v1/units/" + unitId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void another_landlord_cannot_close_a_unit() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        mvc.perform(put("/api/v1/units/" + unitId + "/maintenance")
                        .header("Authorization", "Bearer " + otherLandlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_unit_out_of_service_still_appears_in_the_list() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createBedspaceWithRent(propertyId, "2B", 2, "2500.00");

        mvc.perform(put("/api/v1/units/" + unitId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk());

        // Hidden from the earnings, not from the landlord: they still need to
        // find it to put it back into service.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].status").value("MAINTENANCE"))
                .andExpect(jsonPath("$[0].potentialMonthlyRent").doesNotExist());
    }

    // ---------- Fixed monthly utilities ----------

    private void setUtilities(String unitId, String body) throws Exception {
        mvc.perform(put("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
    }

    @Test
    void every_utility_is_listed_even_before_it_is_set_up() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        // Three switches on the screen means three answers from the API; the
        // client should not have to read absence as "off".
        mvc.perform(get("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.utilities.length()").value(3))
                .andExpect(jsonPath("$.utilities[0].kind").value("WIFI"))
                .andExpect(jsonPath("$.utilities[0].enabled").value(false))
                .andExpect(jsonPath("$.utilities[0].amount").doesNotExist())
                // Combined until a landlord says otherwise.
                .andExpect(jsonPath("$.billing").value("COMBINED"));
    }

    @Test
    void utilities_are_switched_on_independently() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        setUtilities(unitId, """
                                {"utilities":[{"kind":"WIFI","enabled":true,"amount":500.00},
                 {"kind":"WATER","enabled":true,"amount":300.00}]}
                                """);

        mvc.perform(get("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.utilities[0].kind").value("WIFI"))
                .andExpect(jsonPath("$.utilities[0].enabled").value(true))
                .andExpect(jsonPath("$.utilities[0].amount").value(500.00))
                // Electricity was never mentioned, so it stays untouched.
                .andExpect(jsonPath("$.utilities[1].kind").value("ELECTRICITY"))
                .andExpect(jsonPath("$.utilities[1].enabled").value(false))
                .andExpect(jsonPath("$.utilities[2].kind").value("WATER"))
                .andExpect(jsonPath("$.utilities[2].enabled").value(true));
    }

    @Test
    void the_unit_reports_what_its_utilities_add_to_a_month() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        setUtilities(unitId, """
                                {"utilities":[{"kind":"WIFI","enabled":true,"amount":500.00},
                 {"kind":"ELECTRICITY","enabled":true,"amount":1200.00},
                 {"kind":"WATER","enabled":false,"amount":300.00}]}
                                """);

        // Only what is switched on: water is set up but not being charged.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.monthlyUtilities").value(1700.00));
    }

    @Test
    void switching_a_utility_off_keeps_its_amount() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        setUtilities(unitId, """
                                {"utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                                """);

        // No amount sent: switching off should not make the landlord remember
        // what they were charging when they switch it back on.
        setUtilities(unitId, """
                                {"utilities":[{"kind":"WIFI","enabled":false}]}
                                """);

        mvc.perform(get("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.utilities[0].enabled").value(false))
                .andExpect(jsonPath("$.utilities[0].amount").value(500.00));

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.monthlyUtilities").doesNotExist());

        setUtilities(unitId, """
                                {"utilities":[{"kind":"WIFI","enabled":true}]}
                                """);

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.monthlyUtilities").value(500.00));
    }

    @Test
    void a_utility_cannot_be_switched_on_without_an_amount() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        // A charge with no amount is not a charge.
        mvc.perform(put("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"utilities":[{"kind":"WIFI","enabled":true}]}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("wifi")));
    }

    @Test
    void a_utility_cannot_be_priced_at_zero() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        mvc.perform(put("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"utilities":[{"kind":"WIFI","enabled":true,"amount":0}]}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void utilities_are_independent_of_rent() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createBedspaceWithRent(propertyId, "2B", 2, "2500.00");

        setUtilities(unitId, """
                                {"utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                                """);

        // Different lines on a bill: the rent total does not absorb them.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.potentialMonthlyRent").value(5000.00))
                .andExpect(jsonPath("$.monthlyUtilities").value(500.00));
    }

    @Test
    void another_landlord_cannot_read_or_set_utilities() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        mvc.perform(get("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());

        mvc.perform(put("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + otherLandlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void utilities_go_with_the_unit_when_it_is_deleted() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "1A", "WHOLE_UNIT", 1);

        setUtilities(unitId, """
                                {"utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                                """);

        // ON DELETE CASCADE, so a deleted unit leaves no utility rows behind to
        // be adopted by a later unit with a recycled id.
        mvc.perform(delete("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());
    }

    // ---------- How utilities are billed ----------

    @Test
    void utilities_are_combined_with_rent_until_told_otherwise() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        // The simpler of the two for everyone, and what every unit created
        // before the choice existed was implicitly doing.
        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.utilityBilling").value("COMBINED"));
    }

    @Test
    void utilities_can_be_billed_separately() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        setUtilities(unitId, """
                {"billing":"SEPARATE",
                 "utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                """);

        mvc.perform(get("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.billing").value("SEPARATE"));

        mvc.perform(get("/api/v1/units/" + unitId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.utilityBilling").value("SEPARATE"))
                // The choice is about presentation, not arithmetic: the amount
                // is the same either way.
                .andExpect(jsonPath("$.monthlyUtilities").value(500.00));
    }

    @Test
    void changing_an_amount_leaves_the_billing_choice_alone() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        setUtilities(unitId, """
                {"billing":"SEPARATE",
                 "utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                """);

        // No billing sent: a client changing an amount should not have to
        // restate how it is billed.
        setUtilities(unitId, """
                {"utilities":[{"kind":"WIFI","enabled":true,"amount":600.00}]}
                """);

        mvc.perform(get("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.billing").value("SEPARATE"))
                .andExpect(jsonPath("$.utilities[0].amount").value(600.00));
    }

    @Test
    void the_billing_choice_can_be_changed_back() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        setUtilities(unitId, """
                {"billing":"SEPARATE",
                 "utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                """);
        setUtilities(unitId, """
                {"billing":"COMBINED",
                 "utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                """);

        mvc.perform(get("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.billing").value("COMBINED"));
    }

    @Test
    void the_billing_choice_is_per_unit() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String separate = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);
        String combined = createUnit(landlordToken, propertyId, "1A", "WHOLE_UNIT", 1);

        setUtilities(separate, """
                {"billing":"SEPARATE",
                 "utilities":[{"kind":"WIFI","enabled":true,"amount":500.00}]}
                """);

        // One unit's choice does not reach its neighbours: a landlord may bill
        // the bedspacers separately and fold it into the family's rent.
        mvc.perform(get("/api/v1/units/" + combined)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.utilityBilling").value("COMBINED"));
    }

    @Test
    void an_unknown_billing_choice_is_refused() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createUnit(landlordToken, propertyId, "2B", "BEDSPACE", 2);

        mvc.perform(put("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"billing":"QUARTERLY",
                                 "utilities":[{"kind":"WIFI","enabled":false}]}
                                """))
                .andExpect(status().isBadRequest())
                // Naming the accepted values is the difference between a usable
                // error and a shrug.
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("COMBINED, SEPARATE")));
    }

    @Test
    void an_unknown_enum_anywhere_is_a_400_not_a_500() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        // Jackson fails before bean validation runs, so without a handler for
        // an unreadable body every typo in an enum became a 500.
        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"2B","rentalMode":"HOTEL","capacity":2}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("WHOLE_UNIT")));
    }

    // ---------- What a property brings in ----------

    @Test
    void a_property_totals_what_its_units_bring_in() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        createBedspaceWithRent(propertyId, "2B", 4, "2500.00");

        mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"1A","rentalMode":"WHOLE_UNIT","rent":7000.00}
                                """))
                .andExpect(status().isCreated());

        // Four beds at 2500, plus a whole unit at 7000. The same figure the
        // unit screens show, added up.
        mvc.perform(get("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].potentialMonthlyRent").value(17000.00));
    }

    @Test
    void an_empty_property_totals_nothing_rather_than_zero() throws Exception {
        createProperty(landlordToken, "Sunrise Apartments");

        // Nothing in it is priced, which is not the same as free.
        mvc.perform(get("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].potentialMonthlyRent").doesNotExist());
    }

    @Test
    void a_unit_out_of_service_leaves_the_property_total() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String closed = createBedspaceWithRent(propertyId, "2B", 4, "2500.00");
        createBedspaceWithRent(propertyId, "3B", 2, "2000.00");

        mvc.perform(put("/api/v1/units/" + closed + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"underMaintenance":true}
                                """))
                .andExpect(status().isOk());

        // Only 3B counts: 2 x 2000.
        mvc.perform(get("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].potentialMonthlyRent").value(4000.00));
    }

    @Test
    void the_property_total_follows_a_bed_priced_on_its_own() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");
        String unitId = createBedspaceWithRent(propertyId, "2B", 3, "2500.00");
        String bedId = firstBedId(unitId);

        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Bed 1","rent":2000.00}
                                """))
                .andExpect(status().isOk());

        // 2000 + 2500 + 2500. The property figure is derived the same way as
        // the unit's, so the two can never disagree.
        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.potentialMonthlyRent").value(7000.00));
    }

    // ---------- Property description ----------

    @Test
    void a_property_can_carry_a_description() throws Exception {
        String body = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "description":"Quiet street, five minutes from the LRT.",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.description")
                        .value("Quiet street, five minutes from the LRT."))
                .andReturn().getResponse().getContentAsString();

        String propertyId = json.readTree(body).get("id").asText();

        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.description")
                        .value("Quiet street, five minutes from the LRT."));
    }

    @Test
    void a_property_without_one_reports_nothing_rather_than_empty() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        // Null, not "": no description and an empty description are different
        // statements, and every other optional field here draws that line.
        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$.description").doesNotExist());
    }

    @Test
    void a_blank_description_is_stored_as_none() throws Exception {
        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "description":"   ",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                // Clearing the field means having no description, not having
                // one made of spaces.
                .andExpect(jsonPath("$.description").doesNotExist());
    }

    @Test
    void a_description_can_be_edited_and_cleared() throws Exception {
        String propertyId = createProperty(landlordToken, "Sunrise Apartments");

        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "description":"Newly repainted.",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.description").value("Newly repainted."));

        // A PUT carries the whole property, so leaving it out clears it.
        mvc.perform(put("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.description").doesNotExist());
    }

    @Test
    void a_description_longer_than_the_cap_is_refused() throws Exception {
        // 2001 characters. Without a cap a paste from a word processor lands in
        // the database and then in every property list response.
        String tooLong = "x".repeat(2001);

        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "description":"%s",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """.formatted(tooLong)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields.description").exists());
    }

    @Test
    void a_description_at_the_cap_is_accepted() throws Exception {
        String atLimit = "x".repeat(2000);

        mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "description":"%s",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """.formatted(atLimit)))
                .andExpect(status().isCreated());
    }

    @Test
    void another_landlord_cannot_read_a_description() throws Exception {
        String body = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "description":"Private notes about the place.",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String propertyId = json.readTree(body).get("id").asText();

        mvc.perform(get("/api/v1/properties/" + propertyId)
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());
    }
}
