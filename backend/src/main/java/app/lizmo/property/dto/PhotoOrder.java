package app.lizmo.property.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import java.util.UUID;

/**
 * Every photograph once, in the order they should appear.
 *
 * <p>The whole list rather than one move, so two landlords reordering at the
 * same moment settle on one answer instead of interleaving into nonsense.
 */
@Schema(description = "The order a property's photos appear in")
public record PhotoOrder(@NotEmpty List<UUID> ids) {
}
