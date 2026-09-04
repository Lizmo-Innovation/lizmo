package app.lizmo.config;

import java.net.URI;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3ClientBuilder;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
public class S3Config {

    @Bean
    S3Client s3Client(S3Properties props) {
        S3ClientBuilder builder = S3Client.builder().region(Region.of(props.region()));
        if (usesAnEndpointOfItsOwn(props)) {
            // LocalStack and Supabase both require path-style addressing
            builder.endpointOverride(URI.create(props.endpoint())).forcePathStyle(true);
        }
        return builder.build();
    }

    /**
     * Signs the URLs that serve private objects.
     *
     * <p>A separate client from the one above: the presigner never talks to S3,
     * it only computes a signature, and it needs the same endpoint override so
     * that a URL it signs for LocalStack points at LocalStack.
     *
     * <p>And the same path-style setting, which it did not have. Left off, the
     * presigner signs a virtual-host URL — the bucket moved into the hostname —
     * so a signed link for Supabase would point at a host that does not exist.
     * LocalStack resolves both shapes, which is why this was invisible locally
     * and would have failed on the first photograph in production.
     */
    @Bean
    S3Presigner s3Presigner(S3Properties props) {
        S3Presigner.Builder builder = S3Presigner.builder().region(Region.of(props.region()));
        if (usesAnEndpointOfItsOwn(props)) {
            builder.endpointOverride(URI.create(props.endpoint()))
                    .serviceConfiguration(S3Configuration.builder()
                            .pathStyleAccessEnabled(true)
                            .build());
        }
        return builder.build();
    }

    /** Anything that is not AWS itself: LocalStack in development, Supabase in production. */
    private static boolean usesAnEndpointOfItsOwn(S3Properties props) {
        return props.endpoint() != null && !props.endpoint().isBlank();
    }
}
