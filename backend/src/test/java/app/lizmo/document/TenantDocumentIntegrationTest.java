package app.lizmo.document;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.support.InMemoryDocumentStore;
import com.drew.imaging.ImageMetadataReader;
import com.drew.metadata.Metadata;
import com.drew.metadata.exif.ExifIFD0Directory;
import app.lizmo.support.IntegrationTest;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

/**
 * The photographs a tenant uploads about themselves.
 *
 * <p>These are the most personal things the app holds. The isolation tests
 * matter more here than anywhere: an ID photographed at home is an address as
 * well as a name.
 */
class TenantDocumentIntegrationTest extends IntegrationTest {

    @Autowired
    private InMemoryDocumentStore store;

    private String tenantToken;
    private String otherTenantToken;

    @BeforeEach
    void signUp() throws Exception {
        store.clear();
        tenantToken = accounts.tenant("ana").token();
        otherTenantToken = accounts.tenant("bea").token();
    }


    private void upload(String token, String docType, byte[] bytes) throws Exception {
        mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "photo.jpg", "image/jpeg", bytes))
                        .param("docType", docType)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isCreated());
    }

    @Test
    void a_tenant_uploads_their_id() throws Exception {
        mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "id.jpg", "image/jpeg", photo()))
                        .param("docType", "VALID_ID")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.docType").value("VALID_ID"))
                // Signed and short-lived, never a bare key or a public address.
                .andExpect(jsonPath("$.url").exists())
                .andExpect(jsonPath("$.urlExpiresInSeconds").value(600));
    }

    @Test
    void a_tenant_starts_with_no_photographs() throws Exception {
        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void both_photographs_are_kept_apart() throws Exception {
        upload(tenantToken, "VALID_ID", photo());
        upload(tenantToken, "TENANT_PHOTO", photo());

        // A 1x1 is not a second ID, and the two must stay separately askable.
        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void uploading_again_replaces_rather_than_stacking() throws Exception {
        upload(tenantToken, "VALID_ID", photo());
        upload(tenantToken, "VALID_ID", photo());

        // Otherwise "the tenant's ID" becomes a question with two answers, and
        // the newest is only probably the right one.
        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.length()").value(1));
        // And the superseded object does not linger in the bucket.
        assertThat(store.size()).isEqualTo(1);
    }

    @Test
    void what_reaches_the_bucket_carries_no_metadata() throws Exception {
        byte[] withExif = photoWithOrientation(6);
        assertThat(hasExif(withExif)).as("the fixture must carry what we strip").isTrue();

        upload(tenantToken, "VALID_ID", withExif);

        byte[] stored = store.all().values().iterator().next().bytes();
        // Asserted on the bytes that were stored, not on the response: the only
        // way to know an ID photographed at home did not bring the address.
        assertThat(hasExif(stored)).isFalse();
    }

    @Test
    void what_reaches_the_bucket_is_always_a_jpeg() throws Exception {
        BufferedImage image = new BufferedImage(30, 30, BufferedImage.TYPE_INT_ARGB);
        ByteArrayOutputStream png = new ByteArrayOutputStream();
        ImageIO.write(image, "png", png);

        upload(tenantToken, "TENANT_PHOTO", png.toByteArray());

        assertThat(store.all().values().iterator().next().contentType()).isEqualTo("image/jpeg");
    }

    @Test
    void a_tenant_cannot_file_a_lease_contract_under_their_own_name() throws Exception {
        // The type comes from the request, so without a check a tenant could
        // write any kind of document into their own folder.
        mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "x.jpg", "image/jpeg", photo()))
                        .param("docType", "LEASE_CONTRACT")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isBadRequest());
    }

    @Test
    void an_unknown_document_type_is_refused_by_name() throws Exception {
        mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "x.jpg", "image/jpeg", photo()))
                        .param("docType", "BIRTH_CERTIFICATE")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("VALID_ID")));
    }

    @Test
    void something_that_is_not_an_image_is_refused() throws Exception {
        mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "cv.pdf", "application/pdf",
                                "%PDF-1.4 not a photograph".getBytes(StandardCharsets.UTF_8)))
                        .param("docType", "VALID_ID")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isBadRequest())
                // Most often HEIC from an iPhone, so it says what to upload.
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("JPEG or PNG")));
        assertThat(store.size()).isZero();
    }

    @Test
    void an_empty_upload_is_refused() throws Exception {
        mvc.perform(multipart("/api/v1/me/tenant-profile/documents")
                        .file(new MockMultipartFile("file", "empty.jpg", "image/jpeg",
                                new byte[0]))
                        .param("docType", "VALID_ID")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(status().isBadRequest());
    }

    @Test
    void one_tenant_never_sees_another_photograph() throws Exception {
        upload(tenantToken, "VALID_ID", photo());

        // The endpoint is addressed as "me". There is no id to pass, which is
        // the point.
        mvc.perform(get("/api/v1/me/tenant-profile/documents")
                        .header("Authorization", "Bearer " + otherTenantToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void signing_in_is_not_optional() throws Exception {
        mvc.perform(get("/api/v1/me/tenant-profile/documents"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void a_lease_needs_the_details_and_the_id_photograph() throws Exception {
        mvc.perform(put("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"contactPhone":"09170000001",
                                 "emergencyContactName":"Rosa Dela Cruz",
                                 "emergencyContactPhone":"09171234567",
                                 "idType":"PHILSYS","idNumber":"1234-5678-9012"}
                                """))
                .andExpect(status().isOk())
                // Every detail filled in, and still not ready: an ID number
                // typed in is not an ID anyone has seen.
                .andExpect(jsonPath("$.readyForALease").value(false));

        upload(tenantToken, "VALID_ID", photo());
        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken))
                // The ID photograph is the last of it. A 1x1 used to be asked
                // for as well, from somebody who had not moved in.
                .andExpect(jsonPath("$.readyForALease").value(true));
    }

    @Test
    void photographs_alone_are_not_enough_either() throws Exception {
        upload(tenantToken, "VALID_ID", photo());
        upload(tenantToken, "TENANT_PHOTO", photo());

        // No emergency contact. A landlord holding two photographs still has
        // nobody to call.
        mvc.perform(get("/api/v1/me/tenant-profile")
                        .header("Authorization", "Bearer " + tenantToken))
                .andExpect(jsonPath("$.readyForALease").value(false));
    }

    // ---- helpers ----------------------------------------------------------

    private static byte[] photo() throws Exception {
        BufferedImage image = new BufferedImage(60, 40, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.GRAY);
        g.fillRect(0, 0, 60, 40);
        g.dispose();

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "jpeg", out);
        return out.toByteArray();
    }

    /** A JPEG carrying an EXIF orientation, as a phone camera produces. */
    private static byte[] photoWithOrientation(int orientation) throws Exception {
        byte[] plain = photo();
        ByteArrayOutputStream payload = new ByteArrayOutputStream();
        payload.writeBytes("Exif".getBytes(StandardCharsets.US_ASCII));
        payload.write(0);
        payload.write(0);
        payload.writeBytes(new byte[] {'I', 'I', 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00});
        payload.writeBytes(new byte[] {0x01, 0x00});
        payload.writeBytes(new byte[] {0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00});
        payload.write(orientation & 0xFF);
        payload.write(0);
        payload.write(0);
        payload.write(0);
        payload.writeBytes(new byte[] {0, 0, 0, 0});

        byte[] exif = payload.toByteArray();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(plain[0]);
        out.write(plain[1]);
        int length = exif.length + 2;
        out.write(0xFF);
        out.write(0xE1);
        out.write((length >> 8) & 0xFF);
        out.write(length & 0xFF);
        out.writeBytes(exif);
        out.write(plain, 2, plain.length - 2);
        return out.toByteArray();
    }

    private static boolean hasExif(byte[] bytes) throws Exception {
        Metadata metadata = ImageMetadataReader.readMetadata(new ByteArrayInputStream(bytes));
        return metadata.getFirstDirectoryOfType(ExifIFD0Directory.class) != null;
    }
}
