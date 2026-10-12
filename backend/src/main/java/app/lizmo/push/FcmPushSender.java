package app.lizmo.push;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.http.HttpClient;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;

/**
 * Firebase Cloud Messaging, over its HTTP API.
 *
 * <p>Not the Firebase Admin SDK, which brings Firestore, Cloud Storage and
 * gRPC along with it -- a great deal of start-up time for a server that
 * already takes ten seconds to wake. Two HTTP calls do the whole job.
 *
 * <p>And no key file. On Cloud Run the metadata server hands out an access
 * token for the service account the API runs as, which is allowed to send
 * (roles/firebasecloudmessaging.admin, in Terraform). Firebase was added to
 * this same project, so nothing else is needed.
 */
@Component
@ConditionalOnProperty(prefix = "lizmo.push", name = "enabled", havingValue = "true")
public class FcmPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(FcmPushSender.class);

    static final String METADATA_TOKEN = "http://metadata.google.internal/computeMetadata/v1/"
            + "instance/service-accounts/default/token";

    /** Short: a push is never worth holding up the request that raised it. */
    private static final Duration TIMEOUT = Duration.ofSeconds(5);

    private final RestClient http;
    private final String endpoint;
    private final Clock clock;

    private String accessToken;
    private Instant accessTokenExpires = Instant.EPOCH;

    @Autowired
    public FcmPushSender(PushProperties properties, RestClient.Builder builder, Clock clock) {
        this(properties, builder
                .requestFactory(timed())
                .build(), clock);
    }

    /** For tests, which hand in a client bound to a mock server. */
    FcmPushSender(PushProperties properties, RestClient http, Clock clock) {
        this.http = http;
        this.endpoint = "https://fcm.googleapis.com/v1/projects/%s/messages:send"
                .formatted(properties.firebaseProject());
        this.clock = clock;
    }

    private static JdkClientHttpRequestFactory timed() {
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(
                HttpClient.newBuilder().connectTimeout(TIMEOUT).build());
        factory.setReadTimeout(TIMEOUT);
        return factory;
    }

    @Override
    public List<String> send(List<String> tokens, PushMessage message) {
        List<String> dead = new ArrayList<>();
        String bearer;
        try {
            bearer = bearer();
        } catch (RuntimeException failed) {
            log.warn("Push not sent: no access token from the metadata server", failed);
            return dead;
        }

        for (String token : tokens) {
            try {
                http.post()
                        .uri(endpoint)
                        .header("Authorization", "Bearer " + bearer)
                        .body(Map.of("message", messageFor(token, message)))
                        .retrieve()
                        .toBodilessEntity();
            } catch (HttpClientErrorException refused) {
                if (isGone(refused)) {
                    dead.add(token);
                } else {
                    log.warn("Push refused: {} {}", refused.getStatusCode(),
                            refused.getResponseBodyAsString());
                }
            } catch (RuntimeException failed) {
                log.warn("Push not sent", failed);
            }
        }
        return dead;
    }

    /**
     * The message for one phone.
     *
     * <p>A notification part, so Android shows it when the app is closed, and
     * a data part, so a tap opens the right screen. High priority: these are
     * things a person is waiting on, and Android may otherwise hold them.
     */
    static Map<String, Object> messageFor(String token, PushMessage message) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("token", token);
        body.put("notification", Map.of(
                "title", message.title() == null ? "" : message.title(),
                "body", message.body() == null ? "" : message.body()));
        body.put("data", message.data());
        body.put("android", Map.of("priority", "HIGH"));
        return body;
    }

    /**
     * Whether Firebase means this phone is gone for good, rather than that
     * this one message was wrong.
     */
    static boolean isGone(HttpClientErrorException refused) {
        int status = refused.getStatusCode().value();
        String said = refused.getResponseBodyAsString();
        return status == 404
                || said.contains("UNREGISTERED")
                || (status == 400 && said.contains("registration token"));
    }

    /** The service account's access token, reused until shortly before it lapses. */
    private synchronized String bearer() {
        Instant now = clock.instant();
        if (accessToken == null || now.isAfter(accessTokenExpires)) {
            JsonNode granted = http.get()
                    .uri(METADATA_TOKEN)
                    .header("Metadata-Flavor", "Google")
                    .retrieve()
                    .body(JsonNode.class);
            accessToken = granted.get("access_token").asText();
            long life = granted.path("expires_in").asLong(300);
            accessTokenExpires = now.plusSeconds(Math.max(life - 60, 30));
        }
        return accessToken;
    }
}
