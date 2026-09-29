package app.lizmo.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.support.Accounts;
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
    void signUp() {
        Accounts.Account ana = accounts.tenant("Ana");
        token = ana.token();
        tenantId = ana.id();
    }

    @Test
    void a_brand_new_tenant_owes_everything() {
        assertThat(readiness.whatIsMissing(tenantId)).containsExactly(
                "an emergency contact",
                "their ID details",
                "a photo of their ID");
    }

    /**
     * All it takes to ask about a room. The rest is asked when a landlord
     * accepts, by which point the two have spoken.
     */
    @Test
    void asking_about_a_room_takes_only_a_number() throws Exception {
        assertThat(readiness.whatIsNeededToAsk(tenantId))
                .containsExactly("a phone number");

        save("""
                {"contactPhone":"09170000001"}
                """);

        assertThat(readiness.whatIsNeededToAsk(tenantId)).isEmpty();
        // Still nowhere near ready for a tenancy.
        assertThat(readiness.isReady(tenantId)).isFalse();
        readiness.requireEnoughToAsk(tenantId);
    }

    @Test
    void being_told_to_add_a_number_says_why() {
        assertThatThrownBy(() -> readiness.requireEnoughToAsk(tenantId))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("so the landlord can reach you")
                .extracting(error -> ((ApiException) error).getCode())
                .isEqualTo(ErrorCode.TENANT_PROFILE_INCOMPLETE);
    }

    /** An account that is not a tenant's has no number to ask with either. */
    @Test
    void an_account_with_no_profile_cannot_ask() {
        assertThat(readiness.whatIsNeededToAsk(UUID.randomUUID()))
                .containsExactly("a tenant profile");
    }

    @Test
    void a_tenant_who_has_done_it_all_is_ready() throws Exception {
        fillInDetails();
        upload("VALID_ID");

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
                .containsExactly("a photo of their ID");
    }

    @Test
    void photographs_without_details_are_not_enough_either() throws Exception {
        upload("VALID_ID");

        // A landlord holding two photographs still has nobody to call.
        assertThat(readiness.whatIsMissing(tenantId))
                .containsExactly("an emergency contact", "their ID details");
    }

    /**
     * A 1x1 used to be demanded too: a second identity document from somebody
     * who has not moved in, on top of the ID they had already photographed.
     */
    @Test
    void a_selfie_is_no_longer_demanded() throws Exception {
        fillInDetails();
        upload("VALID_ID");

        assertThat(readiness.whatIsMissing(tenantId)).isEmpty();
        assertThat(readiness.isReady(tenantId)).isTrue();
    }

    @Test
    void half_an_emergency_contact_does_not_count() throws Exception {
        // A name with no number is nobody to call.
        save("""
                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                """);

        assertThat(readiness.whatIsMissing(tenantId)).contains("an emergency contact");
    }

    @Test
    void an_id_type_with_no_number_does_not_count() throws Exception {
        save("""
                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
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
                .hasMessageContaining("an emergency contact, their ID details "
                        + "and a photo of their ID")
                .extracting(error -> ((ApiException) error).getCode())
                // 409, not 400: the request is fine, and the same one will
                // succeed once the tenant finishes.
                .isEqualTo(ErrorCode.TENANT_PROFILE_INCOMPLETE);
    }

    @Test
    void one_thing_missing_reads_as_one_thing() throws Exception {
        fillInDetails();
        upload("VALID_ID");
        // Clear the phone again, leaving exactly one gap.
        save("""
                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
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
                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
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
