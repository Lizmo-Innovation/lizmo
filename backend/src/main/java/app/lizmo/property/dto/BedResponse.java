package app.lizmo.property.dto;

import app.lizmo.property.Bed;
import app.lizmo.property.BedStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.UUID;

@Schema(description = "A bed within a bedspace unit")
public record BedResponse(UUID id, UUID unitId, String bedLabel, BedStatus status) {

    public static BedResponse of(Bed bed) {
        return new BedResponse(bed.getId(), bed.getUnitId(), bed.getBedLabel(), bed.getStatus());
    }
}
