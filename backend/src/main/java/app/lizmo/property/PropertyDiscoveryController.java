package app.lizmo.property;

import app.lizmo.common.ApiError;
import app.lizmo.property.dto.PropertyByCodeResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * How a tenant finds a place they do not yet rent.
 *
 * <p>Its own controller because it is the one part of the property API that
 * deliberately crosses the ownership boundary: every other read is scoped to
 * the landlord who owns the row, and a tenant standing at the gate with a code
 * owns nothing. Keeping it apart makes that exception easy to find and to
 * audit, rather than buried among the landlord's own endpoints.
 *
 * <p>Still requires a signed-in account. A code should not be something that
 * can be scraped anonymously, and a request made later has to be traceable to
 * a person.
 */
@RestController
@RequestMapping("/api/v1/properties")
@Tag(name = "Finding a place", description = "Looking up a property by its code")
public class PropertyDiscoveryController {

    private final PropertyDiscoveryService discovery;

    public PropertyDiscoveryController(PropertyDiscoveryService discovery) {
        this.discovery = discovery;
    }

    @GetMapping("/lookup")
    @Operation(operationId = "findPropertyByCode", summary = "Find a property by its code",
            description = "Case-insensitive. Spaces and dashes in the code are ignored, "
                    + "so a code read aloud and written down still matches.")
    @ApiResponse(responseCode = "200", description = "The property",
            content = @Content(schema = @Schema(implementation = PropertyByCodeResponse.class)))
    @ApiResponse(responseCode = "404", description = "No property uses that code",
            content = @Content(schema = @Schema(implementation = ApiError.class)))
    public PropertyByCodeResponse lookup(@RequestParam String code) {
        return discovery.findByCode(code);
    }
}
