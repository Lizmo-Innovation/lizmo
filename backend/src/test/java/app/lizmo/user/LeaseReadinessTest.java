package app.lizmo.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

/**
 * The guard that lease creation will call.
 *
 * <p>Exercised directly rather than through an endpoint, because there is no
 * endpoint: lease creation does not exist yet. That is the honest limit of
 * this suite — it proves the rule and the wording, and it cannot prove that
 * anything actually calls it. Whoever builds lease creation is the first
 * person able to prove that, and should.
 *
 * <p>The profile and the photographs are set up through the real API rather
 * than by writing rows, so what is asserted is the state a tenant can actually
 * put themselves in.
 */
class LeaseReadinessTest extends IntegrationTest {

    @Autowired
    private LeaseReadiness readiness;

    private String token;
    private UUID tenantId;

    @BeforeEach
    void signUp() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Ana","email":"ana%d@example.com",
                                 "password":"correct-horse-battery","asLandlord":false}
                                """.formatted(System.nanoTime())))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        token = json.readTree(body).get("accessToken").asText();
        tenantId = UUID.fromString(json.readTree(body).get("userId").asText());
    }

    @Test
    void a_brand_new_tenant_owes_everything() {
        assertThat(readiness.whatIsMissing(tenantId)).containsExactly(
                "an emergency contact",
                "their ID details",
                "a photo of their ID",
                "a 1x1 or selfie");
    }

    @Test
    void a_tenant_who_has_done_it_all_is_ready() throws Exception {
        fillInDetails();
        upload("VALID_ID");
        upload("TENANT_PHOTO");

        assertThat(readiness.whatIsMissing(tenantId)).isEmpty();
        assertThat(readiness.isReady(tenantId)).isTrue();
        // The whole point: it does not throw.
        readiness.require(tenantId);
    }

    @Test
    void details_without_photographs_are_not_enough() throws Exception {
        fillInDetails();

        // An ID number typed into a form is not an ID anybody has seen.
        assertThat(readiness.whatIsMissing(tenantId))
                .containsExactly("a photo of their ID", "a 1x1 or selfie");
    }

    @Test
    void photographs_without_details_are_not_enough_either() throws Exception {
        upload("VALID_ID");
        upload("TENANT_PHOTO");

        // A landlord holding two photographs still has nobody to call.
        assertThat(readiness.whatIsMissing(tenantId))
                .containsExactly("an emergency contact", "their ID details");
    }

    @Test
    void an_id_photograph_is_not_a_1x1() throws Exception {
        fillInDetails();
        upload("VALID_ID");

        // The one a landlord is most likely to think is enough.
        assertThat(readiness.whatIsMissing(tenantId)).containsExactly("a 1x1 or selfie");
    }

    @Test
    void half_an_emergency_contact_does_not_count() throws Exception {
        // A name with no number is nobody to call.
        save("""
                {"emergencyContactName":"Rosa Dela Cruz",
                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                """);

        assertThat(readiness.whatIsMissing(tenantId)).contains("an emergency contact");
    }

    @Test
    void an_id_type_with_no_number_does_not_count() throws Exception {
        save("""
                {"emergencyContactName":"Rosa Dela Cruz",
                 "emergencyContactPhone":"09171234567",
                 "idType":"PHILSYS"}
                """);

        assertThat(readiness.whatIsMissing(tenantId)).contains("their ID details");
    }

    @Test
    void an_account_with_no_tenant_profile_is_refused_for_that_reason() {
        // Not a tenant at all. Everything is missing, and saying so beats
        // reporting four separate gaps in a profile that does not exist.
        assertThat(readiness.whatIsMissing(UUID.randomUUID()))
                .containsExactly("a tenant profile");
    }

    @Test
    void refusing_names_what_the_tenant_still_owes() {
        assertThatThrownBy(() -> readiness.require(tenantId))
                .isInstanceOf(ApiException.class)
                // A landlord told only "profile incomplete" goes back to their
                // tenant with nothing to act on.
                .hasMessageContaining("an emergency contact, their ID details, "
                        + "a photo of their ID and a 1x1 or selfie")
                .extracting(error -> ((ApiException) error).getCode())
                // 409, not 400: the request is fine, and the same one will
                // succeed once the tenant finishes.
                .isEqualTo(ErrorCode.TENANT_PROFILE_INCOMPLETE);
    }

    @Test
    void one_thing_missing_reads_as_one_thing() throws Exception {
        fillInDetails();
        upload("VALID_ID");
        upload("TENANT_PHOTO");
        // Clear the phone again, leaving exactly one gap.
        save("""
                {"emergencyContactName":"Rosa Dela Cruz",
                 "emergencyContactPhone":"",
                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                """);

        assertThatThrownBy(() -> readiness.require(tenantId))
                // No stray "and", no comma: "They still need an emergency contact."
                .hasMessageContaining("still need an emergency contact.");
    }

    @Test
    void the_profile_endpoint_and_the_guard_never_disagree() throws Exception {
        fillInDetails();
        upload("VALID_ID");
        upload("TENANT_PHOTO");

        // readyForALease on the response is this same guard. If the two were
        // computed separately, the day they drifted a tenant would be told they
        // were ready by one screen and refused by the next.
        String body = mvc.perform(org.springframework.test.web.servlet.request
                        .MockMvcRequestBuilders.get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        assertThat(json.readTree(body).get("readyForALease").asBoolean())
                .isEqualTo(readiness.isReady(tenantId));
    }

    // ---- helpers ----------------------------------------------------------

    private void fillInDetails() throws Exception {
        save("""
                {"emergencyContactName":"Rosa Dela Cruz",
                 "emergencyContactPhone":"09171234567",
                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                """);
    }

    private void save(String body) throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
    }

    private void upload(String docType) throws Exception {
        mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "photo.jpg", "image/jpeg", photo()))
                        .param("docType", docType)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isCreated());
    }

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(40, 30, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.GRAY);
        g.fillRect(0, 0, 40, 30);
        g.dispose();

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpeg", out);
        return out.toByteArray();
    }
}
