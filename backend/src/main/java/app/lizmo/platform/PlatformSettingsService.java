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
     * The oldest version of the Android app allowed to carry on.
     *
     * <p>A version name rather than a build number, because this is what an
     * operator has in front of them: it is what the store lists, what the
     * about screen shows, and what somebody reads off a phone when they ring
     * up. A field nobody can fill in confidently is one that gets the wrong
     * number typed into it.
     *
     * <p>Kept per platform because the two drift apart on their own. An iOS
     * release can sit in review for a week after the Android one has shipped,
     * and a minimum that stopped both at once would turn away every iPhone
     * for a fix they cannot yet install.
     *
     * <p>Blank -- what an operator who has never set one has -- means that
     * platform is not checked at all.
     */
    public static final String MINIMUM_ANDROID_VERSION = "minimum_app_version_android";

    /** The same for iOS. See {@link #MINIMUM_ANDROID_VERSION}. */
    public static final String MINIMUM_IOS_VERSION = "minimum_app_version_ios";

    /** Where an Android phone goes to get a newer one. */
    public static final String ANDROID_UPDATE_URL = "android_update_url";

    /** The same for iOS, empty until there is an app there to point at. */
    public static final String IOS_UPDATE_URL = "ios_update_url";

    @Transactional(readOnly = true)
    public String minimumAndroidVersion() {
        return text(MINIMUM_ANDROID_VERSION);
    }

    @Transactional(readOnly = true)
    public String minimumIosVersion() {
        return text(MINIMUM_IOS_VERSION);
    }

    @Transactional
    public String changeMinimumAndroidVersion(String value, UUID admin) {
        return changeMinimumVersion(MINIMUM_ANDROID_VERSION, value, admin);
    }

    @Transactional
    public String changeMinimumIosVersion(String value, UUID admin) {
        return changeMinimumVersion(MINIMUM_IOS_VERSION, value, admin);
    }

    @Transactional(readOnly = true)
    public String androidUpdateUrl() {
        return text(ANDROID_UPDATE_URL);
    }

    @Transactional(readOnly = true)
    public String iosUpdateUrl() {
        return text(IOS_UPDATE_URL);
    }

    @Transactional
    public String changeAndroidUpdateUrl(String value, UUID admin) {
        return changeUpdateUrl(ANDROID_UPDATE_URL, value, admin);
    }

    @Transactional
    public String changeIosUpdateUrl(String value, UUID admin) {
        return changeUpdateUrl(IOS_UPDATE_URL, value, admin);
    }

    /**
     * Digits and dots, up to three parts: 1, 1.2, 1.1.1.
     *
     * <p>Strict because the phone has to compare it. Something it cannot read
     * -- "v1.1.1", "1.0.0-beta", a date -- is refused here rather than being
     * stored and quietly ignored by every app that fetches it, which is a
     * minimum an operator believes is in force and is not.
     *
     * <p>Blank clears it, which is how a platform stops being checked.
     */
    private String changeMinimumVersion(String key, String value, UUID admin) {
        String version = value == null ? "" : value.trim();
        if (!version.isEmpty() && !version.matches("\\d{1,5}(\\.\\d{1,5}){0,2}")) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED,
                    "A version is digits and dots, like 1.1.1.");
        }
        return save(key, version, admin);
    }

    private String text(String key) {
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
        return save(key, link, admin);
    }

    /** Null back rather than empty: nothing set and set to nothing are one state. */
    private String save(String key, String value, UUID admin) {
        PlatformSetting setting = settings.findById(key)
                .orElseGet(() -> new PlatformSetting(key, value, admin));
        setting.change(value, admin);
        settings.save(setting);
        return value.isEmpty() ? null : value;
    }
}
