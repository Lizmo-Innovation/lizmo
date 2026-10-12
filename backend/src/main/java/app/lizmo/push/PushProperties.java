package app.lizmo.push;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Whether notifications go to phones as well as to the in-app bell.
 *
 * <p>Off unless switched on: locally and under test there is no Firebase to
 * reach, and a server that tried would spend every notification on a timeout.
 *
 * @param enabled         LIZMO_PUSH_ENABLED. On in Cloud Run.
 * @param firebaseProject the project Firebase was added to -- lizmo-test --
 *                        which is the one the API itself runs in.
 */
@ConfigurationProperties(prefix = "lizmo.push")
public record PushProperties(boolean enabled, String firebaseProject) {
}
