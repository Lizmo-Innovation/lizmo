package app.lizmo.config;

import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * The clock everything time-dependent reads.
 *
 * <p>A bean rather than Instant.now() scattered through services, so a rule
 * measured in minutes or days can be tested by moving time instead of waiting
 * for it. UTC because a code expiring at a different moment depending on where
 * the server sits is a bug nobody finds until they travel.
 */
@Configuration
public class ClockConfig {

    @Bean
    Clock clock() {
        return Clock.systemUTC();
    }
}
