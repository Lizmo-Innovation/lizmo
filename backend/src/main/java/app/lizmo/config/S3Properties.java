package app.lizmo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "lizmo.s3")
public record S3Properties(String bucket, String region, String endpoint) {}
