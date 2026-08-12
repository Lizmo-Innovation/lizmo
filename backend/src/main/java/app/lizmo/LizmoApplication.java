package app.lizmo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class LizmoApplication {
    public static void main(String[] args) {
        SpringApplication.run(LizmoApplication.class, args);
    }
}
