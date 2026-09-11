package app.lizmo.maintenance;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Something broken, as a tenant reported it, and what has happened since.
 *
 * <p>Called a report in the code rather than a request, because the app already
 * has a MaintenanceRequest: the flag that takes a bed or a unit out of service.
 * The table keeps its original name.
 *
 * <p>Plain text on purpose, as the spec has it: no categories, no priorities,
 * no vendor. A tenant describes the problem the way they would to the
 * landlord's face.
 *
 * <p>The methods below only move the status. Whether a move is allowed is the
 * service's question, because the answer goes back to a person as a sentence.
 */
@Entity
@Table(name = "maintenance_requests")
public class MaintenanceReport {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "lease_id", nullable = false, updatable = false)
    private UUID leaseId;

    @Column(name = "unit_id", nullable = false, updatable = false)
    private UUID unitId;

    @Column(name = "bed_id", updatable = false)
    private UUID bedId;

    @Column(name = "submitted_by", nullable = false, updatable = false)
    private UUID submittedBy;

    @Column(nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MaintenanceStatus status = MaintenanceStatus.SUBMITTED;

    @Column(name = "landlord_remarks")
    private String landlordRemarks;

    @Column(name = "reopen_reason")
    private String reopenReason;

    @Column(name = "submitted_at", nullable = false, updatable = false)
    private Instant submittedAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "resolved_at")
    private Instant resolvedAt;

    @Column(name = "reopened_at")
    private Instant reopenedAt;

    @Column(name = "closed_at")
    private Instant closedAt;

    protected MaintenanceReport() {
    }

    public MaintenanceReport(
            UUID leaseId, UUID unitId, UUID bedId, UUID submittedBy,
            String description, Instant at) {
        this.leaseId = leaseId;
        this.unitId = unitId;
        this.bedId = bedId;
        this.submittedBy = submittedBy;
        this.description = description;
        this.submittedAt = at;
        this.updatedAt = at;
    }

    /** The tenant taking it back. */
    public void withdraw(Instant at) {
        this.status = MaintenanceStatus.WITHDRAWN;
        this.updatedAt = at;
    }

    /** The landlord starting on it, with anything they want to say. */
    public void start(String remarks, Instant at) {
        this.status = MaintenanceStatus.IN_PROGRESS;
        remark(remarks);
        this.updatedAt = at;
    }

    /** The landlord saying it is fixed. The tenant has the last word. */
    public void resolve(String remarks, Instant at) {
        this.status = MaintenanceStatus.RESOLVED;
        remark(remarks);
        this.resolvedAt = at;
        this.updatedAt = at;
    }

    /** The tenant agreeing it is fixed. */
    public void close(Instant at) {
        this.status = MaintenanceStatus.CLOSED;
        this.closedAt = at;
        this.updatedAt = at;
    }

    /**
     * The tenant saying it is still broken, and why.
     *
     * <p>Back to SUBMITTED rather than IN_PROGRESS, so it lands in front of the
     * landlord again as something nobody is yet dealing with -- because, as far
     * as the tenant can tell, nobody is.
     */
    public void reopen(String reason, Instant at) {
        this.status = MaintenanceStatus.SUBMITTED;
        this.reopenReason = reason;
        this.reopenedAt = at;
        this.resolvedAt = null;
        this.updatedAt = at;
    }

    private void remark(String remarks) {
        // A later remark replaces an earlier one; blank says nothing and leaves
        // what was said before in place.
        if (remarks != null && !remarks.isBlank()) {
            this.landlordRemarks = remarks.trim();
        }
    }

    public UUID getId() {
        return id;
    }

    public UUID getLeaseId() {
        return leaseId;
    }

    public UUID getUnitId() {
        return unitId;
    }

    public UUID getBedId() {
        return bedId;
    }

    public UUID getSubmittedBy() {
        return submittedBy;
    }

    public String getDescription() {
        return description;
    }

    public MaintenanceStatus getStatus() {
        return status;
    }

    public String getLandlordRemarks() {
        return landlordRemarks;
    }

    public String getReopenReason() {
        return reopenReason;
    }

    public Instant getSubmittedAt() {
        return submittedAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public Instant getResolvedAt() {
        return resolvedAt;
    }

    public Instant getReopenedAt() {
        return reopenedAt;
    }

    public Instant getClosedAt() {
        return closedAt;
    }
}
