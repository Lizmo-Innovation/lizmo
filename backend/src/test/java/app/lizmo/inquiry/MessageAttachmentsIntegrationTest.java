package app.lizmo.inquiry;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.document.DocumentOwnerType;
import app.lizmo.document.DocumentType;
import app.lizmo.document.StoredDocument;
import app.lizmo.document.StoredDocumentRepository;
import app.lizmo.support.Accounts;
import app.lizmo.support.InMemoryDocumentStore;
import app.lizmo.support.IntegrationTest;
import app.lizmo.user.AccountDeletionService;
import com.fasterxml.jackson.databind.JsonNode;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder;

/** Photos and PDFs in a conversation. */
class MessageAttachmentsIntegrationTest extends IntegrationTest {

    @Autowired
    private StoredDocumentRepository documents;

    @Autowired
    private InMemoryDocumentStore store;

    /**
     * Its own sweep rather than the whole retention run: that one, a year
     * ahead, would also take the IDs of tenants other tests go on to use.
     */
    @Autowired
    private MessageAttachments messageAttachments;

    @Autowired
    private AccountDeletionService closing;

    @Autowired
    private InquiryMessageRepository messages;

    private Accounts.Account elena;
    private Accounts.Account ana;
    private String thread;

    @BeforeEach
    void setUp() throws Exception {
        elena = accounts.landlord("Elena");
        ana = tenant("Ana");
        String property = json.readTree(mvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + elena.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Sunrise Apartments","address":"12 Mabini St",
                                 "type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}
                                """))
                .andReturn().getResponse().getContentAsString()).get("id").asText();
        thread = json.readTree(mvc.perform(post("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + ana.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"propertyId\":\"%s\"}".formatted(property)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString())
                .get("inquiry").get("id").asText();
    }

    @Test
    void a_photo_on_its_own_is_a_message() throws Exception {
        JsonNode sent = json.readTree(send(ana, null, photo("leak.png", "png"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString());

        assertThat(sent.get("body").asText()).isEmpty();
        JsonNode file = sent.get("attachments").get(0);
        assertThat(file.get("kind").asText()).isEqualTo("PHOTO");
        assertThat(file.get("url").asText()).isNotBlank();
        assertThat(file.get("previewUrl").asText()).isNotBlank();
        assertThat(file.get("previewUrl").asText()).isNotEqualTo(file.get("url").asText());

        // The landlord sees it in the thread, and the list says what it is.
        JsonNode read = read(elena);
        JsonNode last = read.get("messages").get(read.get("messages").size() - 1);
        assertThat(last.get("attachments").size()).isEqualTo(1);
        assertThat(lastMessage(elena)).isEqualTo("Photo");
    }

    /** Pixels in, pixels out: whatever the phone sent, a plain JPEG is kept. */
    @Test
    void a_photo_is_re_encoded_with_a_small_copy() throws Exception {
        send(ana, "The ceiling", photo("leak.png", "png"), photo("stain.jpg", "jpg"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.attachments.length()").value(2));

        List<StoredDocument> kept = mine();
        assertThat(kept).hasSize(4);
        assertThat(kept).allSatisfy(document -> {
            assertThat(document.getContentType()).isEqualTo("image/jpeg");
            assertThat(store.get(document.getStorageKey()).contentType()).isEqualTo("image/jpeg");
        });
        assertThat(kept.stream().filter(d -> d.getDocType() == DocumentType.MESSAGE_PREVIEW))
                .hasSize(2);
        assertThat(lastMessage(elena)).isEqualTo("The ceiling");
    }

    @Test
    void a_pdf_keeps_its_name() throws Exception {
        send(elena, null, pdf("house-rules.pdf"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.attachments[0].kind").value("PDF"))
                .andExpect(jsonPath("$.attachments[0].name").value("house-rules.pdf"));

        assertThat(lastMessage(ana)).isEqualTo("house-rules.pdf");
    }

    /** What is in it decides, not what it is called. */
    @Test
    void a_file_called_pdf_that_is_not_one_is_refused() throws Exception {
        send(ana, null, new MockMultipartFile("file1", "rules.pdf", "application/pdf",
                        "just some words".getBytes(StandardCharsets.UTF_8)))
                .andExpect(status().isBadRequest());
        assertThat(mine()).isEmpty();
    }

    @Test
    void a_pdf_goes_on_its_own() throws Exception {
        send(elena, null, pdf("rules.pdf"), photo("gate.png", "png"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Send a PDF on its own, in a message of its own."));
    }

    @Test
    void nothing_at_all_is_refused() throws Exception {
        send(ana, "   ").andExpect(status().isBadRequest());
    }

    @Test
    void only_the_two_of_them() throws Exception {
        send(accounts.landlord("Mario"), null, photo("x.png", "png"))
                .andExpect(status().isNotFound());
    }

    @Test
    void not_into_a_closed_conversation() throws Exception {
        mvc.perform(post("/api/v1/inquiries/" + thread + "/close")
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isOk());

        send(ana, null, photo("x.png", "png")).andExpect(status().isBadRequest());
    }

    /** Somebody closing their account takes their photos with them. */
    @Test
    void closing_an_account_removes_what_it_sent() throws Exception {
        send(ana, null, photo("leak.png", "png")).andExpect(status().isCreated());
        send(elena, null, pdf("rules.pdf")).andExpect(status().isCreated());

        closing.delete(ana.id());

        List<StoredDocument> left = mine();
        assertThat(left).hasSize(1);
        assertThat(left.get(0).getDocType()).isEqualTo(DocumentType.MESSAGE_FILE);
    }

    /** A conversation closed over a year ago, that never became a tenancy. */
    @Test
    void a_closed_conversation_lets_them_go_after_a_year() throws Exception {
        send(ana, null, photo("leak.png", "png")).andExpect(status().isCreated());

        messageAttachments.purgeAsOf(LocalDate.now().plusDays(400));
        assertThat(mine())
                .as("still open, so kept").hasSize(2);

        mvc.perform(post("/api/v1/inquiries/" + thread + "/close")
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isOk());
        messageAttachments.purgeAsOf(LocalDate.now().plusDays(30));
        assertThat(mine()).hasSize(2);

        List<String> keys = mine().stream()
                .map(StoredDocument::getStorageKey).toList();
        messageAttachments.purgeAsOf(LocalDate.now().plusDays(400));
        assertThat(mine()).isEmpty();
        assertThat(keys).allSatisfy(key -> assertThat(store.get(key)).isNull());
    }

    // ---- fixtures ----------------------------------------------------------

    /** What this test's conversation carries; other tests leave their own. */
    private List<StoredDocument> mine() {
        List<java.util.UUID> ids = messages.findByInquiryIdOrderBySentAtAsc(java.util.UUID.fromString(thread))
                .stream().map(InquiryMessage::getId).toList();
        return ids.isEmpty()
                ? List.of()
                : documents.findByOwnerTypeAndOwnerIdIn(DocumentOwnerType.INQUIRY_MESSAGE, ids);
    }

    private ResultActions send(Accounts.Account who, String body, MockMultipartFile... files)
            throws Exception {
        MockMultipartHttpServletRequestBuilder request =
                multipart("/api/v1/inquiries/" + thread + "/messages/files");
        for (MockMultipartFile file : files) {
            request.file(file);
        }
        if (body != null) {
            request.part(new MockPart("body", body.getBytes(StandardCharsets.UTF_8)));
        }
        return mvc.perform(request.header("Authorization", "Bearer " + who.token()));
    }

    private JsonNode read(Accounts.Account who) throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/inquiries/" + thread)
                        .header("Authorization", "Bearer " + who.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private String lastMessage(Accounts.Account who) throws Exception {
        return json.readTree(mvc.perform(get("/api/v1/inquiries")
                        .header("Authorization", "Bearer " + who.token()))
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8))
                .get(0).get("lastMessage").asText();
    }

    private int parts = 0;

    private MockMultipartFile photo(String name, String format) throws Exception {
        BufferedImage image = new BufferedImage(900, 600, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.ORANGE);
        g.fillRect(0, 0, 900, 600);
        g.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, format, out);
        parts++;
        return new MockMultipartFile("file" + parts, name,
                format.equals("png") ? "image/png" : "image/jpeg", out.toByteArray());
    }

    private MockMultipartFile pdf(String name) {
        parts++;
        return new MockMultipartFile("file" + parts, name, "application/pdf",
                "%PDF-1.4\n1 0 obj << >> endobj\ntrailer << >>\n%%EOF\n"
                        .getBytes(StandardCharsets.US_ASCII));
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
        return tenant;
    }
}
