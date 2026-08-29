package app.lizmo.property;

import app.lizmo.common.ApiException;
import app.lizmo.common.ErrorCode;
import app.lizmo.property.dto.PropertyByCodeResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Finding a property by the code on the gate. */
@Service
public class PropertyDiscoveryService {

    private final PropertyRepository properties;

    public PropertyDiscoveryService(PropertyRepository properties) {
        this.properties = properties;
    }

    @Transactional(readOnly = true)
    public PropertyByCodeResponse findByCode(String typed) {
        String code = PropertyCodes.normalise(typed);
        if (code == null) {
            throw notFound();
        }
        return properties.findByCode(code)
                .map(PropertyByCodeResponse::of)
                .orElseThrow(PropertyDiscoveryService::notFound);
    }

    /**
     * The same answer for a malformed code, an unused one, and one that is
     * merely someone else's. Saying "that code is not in use" would turn this
     * endpoint into a way to test codes one at a time and learn which exist.
     */
    private static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, "No property uses that code.");
    }
}
