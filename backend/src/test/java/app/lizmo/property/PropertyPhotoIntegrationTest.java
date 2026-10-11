package app.lizmo.property;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;
import javax.imageio.ImageIO;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * What a place looks like, which is half of why anybody scans a code.
 *
 * <p>A stranger used to get an address, a type and counts per floor — enough
 * to rule somewhere out, nowhere near enough to choose it.
 */
class PropertyPhotoIntegrationTest extends IntegrationTest {

    private String landlordToken;
    private String otherLandlordToken;
    private String tenantToken;

    private String propertyId;
    private String code;

    @BeforeEach
    void setUp() throws Exception {
        landlordToken = accounts.landlord("elena").token();
        otherLandlordToken = accounts.landlord("rodel").token();
        tenantToken = accounts.tenant("ana").token();

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
        code = json.readTree(property).get("code").asText();
    }

    /** A different colour each time, so a test can tell two photographs apart. */
    private byte[] photo(Color colour) throws Exception {
        BufferedImage image = new BufferedImage(40, 30, BufferedImage.TYPE_INT_RGB);
        Graphics2D brush = image.createGraphics();
        brush.setColor(colour);
        brush.fillRect(0, 0, 40, 30);
        brush.dispose();

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", out);
        return out.toByteArray();
    }

    private ResultActions upload(String token, byte[] bytes) throws Exception {
        return mvc.perform(multipart("/api/v1/properties/" + propertyId + "/photos")
                .file(new MockMultipartFile("file", "house.jpg", "image/jpeg", bytes))
                .header("Authorization", "Bearer " + token));
    }

    private String add(Color colour) throws Exception {
        String added = upload(landlordToken, photo(colour))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(added).get("id").asText();
    }

    private List<String> idsInOrder() throws Exception {
        String listed = mvc.perform(get("/api/v1/properties/" + propertyId + "/photos")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        List<String> ids = new ArrayList<>();
        json.readTree(listed).forEach(photo -> ids.add(photo.get("id").asText()));
        return ids;
    }

    // ---- putting them up ------------------------------------------------------------

    @Test
    void a_landlord_adds_a_photo_and_gets_a_url_back() throws Exception {
        upload(landlordToken, photo(Color.BLUE))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.url").value(Matchers.containsString("http")))
                .andExpect(jsonPath("$.urlExpiresInSeconds")
                        .value(Matchers.greaterThan(0)))
                // The first one represents the place until they say otherwise.
                .andExpect(jsonPath("$.position").value(0));
    }

    @Test
    void they_come_back_in_the_order_they_went_up() throws Exception {
        String first = add(Color.BLUE);
        String second = add(Color.RED);

        assertThat(idsInOrder()).containsExactly(first, second);
    }

    /**
     * A gallery nobody reaches the end of, and every one of them a presigned
     * URL to mint on every read of the vacancy screen.
     */
    @Test
    void eight_is_as_many_as_a_property_gets() throws Exception {
        for (int i = 0; i < 8; i++) {
            add(Color.BLUE);
        }

        upload(landlordToken, photo(Color.RED))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(Matchers.containsString("Remove one first")));
    }

    @Test
    void something_that_is_not_an_image_is_refused() throws Exception {
        mvc.perform(multipart("/api/v1/properties/" + propertyId + "/photos")
                        .file(new MockMultipartFile(
                                "file", "notes.txt", "text/plain", "hello".getBytes()))
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isBadRequest());
    }

    @Test
    void nothing_uploaded_is_refused() throws Exception {
        mvc.perform(multipart("/api/v1/properties/" + propertyId + "/photos")
                        .file(new MockMultipartFile("file", "x.jpg", "image/jpeg", new byte[0]))
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isBadRequest());
    }

    // ---- who may ---------------------------------------------------------------------

    @Test
    void another_landlord_cannot_put_photos_on_this_place() throws Exception {
        upload(otherLandlordToken, photo(Color.BLUE))
                .andExpect(status().isNotFound());
    }

    @Test
    void a_tenant_cannot_put_photos_on_somebody_elses_place() throws Exception {
        upload(tenantToken, photo(Color.BLUE))
                .andExpect(status().isNotFound());
    }

    @Test
    void adding_a_photo_requires_signing_in() throws Exception {
        mvc.perform(multipart("/api/v1/properties/" + propertyId + "/photos")
                        .file(new MockMultipartFile(
                                "file", "house.jpg", "image/jpeg", photo(Color.BLUE))))
                .andExpect(status().isUnauthorized());
    }

    // ---- what a stranger with the code sees -------------------------------------------

    /** The whole point: somebody standing at a gate gets the photographs too. */
    @Test
    void somebody_with_the_code_sees_them() throws Exception {
        add(Color.BLUE);
        add(Color.RED);

        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.photos.length()").value(2))
                .andExpect(jsonPath("$.photos[0]").value(Matchers.containsString("http")));
    }

    /** Most properties have none, and an empty list is a real answer. */
    @Test
    void a_place_with_no_photos_says_so_with_an_empty_list() throws Exception {
        mvc.perform(get("/api/v1/properties/lookup")
                        .param("code", code)
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.photos.length()").value(0));
    }

    // ---- choosing which one leads ------------------------------------------------------

    @Test
    void the_landlord_chooses_which_one_represents_the_place() throws Exception {
        String first = add(Color.BLUE);
        String second = add(Color.RED);

        mvc.perform(put("/api/v1/properties/" + propertyId + "/photos/order")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"ids\":[\"%s\",\"%s\"]}".formatted(second, first)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(second))
                .andExpect(jsonPath("$[0].position").value(0));

        assertThat(idsInOrder()).containsExactly(second, first);
    }

    @Test
    void a_half_list_is_refused_rather_than_half_applied() throws Exception {
        String first = add(Color.BLUE);
        String second = add(Color.RED);

        mvc.perform(put("/api/v1/properties/" + propertyId + "/photos/order")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"ids\":[\"%s\"]}".formatted(second)))
                .andExpect(status().isBadRequest());

        assertThat(idsInOrder()).containsExactly(first, second);
    }

    @Test
    void a_photo_from_another_property_cannot_be_ordered_into_this_one()
            throws Exception {
        String mine = add(Color.BLUE);

        String theirs = mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunset","address":"1 Rizal Ave",
                                 "type":"APARTMENT","usage":"RESIDENTIAL"}
                                """))
                .andReturn().getResponse().getContentAsString();
        String otherProperty = json.readTree(theirs).get("id").asText();

        String elsewhere = json.readTree(mvc.perform(
                        multipart("/api/v1/properties/" + otherProperty + "/photos")
                                .file(new MockMultipartFile("file", "h.jpg", "image/jpeg",
                                        photo(Color.GREEN)))
                                .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText();

        mvc.perform(put("/api/v1/properties/" + propertyId + "/photos/order")
                        .header("Authorization", "Bearer " + landlordToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"ids\":[\"%s\"]}".formatted(elsewhere)))
                .andExpect(status().isBadRequest());

        assertThat(idsInOrder()).containsExactly(mine);
    }

    // ---- taking one down ---------------------------------------------------------------

    @Test
    void removing_one_closes_the_rest_up() throws Exception {
        String first = add(Color.BLUE);
        String second = add(Color.RED);
        String third = add(Color.GREEN);

        mvc.perform(delete("/api/v1/properties/" + propertyId + "/photos/" + first)
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNoContent());

        assertThat(idsInOrder()).containsExactly(second, third);

        // And the one that is now first says so, rather than keeping a 1 that
        // means nothing once the 0 has gone.
        mvc.perform(get("/api/v1/properties/" + propertyId + "/photos")
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(jsonPath("$[0].position").value(0))
                .andExpect(jsonPath("$[1].position").value(1));
    }

    @Test
    void another_landlord_cannot_remove_a_photo() throws Exception {
        String mine = add(Color.BLUE);

        mvc.perform(delete("/api/v1/properties/" + propertyId + "/photos/" + mine)
                        .header("Authorization", "Bearer " + otherLandlordToken))
                .andExpect(status().isNotFound());

        assertThat(idsInOrder()).containsExactly(mine);
    }

    @Test
    void a_photo_that_is_not_there_is_not_found() throws Exception {
        mvc.perform(delete("/api/v1/properties/" + propertyId + "/photos/"
                        + java.util.UUID.randomUUID())
                        .header("Authorization", "Bearer " + landlordToken))
                .andExpect(status().isNotFound());
    }
}
