package app.lizmo.config;

import java.net.URI;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3ClientBuilder;

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
}
