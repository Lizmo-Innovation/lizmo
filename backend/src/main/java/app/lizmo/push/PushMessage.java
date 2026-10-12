package app.lizmo.push;

import java.util.Map;

/**
 * What a phone is sent: the words on the lock screen, and what tapping it
 * should open.
 *
 * @param data string values only, as Firebase takes them: the notification's
 *             id, type and what it is about -- enough for the app to route the
 *             tap the same way a tap in the bell is routed.
 */
public record PushMessage(String title, String body, Map<String, String> data) {
}
