package app.lizmo.property;

import java.util.EnumSet;
import java.util.Set;

/**
 * What a property is let for. Mirrors chk_properties_usage.
 *
 * <p>Separate from {@link PropertyType}, which describes the building form. The
 * two are one-to-one today — every type belongs to exactly one usage — so the
 * stored column is strictly redundant. It is stored anyway because the pairing
 * is expected to loosen: a single house let as an office is ordinary here, and
 * when that lands, the allowed sets below widen without a data migration.
 */
public enum PropertyUsage {

    RESIDENTIAL(EnumSet.of(
            PropertyType.APARTMENT,
            PropertyType.BOARDING_HOUSE,
            PropertyType.CONDO,
            PropertyType.SINGLE_HOUSE)),

    COMMERCIAL(EnumSet.of(
            PropertyType.OFFICE,
            PropertyType.RETAIL_SPACE,
            PropertyType.WAREHOUSE,
            PropertyType.STALL));

    private final Set<PropertyType> allowed;

    PropertyUsage(Set<PropertyType> allowed) {
        this.allowed = allowed;
    }

    public boolean allows(PropertyType type) {
        return allowed.contains(type);
    }

    public Set<PropertyType> allowedTypes() {
        return Set.copyOf(allowed);
    }
}
