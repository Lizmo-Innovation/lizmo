package app.lizmo.maintenance;

import app.lizmo.common.ApiError;
import app.lizmo.maintenance.dto.MaintenanceNote;
import app.lizmo.maintenance.dto.MaintenanceReportResponse;
import app.lizmo.maintenance.dto.ReportProblemRequest;
import app.lizmo.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Something broken: reporting it, and dealing with it.
 *
 * <p>Two sets of endpoints, as with rental requests. A tenant has their own
 * reports under /me; a landlord has every report on their properties.
 */
@RestController
public class MaintenanceController {

    private final MaintenanceService maintenance;
    private final CurrentUser currentUser;

    public MaintenanceController(MaintenanceService maintenance, CurrentUser currentUser) {
        this.maintenance = maintenance;
        this.currentUser = currentUser;
    }

    // ---- the tenant --------------------------------------------------------

    @GetMapping("/api/v1/me/maintenance")
    @Tag(name = "Maintenance", description = "Reporting something broken")
    @Operation(operationId = "listMyMaintenanceReports", summary = "What I have reported",
            description = "Newest first, whatever became of each.")
    @ApiResponse(responseCode = "200", description = "The reports",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = MaintenanceReportResponse.class))))
    public List<MaintenanceReportResponse> mine() {
        return maintenance.mine(currentUser.requireId());
    }

    @PostMapping("/api/v1/me/maintenance")
    @ResponseStatus(HttpStatus.CREATED)
    @Tag(name = "Maintenance", description = "Reporting something broken")
    @Operation(operationId = "reportProblem", summary = "Report something broken",
            description = "Against the tenancy the caller is living under now. The landlord "
                    + "is told. Photos are added afterwards, one at a time.")
    @ApiResponse(responseCode = "201", description = "The report",
            content = @Content(schema = @Schema(implementation = MaintenanceReportResponse.class)))
    @ApiResponse(responseCode = "400", description = "No tenancy, or nothing described",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public MaintenanceReportResponse report(@Valid @RequestBody ReportProblemRequest request) {
        return maintenance.report(currentUser.requireId(), request);
    }

    @PostMapping(path = "/api/v1/me/maintenance/{id}/photos",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Tag(name = "Maintenance", description = "Reporting something broken")
    @Operation(operationId = "addMaintenancePhoto", summary = "Add a photo to my report",
            description = "Up to three, while nobody has started on it. Re-encoded, so no "
                    + "EXIF or location leaves the phone.")
    @ApiResponse(responseCode = "201", description = "The report, with the photo",
            content = @Content(schema = @Schema(implementation = MaintenanceReportResponse.class)))
    @ApiResponse(responseCode = "400", description = "Three already, or work has started",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public MaintenanceReportResponse addPhoto(
            @PathVariable UUID id,
            @RequestPart("photo") MultipartFile photo) {
        return maintenance.addPhoto(id, currentUser.requireId(), photo);
    }

    @PostMapping("/api/v1/me/maintenance/{id}/withdraw")
    @Tag(name = "Maintenance", description = "Reporting something broken")
    @Operation(operationId = "withdrawMaintenanceReport", summary = "Take my report back",
            description = "Only while nobody has started on it. Kept, not deleted.")
    @ApiResponse(responseCode = "200", description = "The withdrawn report",
            content = @Content(schema = @Schema(implementation = MaintenanceReportResponse.class)))
    public MaintenanceReportResponse withdraw(@PathVariable UUID id) {
        return maintenance.withdraw(id, currentUser.requireId());
    }

    @PostMapping("/api/v1/me/maintenance/{id}/fixed")
    @Tag(name = "Maintenance", description = "Reporting something broken")
    @Operation(operationId = "confirmMaintenanceFixed", summary = "Say it is fixed",
            description = "Closes a report the landlord has marked resolved.")
    @ApiResponse(responseCode = "200", description = "The closed report",
            content = @Content(schema = @Schema(implementation = MaintenanceReportResponse.class)))
    public MaintenanceReportResponse confirmFixed(@PathVariable UUID id) {
        return maintenance.confirmFixed(id, currentUser.requireId());
    }

    @PostMapping("/api/v1/me/maintenance/{id}/reopen")
    @Tag(name = "Maintenance", description = "Reporting something broken")
    @Operation(operationId = "reopenMaintenanceReport", summary = "Say it is still broken",
            description = "On a report the landlord has marked resolved. A reason is required: "
                    + "it is the whole of what the landlord needs to hear.")
    @ApiResponse(responseCode = "200", description = "The reopened report",
            content = @Content(schema = @Schema(implementation = MaintenanceReportResponse.class)))
    public MaintenanceReportResponse reopen(
            @PathVariable UUID id, @Valid @RequestBody MaintenanceNote reason) {
        return maintenance.reopen(id, currentUser.requireId(), reason);
    }

    // ---- the landlord ------------------------------------------------------

    @GetMapping("/api/v1/maintenance")
    @Tag(name = "Maintenance to handle", description = "What tenants have reported")
    @Operation(operationId = "listMaintenanceReports", summary = "Everything reported on my properties",
            description = "Newest first, across every property, whatever became of each.")
    @ApiResponse(responseCode = "200", description = "The reports",
            content = @Content(array = @ArraySchema(
                    schema = @Schema(implementation = MaintenanceReportResponse.class))))
    public List<MaintenanceReportResponse> forLandlord() {
        return maintenance.forLandlord(currentUser.requireId());
    }

    @GetMapping("/api/v1/maintenance/{id}")
    @Tag(name = "Maintenance to handle", description = "What tenants have reported")
    @Operation(operationId = "getMaintenanceReport", summary = "One report in full")
    @ApiResponse(responseCode = "200", description = "The report",
            content = @Content(schema = @Schema(implementation = MaintenanceReportResponse.class)))
    @ApiResponse(responseCode = "404", description = "Not on your property",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public MaintenanceReportResponse one(@PathVariable UUID id) {
        return maintenance.one(id, currentUser.requireId());
    }

    @PostMapping("/api/v1/maintenance/{id}/start")
    @Tag(name = "Maintenance to handle", description = "What tenants have reported")
    @Operation(operationId = "startMaintenance", summary = "Start on it",
            description = "The tenant is told, with the remark if there is one.")
    @ApiResponse(responseCode = "200", description = "The report",
            content = @Content(schema = @Schema(implementation = MaintenanceReportResponse.class)))
    public MaintenanceReportResponse start(
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) MaintenanceNote remarks) {
        return maintenance.start(id, currentUser.requireId(), remarks);
    }

    @PostMapping("/api/v1/maintenance/{id}/resolve")
    @Tag(name = "Maintenance to handle", description = "What tenants have reported")
    @Operation(operationId = "resolveMaintenance", summary = "Say it is fixed",
            description = "The tenant is asked to confirm, or to say it is still broken.")
    @ApiResponse(responseCode = "200", description = "The report",
            content = @Content(schema = @Schema(implementation = MaintenanceReportResponse.class)))
    public MaintenanceReportResponse resolve(
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) MaintenanceNote remarks) {
        return maintenance.resolve(id, currentUser.requireId(), remarks);
    }
}
