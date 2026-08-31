package app.lizmo.document;

import app.lizmo.lease.Lease;
import app.lizmo.lease.LeaseRepository;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Throws away tenant photographs a year after they stopped being needed.
 *
 * <p>Ariel's rule: keep until one year after the lease ends. Read literally
 * that is ambiguous, because documents belong to the tenant rather than to any
 * one lease — a person renting in two places has one ID, and deleting it when
 * the first tenancy ended would break the second.
 *
 * <p>So: a tenant's photographs go when they hold <em>no</em> active lease and
 * their most recent one ended more than a year ago. Somebody who never signed a
 * lease at all is left alone; they are still using the app, and their profile
 * is theirs.
 *
 * <p>The year exists because a dispute about a tenancy does not end the day the
 * tenant moves out. After that there is no reason to be holding a photograph of
 * somebody's identity document, and holding it is the only way to lose it.
 */
@Service
public class DocumentRetentionService {

    private static final Logger log = LoggerFactory.getLogger(DocumentRetentionService.class);

    /** How long after the last tenancy the photographs are kept. */
    static final int RETENTION_DAYS = 365;

    private final StoredDocumentRepository documents;
    private final DocumentStore store;
    private final LeaseRepository leases;

    public DocumentRetentionService(
            StoredDocumentRepository documents,
            DocumentStore store,
            LeaseRepository leases) {
        this.documents = documents;
        this.store = store;
        this.leases = leases;
    }

    /**
     * Once a day, in the small hours.
     *
     * <p>Nothing here is urgent to the minute — a document lingering a few
     * extra hours is not the risk this guards against — and running when
     * nobody is using the app keeps a long sweep out of anybody's way.
     */
    @Scheduled(cron = "0 30 3 * * *")
    public void purgeExpired() {
        int removed = purgeAsOf(LocalDate.now());
        if (removed > 0) {
            log.info("Removed {} tenant documents past their retention period", removed);
        }
    }

    /**
     * @param today taken as a parameter rather than read from the clock, so the
     *              rule can be tested without waiting a year or freezing time
     *              globally. The scheduled entry point above supplies the real
     *              date.
     * @return how many documents were removed
     */
    @Transactional
    public int purgeAsOf(LocalDate today) {
        LocalDate cutoff = today.minusDays(RETENTION_DAYS);

        int removed = 0;
        for (UUID tenantId : tenantsWithDocuments()) {
            if (!isPastRetention(tenantId, cutoff)) {
                continue;
            }
            for (StoredDocument document
                    : documents.findByOwnerTypeAndOwnerId(DocumentOwnerType.TENANT, tenantId)) {
                // The object first, then the row. The other order can leave a
                // file in the bucket that nothing points at any more, which is
                // exactly the thing this service exists to prevent.
                store.delete(document.getStorageKey());
                documents.delete(document);
                removed++;
            }
        }
        return removed;
    }

    /**
     * True when this tenant has finished renting and the year is up.
     *
     * <p>A tenant with any active lease is never past retention, whatever their
     * history: an ID is needed for the tenancy they are currently in.
     */
    private boolean isPastRetention(UUID tenantId, LocalDate cutoff) {
        List<Lease> history = leases.findByTenantIdOrderByStartDateDesc(tenantId);
        if (history.isEmpty()) {
            // Never rented anything. Their profile is their own, and nothing
            // here has expired because nothing ever started.
            return false;
        }

        LocalDate latestEnd = null;
        for (Lease lease : history) {
            if (lease.isActive()) {
                return false;
            }
            LocalDate end = lease.getEndDate();
            if (end == null) {
                // Closed without a date recorded. Treated as recent rather than
                // ancient: guessing old would delete somebody's ID early.
                return false;
            }
            if (latestEnd == null || end.isAfter(latestEnd)) {
                latestEnd = end;
            }
        }

        return latestEnd != null && latestEnd.isBefore(cutoff);
    }

    private Set<UUID> tenantsWithDocuments() {
        Set<UUID> owners = new HashSet<>();
        for (StoredDocument document : documents.findByOwnerType(DocumentOwnerType.TENANT)) {
            owners.add(document.getOwnerId());
        }
        return owners;
    }
}
