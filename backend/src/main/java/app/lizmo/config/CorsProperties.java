package app.lizmo.config;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * @param allowedOrigins exact origins permitted to call the API from a browser.
 *                       The admin web app needs this; the mobile apps do not,
 *                       since CORS is a browser-only concern.
 */
@ConfigurationProperties(prefix = "lizmo.cors")
public record CorsProperties(List<String> allowedOrigins) {
}
