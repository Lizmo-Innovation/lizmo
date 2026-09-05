package app.lizmo.admin.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

/** A landlord and their properties: the console's one-landlord page. */
@Schema(description = "A landlord in full")
public record LandlordDetail(LandlordSummary landlord, List<AdminPropertySummary> properties) {
}
