package app.lizmo.push;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.ExpectedCount;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

/**
 * The two HTTP calls that send a push: an access token from Cloud Run's
 * metadata server, then a message to Firebase per phone.
 *
 * <p>Against a mock server, because there is no Firebase here. What this
 * cannot show is a real phone ringing; that is for the first APK.
 */
class FcmPushSenderTest {

    private static final String SEND =
            "https://fcm.googleapis.com/v1/projects/lizmo-test/messages:send";

    private static final PushMessage MESSAGE = new PushMessage(
            "Your landlord sent a message",
            "There is a new message about Sunrise Apartments.",
            Map.of("type", "INQUIRY_MESSAGE", "relatedEntityId", "thread-1"));

    private MockRestServiceServer server;
    private FcmPushSender sender;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder();
        server = MockRestServiceServer.bindTo(builder).build();
        sender = new FcmPushSender(
                new PushProperties(true, "lizmo-test"),
                builder.build(),
                Clock.fixed(Instant.parse("2026-10-12T08:00:00Z"), ZoneOffset.UTC));
    }

    private void tokenGranted(ExpectedCount times) {
        server.expect(times, requestTo(FcmPushSender.METADATA_TOKEN))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Metadata-Flavor", "Google"))
                .andRespond(withSuccess(
                        "{\"access_token\":\"granted\",\"expires_in\":3599,\"token_type\":\"Bearer\"}",
                        MediaType.APPLICATION_JSON));
    }

    @Test
    void a_message_reaches_firebase_as_the_service_account() {
        tokenGranted(ExpectedCount.once());
        server.expect(requestTo(SEND))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("Authorization", "Bearer granted"))
                .andExpect(jsonPath("$.message.token").value("phone-1"))
                .andExpect(jsonPath("$.message.notification.title")
                        .value("Your landlord sent a message"))
                .andExpect(jsonPath("$.message.notification.body")
                        .value("There is a new message about Sunrise Apartments."))
                .andExpect(jsonPath("$.message.data.type").value("INQUIRY_MESSAGE"))
                .andExpect(jsonPath("$.message.android.priority").value("HIGH"))
                .andRespond(withSuccess("{\"name\":\"projects/lizmo-test/messages/1\"}",
                        MediaType.APPLICATION_JSON));

        assertThat(sender.send(List.of("phone-1"), MESSAGE)).isEmpty();
        server.verify();
    }

    /** Asked for once and reused, not fetched again for every phone. */
    @Test
    void the_access_token_is_reused_until_it_lapses() {
        tokenGranted(ExpectedCount.once());
        server.expect(ExpectedCount.times(3), requestTo(SEND))
                .andRespond(withSuccess());

        sender.send(List.of("phone-1", "phone-2"), MESSAGE);
        sender.send(List.of("phone-3"), MESSAGE);

        server.verify();
    }

    /** Uninstalled, or its data cleared: reported, so it is never sent to again. */
    @Test
    void a_phone_firebase_says_is_gone_is_reported() {
        tokenGranted(ExpectedCount.once());
        server.expect(requestTo(SEND))
                .andExpect(jsonPath("$.message.token").value("phone-1"))
                .andRespond(withSuccess());
        server.expect(requestTo(SEND))
                .andExpect(jsonPath("$.message.token").value("phone-2"))
                .andRespond(withStatus(HttpStatus.NOT_FOUND).contentType(MediaType.APPLICATION_JSON)
                        .body("{\"error\":{\"code\":404,\"status\":\"NOT_FOUND\","
                                + "\"details\":[{\"errorCode\":\"UNREGISTERED\"}]}}"));

        assertThat(sender.send(List.of("phone-1", "phone-2"), MESSAGE))
                .containsExactly("phone-2");
    }

    /** A message Firebase refused for another reason says nothing about the phone. */
    @Test
    void any_other_refusal_keeps_the_phone() {
        tokenGranted(ExpectedCount.once());
        server.expect(requestTo(SEND))
                .andRespond(withStatus(HttpStatus.FORBIDDEN).contentType(MediaType.APPLICATION_JSON)
                        .body("{\"error\":{\"code\":403,\"status\":\"PERMISSION_DENIED\"}}"));

        assertThat(sender.send(List.of("phone-1"), MESSAGE)).isEmpty();
    }

    @Test
    void firebase_being_down_throws_nothing() {
        tokenGranted(ExpectedCount.once());
        server.expect(requestTo(SEND)).andRespond(withServerError());

        assertThat(sender.send(List.of("phone-1"), MESSAGE)).isEmpty();
    }

    /** Not on Cloud Run, or the metadata server not answering: nothing sent, nothing thrown. */
    @Test
    void no_access_token_sends_nothing_and_throws_nothing() {
        server.expect(requestTo(FcmPushSender.METADATA_TOKEN)).andRespond(withServerError());

        assertThat(sender.send(List.of("phone-1"), MESSAGE)).isEmpty();
        server.verify();
    }
}
