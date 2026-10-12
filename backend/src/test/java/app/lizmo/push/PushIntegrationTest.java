package app.lizmo.push;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import app.lizmo.notification.NotificationEntityType;
import app.lizmo.notification.NotificationService;
import app.lizmo.notification.NotificationType;
import app.lizmo.support.Accounts;
import app.lizmo.support.IntegrationTest;
import app.lizmo.support.RecordingPushSender;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Notifications reaching phones.
 *
 * <p>The same notifications as the bell -- each written to be read on a lock
 * screen -- sent to every phone the person is signed in on, once whatever
 * they announce has actually happened.
 */
class PushIntegrationTest extends IntegrationTest {

    @Autowired
    private RecordingPushSender pushes;

    @Autowired
    private NotificationService notifications;

    @Autowired
    private DeviceTokenRepository devices;

    @Autowired
    private TransactionTemplate transactions;

    private Accounts.Account ana;
    private Accounts.Account bea;

    @BeforeEach
    void setUp() {
        ana = accounts.tenant("ana");
        bea = accounts.tenant("bea");
    }

    // ---- phones ---------------------------------------------------------------------

    @Test
    void a_registered_phone_is_pushed_to() throws Exception {
        String phone = register(ana, "ana-phone");

        raiseFor(ana, "Your landlord sent a message");

        assertThat(pushes.to(phone)).hasSize(1);
        assertThat(pushes.to(phone).get(0).message().title())
                .isEqualTo("Your landlord sent a message");
    }

    @Test
    void every_phone_they_are_signed_in_on_is_pushed_to() throws Exception {
        String phone = register(ana, "ana-phone");
        String tablet = register(ana, "ana-tablet");

        raiseFor(ana, "Rent is due soon");

        assertThat(pushes.to(phone)).hasSize(1);
        assertThat(pushes.to(tablet)).hasSize(1);
    }

    @Test
    void nobody_else_is_pushed_to() throws Exception {
        register(ana, "ana-phone");
        String beas = register(bea, "bea-phone");

        raiseFor(ana, "Rent is due soon");

        assertThat(pushes.to(beas)).isEmpty();
    }

    /** Registered after every sign-in: the same phone twice is one phone. */
    @Test
    void registering_twice_is_one_phone() throws Exception {
        String phone = register(ana, "ana-phone");
        register(ana, "ana-phone");

        raiseFor(ana, "Rent is due soon");

        assertThat(pushes.to(phone)).hasSize(1);
    }

    /** Somebody else signed in on that phone: the last person stops being told. */
    @Test
    void a_phone_follows_whoever_signed_in_on_it() throws Exception {
        String phone = "shared-phone-" + ana.id();
        registerToken(ana, phone);
        registerToken(bea, phone);

        raiseFor(ana, "For Ana");
        raiseFor(bea, "For Bea");

        assertThat(pushes.to(phone)).extracting(sent -> sent.message().title())
                .containsExactly("For Bea");
    }

    @Test
    void signing_out_stops_the_pushes() throws Exception {
        String phone = register(ana, "ana-phone");

        mvc.perform(delete("/api/v1/me/devices")
                        .param("token", phone)
                        .header("Authorization", "Bearer " + ana.token()))
                .andExpect(status().isNoContent());

        raiseFor(ana, "Rent is due soon");
        assertThat(pushes.to(phone)).isEmpty();
    }

    /** A token is no key to anybody else's phones. */
    @Test
    void nobody_can_sign_somebody_else_out() throws Exception {
        String phone = register(ana, "ana-phone");

        mvc.perform(delete("/api/v1/me/devices")
                        .param("token", phone)
                        .header("Authorization", "Bearer " + bea.token()))
                .andExpect(status().isNoContent());

        raiseFor(ana, "Rent is due soon");
        assertThat(pushes.to(phone)).hasSize(1);
    }

    @Test
    void a_phone_has_to_be_named() throws Exception {
        mvc.perform(put("/api/v1/me/devices")
                        .header("Authorization", "Bearer " + ana.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"\",\"platform\":\"ANDROID\"}"))
                .andExpect(status().isBadRequest());
    }

    // ---- when ---------------------------------------------------------------------------

    /**
     * Raised in the middle of other work; if that is rolled back, what the
     * notification announces never happened, and no phone may hear of it.
     */
    @Test
    void nothing_is_pushed_about_something_that_was_rolled_back() throws Exception {
        String phone = register(ana, "ana-phone");

        transactions.executeWithoutResult(status -> {
            notifications.raise(ana.id(), NotificationType.PAYMENT_CONFIRMED,
                    "Your payment was confirmed", "P2500 for October 2026. Thank you.",
                    null, null);
            status.setRollbackOnly();
        });

        assertThat(pushes.to(phone)).isEmpty();
    }

    @Test
    void it_is_pushed_once_the_work_that_raised_it_commits() throws Exception {
        String phone = register(ana, "ana-phone");

        transactions.executeWithoutResult(status ->
                notifications.raise(ana.id(), NotificationType.PAYMENT_CONFIRMED,
                        "Your payment was confirmed", "P2500 for October 2026. Thank you.",
                        null, null));

        assertThat(pushes.to(phone)).hasSize(1);
    }

    // ---- what it carries -----------------------------------------------------------------

    /** Enough for the app to open the same screen a tap in the bell opens. */
    @Test
    void a_push_carries_what_it_is_about() throws Exception {
        String phone = register(ana, "ana-phone");
        UUID thread = UUID.randomUUID();

        notifications.raise(ana.id(), NotificationType.INQUIRY_MESSAGE,
                "Your landlord sent a message", "There is a new message about Sunrise.",
                NotificationEntityType.INQUIRY, thread);

        var data = pushes.to(phone).get(0).message().data();
        assertThat(data.get("type")).isEqualTo("INQUIRY_MESSAGE");
        assertThat(data.get("relatedEntityType")).isEqualTo("INQUIRY");
        assertThat(data.get("relatedEntityId")).isEqualTo(thread.toString());
        assertThat(data.get("notificationId")).isNotBlank();
    }

    // ---- phones that are gone ---------------------------------------------------------

    /** Uninstalled, or its data cleared: never sent to again. */
    @Test
    void a_phone_firebase_says_is_gone_is_forgotten() throws Exception {
        String phone = register(ana, "ana-old-phone");
        pushes.uninstalled(phone);

        raiseFor(ana, "Rent is due soon");

        assertThat(devices.findByToken(phone)).isEmpty();
    }

    // ---- fixtures ---------------------------------------------------------------------

    /** @return the token, made unique to this test so the shared recorder is not confused. */
    private String register(Accounts.Account who, String name) throws Exception {
        String token = name + "-" + who.id();
        registerToken(who, token);
        return token;
    }

    private void registerToken(Accounts.Account who, String token) throws Exception {
        mvc.perform(put("/api/v1/me/devices")
                        .header("Authorization", "Bearer " + who.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"%s\",\"platform\":\"ANDROID\"}".formatted(token)))
                .andExpect(status().isNoContent());
    }

    private void raiseFor(Accounts.Account who, String title) {
        notifications.raise(who.id(), NotificationType.RENT_DUE_REMINDER, title,
                "P2500 for October 2026, due on 2026-10-05.", null, null);
    }
}
