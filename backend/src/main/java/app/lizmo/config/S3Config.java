package app.lizmo.config;

import java.net.URI;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3ClientBuilder;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
public class S3Config {

    @Bean
    S3Client s3Client(S3Properties props) {
        S3ClientBuilder builder = S3Client.builder().region(Region.of(props.region()));
        if (props.endpoint() != null && !props.endpoint().isBlank()) {
            // LocalStack requires path-style addressing
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
     */
    @Bean
    S3Presigner s3Presigner(S3Properties props) {
        S3Presigner.Builder builder = S3Presigner.builder().region(Region.of(props.region()));
        if (props.endpoint() != null && !props.endpoint().isBlank()) {
            builder.endpointOverride(URI.create(props.endpoint()));
        }
        return builder.build();
    }
}
