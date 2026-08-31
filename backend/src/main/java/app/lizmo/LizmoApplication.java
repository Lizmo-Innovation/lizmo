package app.lizmo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

// For the document retention sweep. Nothing else is scheduled yet.
@EnableScheduling
@SpringBootApplication
@ConfigurationPropertiesScan
public class LizmoApplication {
    public static void main(String[] args) {
        SpringApplication.run(LizmoApplication.class, args);
    }
}
