package app.lizmo.maintenance.dto;

import app.lizmo.maintenance.MaintenanceStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * A report, as either side sees it.
 *
 * <p>The same shape for both, because it is the same conversation read from
 * two ends -- a tenant reading the landlord's remark and a landlord reading the
 * tenant's description are looking at one record.
 *
 * @param reopened     whether the tenant has ever said it was still broken. A
 *                     reopened report is back to SUBMITTED, and a landlord
 *                     needs to know it is not new.
 * @param photoUrls    presigned, oldest first, and good for
 *                     {@code photoUrlsExpireInSeconds}.
 */
@Schema(description = "Something broken, and what has happened since")
public record MaintenanceReportResponse(
        UUID id,
        UUID leaseId,
        UUID propertyId,
        String propertyName,
        String unitNumber,
        String bedLabel,
        String tenantName,
        String description,
        MaintenanceStatus status,
        String landlordRemarks,
        boolean reopened,
        String reopenReason,
        Instant submittedAt,
        Instant updatedAt,
        Instant resolvedAt,
        Instant closedAt,
        List<String> photoUrls,
        long photoUrlsExpireInSeconds) {
}
