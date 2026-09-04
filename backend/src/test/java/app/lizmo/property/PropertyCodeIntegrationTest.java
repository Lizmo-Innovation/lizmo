package app.lizmo.property;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/**
 * The code on the gate.
 *
 * <p>How a tenant finds a place they have no relationship to yet — which makes
 * this the one property lookup that crosses the ownership boundary on purpose,
 * and the one that has to be careful about what it hands over.
 */
class PropertyCodeIntegrationTest extends IntegrationTest {

    @org.springframework.beans.factory.annotation.Autowired
    private IssuedPropertyCodeRepository issuedCodes;

    private String landlordToken;
    private String tenantToken;

    @BeforeEach
    void signUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        tenantToken = accounts.tenant("ana").token();
    }


    /** @return the new property's code */
    private String createProperty(String name) throws Exception {
        String body = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"%s","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """.formatted(name)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("code").asText();
    }

    @Test
    void every_new_property_gets_a_code() throws Exception {
        String code = createProperty("Sunrise Apartments");

        assertThat(code).hasSize(8);
        assertThat(code).startsWith("PH");
        // Mirrors chk_properties_code_shape. No 0/O and no 1/I/L, because these
        // get read aloud and chalked on a board by the gate.
        assertThat(code).matches("PH[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}");
    }

    @Test
    void codes_do_not_repeat() throws Exception {
        Set<String> seen = new HashSet<>();
        for (int i = 0; i < 12; i++) {
            seen.add(createProperty("House " + i));
        }

        // Not proof of uniqueness at scale — the unique index is that. This
        // catches a generator that is not actually random, which would collide
        // constantly and would otherwise only show up in production.
        assertThat(seen).hasSize(12);
    }

    @Test
    void a_tenant_finds_a_place_by_its_code() throws Exception {
        String code = createProperty("Sunrise Apartments");

        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Sunrise Apartments"))
                .andExpect(jsonPath("$.address").value("12 Mabini St"))
                .andExpect(jsonPath("$.type").value("BOARDING_HOUSE"));
    }

    @Test
    void what_the_landlord_earns_is_not_handed_to_a_stranger() throws Exception {
        String code = createProperty("Sunrise Apartments");

        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk())
                // The landlord's own view carries what the building could earn
                // and how much of it they own. Someone who typed a code off a
                // gate is entitled to neither.
                .andExpect(jsonPath("$.potentialMonthlyRent").doesNotExist())
                .andExpect(jsonPath("$.unitCount").doesNotExist());
    }

    @Test
    void the_code_survives_being_read_aloud() throws Exception {
        String code = createProperty("Sunrise Apartments");

        // Lower case, with the spaces and dash of someone reading it back over
        // the phone. All the same code.
        for (String typed : new String[] {
            code.toLowerCase(),
            " " + code + " ",
            code.substring(0, 4) + "-" + code.substring(4),
        }) {
            mvc.perform(get("/api/v1/properties/lookup")
                            .param("code", typed)
                            .header("Authorization", "Bearer " + tenantToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.name").value("Sunrise Apartments"));
        }
    }

    @Test
    void an_unused_code_says_only_that() throws Exception {
        createProperty("Sunrise Apartments");

        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", "PHZZZZZZ")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_malformed_code_is_refused_the_same_way_as_an_unused_one() throws Exception {
        // Same 404, deliberately. A different answer for "that is not a code"
        // and "that code is not in use" turns this endpoint into a way to test
        // codes one at a time and learn which properties exist.
        for (String rubbish : new String[] {
            "", "  ", "!!!", "ABC", "TOOLONGCODE", "PHOOOOOO", "LZ7K4M2A"}) {
            mvc.perform(get("/api/v1/properties/lookup")
                            .param("code", rubbish)
                            .header("Authorization", "Bearer " + tenantToken))
                    .andExpect(status().isNotFound());
        }
    }

    @Test
    void a_deleted_property_does_not_give_its_code_back() throws Exception {
        String code = createProperty("Sunrise Apartments");

        String id = json.readTree(mvc.perform(get("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken))
                .andReturn().getResponse().getContentAsString())
                .get(0).get("id").asText();

        mvc.perform(delete("/api/v1/properties/" + id)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        // The property is gone, so nothing answers to the code any more.
        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isNotFound());

        // But it is still spent. Reissuing it would let an old QR sticker or an
        // unchanged sign by the gate come to mean somebody else's building.
        assertThat(issuedCodes.existsById(code)).isTrue();
    }

    @Test
    void a_code_is_claimed_before_it_is_used() throws Exception {
        String code = createProperty("Sunrise Apartments");

        // The ledger is what makes a code spent, so it has to know about every
        // code the moment one is handed out — not only on deletion.
        assertThat(issuedCodes.existsById(code)).isTrue();
    }

    @Test
    void looking_up_a_place_still_needs_an_account() throws Exception {
        String code = createProperty("Sunrise Apartments");

        // Signed-in only: a code should not be scrapeable anonymously, and a
        // request sent later has to be traceable to a person.
        mvc.perform(get("/api/v1/properties/lookup").param("code", code))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void the_landlord_sees_the_code_on_their_own_property() throws Exception {
        String code = createProperty("Sunrise Apartments");

        // They have to be able to read it out, print it, or chalk it on a board.
        mvc.perform(get("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.code == '" + code + "')]").exists());
    }
}
