package app.lizmo.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import org.junit.jupiter.api.Test;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

/**
 * Where a signed URL actually points.
 *
 * <p>There are two ways to address an S3 object: path-style, where the bucket
 * is the first segment of the path, and virtual-host style, where it is a
 * subdomain. The client was configured for the first and the presigner was
 * left on the default, which is the second.
 *
 * <p>That gap is invisible in development — LocalStack answers to both — and
 * fatal in production, where {@code lizmo-uploads.cbbipywzrbksbnglgncn
 * .storage.supabase.co} is a hostname that does not resolve. Every tenant's ID
 * photograph would have come back as a broken link on the first day.
 *
 * <p>No network and no credentials: signing is arithmetic, so this asserts the
 * shape of the URL that arithmetic produces.
 */
class S3PresignedUrlShapeTest {

    private static final String ENDPOINT =
            "https://cbbipywzrbksbnglgncn.storage.supabase.co/storage/v1/s3";
    private static final String BUCKET = "lizmo-uploads";
    private static final String KEY = "tenant-documents/ana/valid-id.jpg";

    private String presignedUrlFor(String endpoint) {
        // The SDK's default credential chain would go looking for a real
        // profile; these are enough to sign with and are never sent anywhere.
        System.setProperty("aws.accessKeyId", "test-access-key");
        System.setProperty("aws.secretAccessKey", "test-secret-key");
        try {
            S3Presigner presigner = new S3Config()
                    .s3Presigner(new S3Properties(BUCKET, "ap-northeast-2", endpoint));
            return presigner.presignGetObject(GetObjectPresignRequest.builder()
                            .signatureDuration(Duration.ofMinutes(5))
                            .getObjectRequest(GetObjectRequest.builder()
                                    .bucket(BUCKET)
                                    .key(KEY)
                                    .build())
                            .build())
                    .url()
                    .toString();
        } finally {
            System.clearProperty("aws.accessKeyId");
            System.clearProperty("aws.secretAccessKey");
        }
    }

    @Test
    void a_signed_url_for_supabase_keeps_the_bucket_in_the_path() {
        String url = presignedUrlFor(ENDPOINT);

        assertThat(url).startsWith(ENDPOINT + "/" + BUCKET + "/" + KEY);
        // The failure this test exists for: the bucket promoted into a hostname
        // that was never registered.
        assertThat(url).doesNotContain(BUCKET + ".cbbipywzrbksbnglgncn");
    }

    @Test
    void it_is_still_a_signed_url_and_not_a_bare_link() {
        // Path-style must not have quietly cost us the signature: the bucket is
        // private, so an unsigned URL is a 403 rather than a leak — but it is
        // still a broken photograph.
        assertThat(presignedUrlFor(ENDPOINT))
                .contains("X-Amz-Signature=")
                .contains("X-Amz-Expires=300");
    }

    @Test
    void against_aws_itself_nothing_is_forced() {
        // No endpoint means real S3, where virtual-host style is the norm and
        // path-style has been deprecated for years. The override is for the
        // stand-ins, not for everybody.
        String url = presignedUrlFor(null);

        assertThat(url).startsWith("https://" + BUCKET + ".s3.");
    }
}
