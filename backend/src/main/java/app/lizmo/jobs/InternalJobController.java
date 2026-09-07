package app.lizmo.jobs;

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

    public InternalJobController(
            JobAuthoriser authoriser, RentReminderService reminders) {
        this.authoriser = authoriser;
        this.reminders = reminders;
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
}
