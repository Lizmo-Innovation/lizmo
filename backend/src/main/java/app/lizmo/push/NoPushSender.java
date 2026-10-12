package app.lizmo.push;

import java.util.List;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/** Sends nothing: locally, under test, and anywhere push is not switched on. */
@Component
@ConditionalOnProperty(prefix = "lizmo.push", name = "enabled", havingValue = "false",
        matchIfMissing = true)
public class NoPushSender implements PushSender {

    @Override
    public List<String> send(List<String> tokens, PushMessage message) {
        return List.of();
    }
}
