package app.lizmo.support;

import app.lizmo.push.PushMessage;
import app.lizmo.push.PushSender;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Records what would have been pushed, instead of reaching Firebase.
 *
 * <p>Shared by every test in the suite, so a test reads only the pushes to
 * its own tokens rather than counting them all.
 */
public class RecordingPushSender implements PushSender {

    /** One phone's copy of one message. */
    public record Sent(String token, PushMessage message) {
    }

    private final List<Sent> sent = Collections.synchronizedList(new ArrayList<>());
    private final Set<String> gone = Collections.synchronizedSet(new HashSet<>());

    @Override
    public List<String> send(List<String> tokens, PushMessage message) {
        List<String> dead = new ArrayList<>();
        for (String token : tokens) {
            if (gone.contains(token)) {
                dead.add(token);
            } else {
                sent.add(new Sent(token, message));
            }
        }
        return dead;
    }

    /** What reached this phone, oldest first. */
    public List<Sent> to(String token) {
        synchronized (sent) {
            return sent.stream().filter(one -> one.token().equals(token)).toList();
        }
    }

    /** Makes Firebase report this phone as gone for good. */
    public void uninstalled(String token) {
        gone.add(token);
    }
}
