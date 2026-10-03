package app.lizmo.platform;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/**
 * Settings an operator changes from the console.
 *
 * <p>Narrow on purpose: every setting is named here, with a default, rather
 * than being whatever string somebody put in the table. A key/value store that
 * accepts any key becomes a place where features hide.
 */
@Service
public class PlatformSettingsService {

    /** Where somebody writes when they want their account deleted. */
    public static final String SUPPORT_EMAIL = "support_email";

    /** Used until an admin sets one, and if the row is ever missing. */
    private static final String DEFAULT_SUPPORT_EMAIL = "lizmodev@gmail.com";

    private final PlatformSettingRepository settings;

    public PlatformSettingsService(PlatformSettingRepository settings) {
        this.settings = settings;
    }

    @Transactional(readOnly = true)
    public String supportEmail() {
        return settings.findById(SUPPORT_EMAIL)
                .map(PlatformSetting::getValue)
                .filter(StringUtils::hasText)
                .orElse(DEFAULT_SUPPORT_EMAIL);
    }

    @Transactional
    public String changeSupportEmail(String value, UUID admin) {
        String email = value == null ? "" : value.trim();

        // Checked because this address is published on a public page and told
        // to strangers. A typo here is a deletion request nobody receives.
        if (!email.contains("@") || email.startsWith("@") || email.endsWith("@")) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "That does not look like an email address.");
        }

        PlatformSetting setting = settings.findById(SUPPORT_EMAIL)
                .orElseGet(() -> new PlatformSetting(SUPPORT_EMAIL, email, admin));
        setting.change(email, admin);
        settings.save(setting);
        return email;
    }

    /**
     * The note shown to landlords under Lizmo's payment channels.
     *
     * <p>Once the only payment details there were, as free text; the key keeps
     * that name so what an admin already wrote carries over.
     */
    public static final String PAYMENT_INSTRUCTIONS = "payment_instructions";

    /** Null until an admin has written some. There is no sensible default. */
    @Transactional(readOnly = true)
    public String paymentInstructions() {
        return settings.findById(PAYMENT_INSTRUCTIONS)
                .map(PlatformSetting::getValue)
                .filter(StringUtils::hasText)
                .orElse(null);
    }

    @Transactional
    public String changePaymentInstructions(String value, UUID admin) {
        String text = value == null ? "" : value.trim();
        if (text.length() > 1000) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Keep the payment details under 1000 characters.");
        }
        PlatformSetting setting = settings.findById(PAYMENT_INSTRUCTIONS)
                .orElseGet(() -> new PlatformSetting(PAYMENT_INSTRUCTIONS, text, admin));
        setting.change(text, admin);
        settings.save(setting);
        return text.isEmpty() ? null : text;
    }

    // ---- the app people are running ------------------------------------------------

    /**
     * The oldest build of the mobile app allowed to carry on.
     *
     * <p>A build number rather than a version name: it only ever goes up, the
     * stores already count it, and "1.10" against "1.9" is a comparison
     * somebody has to get right. Zero, the default, means nobody is turned
     * away -- a setting nobody has filled in should not lock out every phone.
     */
    public static final String MINIMUM_APP_BUILD = "minimum_app_build";

    /** Where an Android phone goes to get a newer one. */
    public static final String ANDROID_UPDATE_URL = "android_update_url";

    /** The same for iOS, empty until there is an app there to point at. */
    public static final String IOS_UPDATE_URL = "ios_update_url";

    @Transactional(readOnly = true)
    public int minimumAppBuild() {
        return settings.findById(MINIMUM_APP_BUILD)
                .map(PlatformSetting::getValue)
                .filter(StringUtils::hasText)
                .map(value -> {
                    try {
                        return Integer.parseInt(value.trim());
                    } catch (NumberFormatException notANumber) {
                        // Stored by an older console, or by hand. Nobody is
                        // locked out over something unreadable.
                        return 0;
                    }
                })
                .orElse(0);
    }

    @Transactional
    public int changeMinimumAppBuild(Integer value, UUID admin) {
        int build = value == null ? 0 : value;
        if (build < 0) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A build number cannot be negative.");
        }
        return (int) store(MINIMUM_APP_BUILD, String.valueOf(build), admin, Integer::parseInt);
    }

    @Transactional(readOnly = true)
    public String androidUpdateUrl() {
        return url(ANDROID_UPDATE_URL);
    }

    @Transactional(readOnly = true)
    public String iosUpdateUrl() {
        return url(IOS_UPDATE_URL);
    }

    @Transactional
    public String changeAndroidUpdateUrl(String value, UUID admin) {
        return changeUpdateUrl(ANDROID_UPDATE_URL, value, admin);
    }

    @Transactional
    public String changeIosUpdateUrl(String value, UUID admin) {
        return changeUpdateUrl(IOS_UPDATE_URL, value, admin);
    }

    private String url(String key) {
        return settings.findById(key)
                .map(PlatformSetting::getValue)
                .filter(StringUtils::hasText)
                .orElse(null);
    }

    /**
     * Blank clears it, which is how an operator stops pointing at a store that
     * has not published yet. Anything kept has to be a link a phone can open:
     * an app told to update, with an address it cannot follow, is a dead end.
     */
    private String changeUpdateUrl(String key, String value, UUID admin) {
        String link = value == null ? "" : value.trim();
        if (!link.isEmpty() && !link.startsWith("https://") && !link.startsWith("http://")) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "An update link has to start with https://");
        }
        if (link.length() > 500) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "Keep the update link under 500 characters.");
        }
        PlatformSetting setting = settings.findById(key)
                .orElseGet(() -> new PlatformSetting(key, link, admin));
        setting.change(link, admin);
        settings.save(setting);
        return link.isEmpty() ? null : link;
    }

    private long store(String key, String value, UUID admin,
            java.util.function.ToIntFunction<String> read) {
        PlatformSetting setting = settings.findById(key)
                .orElseGet(() -> new PlatformSetting(key, value, admin));
        setting.change(value, admin);
        settings.save(setting);
        return read.applyAsInt(value);
    }
}
