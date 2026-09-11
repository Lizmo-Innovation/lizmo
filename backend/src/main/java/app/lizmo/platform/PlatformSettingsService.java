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

    /** Where a landlord sends money to Lizmo: a GCash number, a bank account. */
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
}
