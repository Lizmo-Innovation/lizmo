package app.lizmo.jobs;

import app.lizmo.platform.billing.PlatformBillingService;
import app.lizmo.billing.RentReminderService;
import io.swagger.v3.oas.annotations.Hidden;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Work that runs on a clock rather than because somebody asked.
 *
 * <p>Hidden from the API docs: these are not part of the app's interface, and
 * publishing them would advertise paths whose only defence is a token check.
 *
 * <p>Every method authorises the caller itself rather than relying on the path
 * prefix. Cloud Run serves /internal/ as publicly as anything else.
 */
@Hidden
@RestController
@RequestMapping("/internal/jobs")
public class InternalJobController {

    private final JobAuthoriser authoriser;
    private final RentReminderService reminders;
    private final PlatformBillingService platformBilling;

    public InternalJobController(
            JobAuthoriser authoriser,
            RentReminderService reminders,
            PlatformBillingService platformBilling) {
        this.authoriser = authoriser;
        this.reminders = reminders;
        this.platformBilling = platformBilling;
    }

    /**
     * Tells tenants rent is coming, and that it is late.
     *
     * @return how many were sent. A run that sent nothing and a run that failed
     *         look the same in a scheduler log otherwise.
     */
    @PostMapping("/rent-reminders")
    public Map<String, Integer> rentReminders(HttpServletRequest request) {
        authoriser.requireScheduler(request);
        return Map.of("sent", reminders.run());
    }

    /**
     * Monthly, on the 1st: raises each property's Lizmo invoice.
     *
     * @return how many were raised
     */
    @PostMapping("/platform-billing-snapshot")
    public Map<String, Integer> platformBillingSnapshot(HttpServletRequest request) {
        authoriser.requireScheduler(request);
        return Map.of("raised", platformBilling.snapshot());
    }

    /**
     * Daily: warns about overdue invoices, and locks properties thirty days on.
     *
     * @return how many were warned and locked
     */
    @PostMapping("/platform-billing-enforcement")
    public Map<String, Integer> platformBillingEnforcement(HttpServletRequest request) {
        authoriser.requireScheduler(request);
        return platformBilling.enforce();
    }
}
