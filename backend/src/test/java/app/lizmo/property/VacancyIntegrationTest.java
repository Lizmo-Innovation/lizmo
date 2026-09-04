package app.lizmo.property;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/**
 * What a prospective tenant sees after scanning the code on the gate.
 *
 * <p>Grouped by floor, because "is there anything on the second floor?" is the
 * question people actually ask in a boarding house.
 */
class VacancyIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String tenantToken;
    private String propertyId;
    private String code;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        tenantToken = accounts.tenant("ana").token();

        String body = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        propertyId = json.readTree(body).get("id").asText();
        code = json.readTree(body).get("code").asText();
    }


    /** @return the new unit's id */
    private String addUnit(String unitNumber, String floor, String mode, String extra)
            throws Exception {
        String body = mvc.perform(post("/api/v1/properties/" + propertyId + "/units")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"unitNumber":"%s","floor":%s,"rentalMode":"%s"%s}
                                """.formatted(
                                    unitNumber,
                                    floor == null ? "null" : "\"" + floor + "\"",
                                    mode,
                                    extra)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("id").asText();
    }

    private org.springframework.test.web.servlet.ResultActions lookup() throws Exception {
        return mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk());
    }

    @Test
    void an_empty_property_offers_nothing_without_it_being_an_error() throws Exception {
        // A place with no units yet is a real answer, not a failure.
        lookup()
                .andExpect(jsonPath("$.floors.length()").value(0))
                .andExpect(jsonPath("$.vacantBeds").value(0))
                .andExpect(jsonPath("$.vacantWholeUnits").value(0));
    }

    @Test
    void beds_are_offered_one_at_a_time_with_their_prices() throws Exception {
        addUnit("2B", "2", "BEDSPACE", ",\"capacity\":3,\"rent\":2500.00");

        lookup()
                .andExpect(jsonPath("$.vacantBeds").value(3))
                .andExpect(jsonPath("$.vacantWholeUnits").value(0))
                .andExpect(jsonPath("$.floors.length()").value(1))
                .andExpect(jsonPath("$.floors[0].floor").value("2"))
                .andExpect(jsonPath("$.floors[0].bedspaces.length()").value(3))
                // A bed with no price of its own reports its unit's, resolved
                // here — null would read as free to anyone who did not know the
                // fallback rule.
                .andExpect(jsonPath("$.floors[0].bedspaces[0].rent").value(2500.00))
                .andExpect(jsonPath("$.floors[0].bedspaces[0].bedLabel").exists());
    }

    @Test
    void a_bed_priced_on_its_own_says_so() throws Exception {
        String unitId = addUnit("2B", "2", "BEDSPACE", ",\"capacity\":2,\"rent\":2500.00");

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bedId = json.readTree(beds).get(0).get("id").asText();

        mvc.perform(put("/api/v1/beds/" + bedId)
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"bedLabel":"Window bed","rent":3200.00}
                                """))
                .andExpect(status().isOk());

        // The bed by the window can cost more than the one by the door.
        lookup()
                .andExpect(jsonPath("$.floors[0].bedspaces[?(@.bedLabel == 'Window bed')].rent")
                        .value(3200.00));
    }

    @Test
    void a_whole_unit_is_offered_entire() throws Exception {
        addUnit("101", "1", "WHOLE_UNIT", ",\"rent\":12000.00,\"sizeSqm\":32.5");

        lookup()
                .andExpect(jsonPath("$.vacantWholeUnits").value(1))
                .andExpect(jsonPath("$.vacantBeds").value(0))
                .andExpect(jsonPath("$.floors[0].wholeUnits[0].unitNumber").value("101"))
                .andExpect(jsonPath("$.floors[0].wholeUnits[0].rent").value(12000.00))
                .andExpect(jsonPath("$.floors[0].wholeUnits[0].sizeSqm").value(32.5));
    }

    @Test
    void a_unit_out_of_service_is_not_offered() throws Exception {
        String unitId = addUnit("3C", "3", "WHOLE_UNIT", ",\"rent\":9000.00");

        mvc.perform(put("/api/v1/units/" + unitId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"underMaintenance\":true}"))
                .andExpect(status().isOk());

        // A room being repainted should not bring somebody across town to look
        // at it.
        lookup()
                .andExpect(jsonPath("$.vacantWholeUnits").value(0))
                .andExpect(jsonPath("$.floors.length()").value(0));
    }

    @Test
    void a_bed_out_of_service_is_not_offered_but_its_neighbours_are() throws Exception {
        String unitId = addUnit("2B", "2", "BEDSPACE", ",\"capacity\":3,\"rent\":2500.00");

        String beds = mvc.perform(get("/api/v1/units/" + unitId + "/beds")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString();
        String bedId = json.readTree(beds).get(0).get("id").asText();

        mvc.perform(put("/api/v1/beds/" + bedId + "/maintenance")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"underMaintenance\":true}"))
                .andExpect(status().isOk());

        // One broken bunk does not take the room off the market.
        lookup()
                .andExpect(jsonPath("$.vacantBeds").value(2))
                .andExpect(jsonPath("$.floors[0].bedspaces.length()").value(2));
    }

    @Test
    void floors_are_ordered_the_way_a_building_is() throws Exception {
        addUnit("A", "10", "WHOLE_UNIT", ",\"rent\":9000.00");
        addUnit("B", "2", "WHOLE_UNIT", ",\"rent\":9000.00");
        addUnit("C", "1", "WHOLE_UNIT", ",\"rent\":9000.00");

        // Sorted as text, floor 10 lands between 1 and 2 — which reads as a bug
        // to anyone with a ten-storey building.
        lookup()
                .andExpect(jsonPath("$.floors[0].floor").value("1"))
                .andExpect(jsonPath("$.floors[1].floor").value("2"))
                .andExpect(jsonPath("$.floors[2].floor").value("10"));
    }

    @Test
    void a_named_floor_sits_after_the_numbered_ones() throws Exception {
        addUnit("A", "2", "WHOLE_UNIT", ",\"rent\":9000.00");
        addUnit("B", "Mezzanine", "WHOLE_UNIT", ",\"rent\":9000.00");
        addUnit("C", null, "WHOLE_UNIT", ",\"rent\":9000.00");

        lookup()
                .andExpect(jsonPath("$.floors[0].floor").value("2"))
                .andExpect(jsonPath("$.floors[1].floor").value("Mezzanine"))
                // No floor at all goes last rather than being called floor zero.
                // Normal for a single-storey house.
                .andExpect(jsonPath("$.floors[2].floor").doesNotExist());
    }

    @Test
    void utilities_are_shown_because_they_are_part_of_what_gets_handed_over()
            throws Exception {
        String unitId = addUnit("101", "1", "WHOLE_UNIT", ",\"rent\":12000.00");

        mvc.perform(put("/api/v1/units/" + unitId + "/utilities")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"billing":"SEPARATE","utilities":[
                                  {"kind":"WIFI","enabled":true,"amount":800},
                                  {"kind":"WATER","enabled":true,"amount":400},
                                  {"kind":"ELECTRICITY","enabled":false,"amount":1500}]}
                                """))
                .andExpect(status().isOk());

        // Only the switched-on ones, and the tenant is told these are on top of
        // the rent rather than inside it.
        lookup()
                .andExpect(jsonPath("$.floors[0].wholeUnits[0].monthlyUtilities").value(1200))
                .andExpect(jsonPath("$.floors[0].wholeUnits[0].utilitiesIncluded").value(false));
    }

    @Test
    void a_unit_charging_no_utilities_says_nothing_rather_than_zero() throws Exception {
        addUnit("101", "1", "WHOLE_UNIT", ",\"rent\":12000.00");

        // Null, not 0. "The landlord has not set any" and "they cost nothing"
        // are different statements, and the app renders them differently.
        lookup()
                .andExpect(jsonPath("$.floors[0].wholeUnits[0].monthlyUtilities")
                        .doesNotExist());
    }

    @Test
    void a_bedspace_unit_is_never_offered_whole() throws Exception {
        addUnit("2B", "2", "BEDSPACE", ",\"capacity\":4,\"rent\":2500.00");

        // Every bed in it is free, and it is still not a room to rent entire —
        // the landlord chose to let it bed by bed.
        lookup()
                .andExpect(jsonPath("$.vacantWholeUnits").value(0))
                .andExpect(jsonPath("$.floors[0].wholeUnits.length()").value(0))
                .andExpect(jsonPath("$.vacantBeds").value(4));
    }

    @Test
    void totals_cannot_disagree_with_the_lists() throws Exception {
        addUnit("101", "1", "WHOLE_UNIT", ",\"rent\":12000.00");
        addUnit("2B", "2", "BEDSPACE", ",\"capacity\":3,\"rent\":2500.00");
        addUnit("2C", "2", "BEDSPACE", ",\"capacity\":2,\"rent\":2200.00");

        // The headline figure a screen leads with is derived from the same lists
        // below it, so the two cannot drift.
        lookup()
                .andExpect(jsonPath("$.vacantWholeUnits").value(1))
                .andExpect(jsonPath("$.vacantBeds").value(5))
                .andExpect(jsonPath("$.floors.length()").value(2))
                .andExpect(jsonPath("$.floors[1].bedspaces.length()").value(5));
    }

    @Test
    void what_the_landlord_earns_is_still_not_handed_over() throws Exception {
        addUnit("101", "1", "WHOLE_UNIT", ",\"rent\":12000.00");

        // The vacancy list gives asking prices for what is free. It must not
        // become a way to total up the whole building.
        lookup()
                .andExpect(jsonPath("$.potentialMonthlyRent").doesNotExist())
                .andExpect(jsonPath("$.unitCount").doesNotExist());
    }
}
