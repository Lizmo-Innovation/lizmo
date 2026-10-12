package app.lizmo.push;

import java.util.List;

/** Hands a message to whatever delivers it to phones. */
public interface PushSender {

    /**
     * Sends to each token. Never throws: a push is a copy of a notification
     * already recorded, and failing to deliver the copy must not fail the
     * thing that raised it.
     *
     * @return tokens Firebase says will never be delivered to again -- the app
     *         uninstalled, its data cleared -- for the caller to forget.
     */
    List<String> send(List<String> tokens, PushMessage message);
}
