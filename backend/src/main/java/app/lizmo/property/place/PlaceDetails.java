package app.lizmo.property.place;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;

/**
 * What a tenant wants to know about a place before asking: who can rent,
 * the house rules, the money up front, and what comes with it.
 *
 * <p>Every part is optional. Null is "not said", which is not the same as
 * "no" -- a landlord who has not said whether pets are allowed has not said
 * they are not.
 */
@Entity
@Table(name = "place_details")
public class PlaceDetails {

    /** Who a place lets to. Very often women only, for bedspaces here. */
    public enum WhoCanRent {
        ANYONE,
        WOMEN,
        MEN
    }

    public enum Visitors {
        ALLOWED,
        DAYTIME,
        NONE
    }

    @Id
    @Column(name = "property_id")
    private UUID propertyId;

    @Enumerated(EnumType.STRING)
    @Column(name = "who_can_rent")
    private WhoCanRent whoCanRent;

    /** "22:00", or null for no curfew said. */
    private String curfew;

    @Enumerated(EnumType.STRING)
    private Visitors visitors;

    private Boolean cooking;
    private Boolean pets;
    private Boolean smoking;

    @Column(name = "other_rules")
    private String otherRules;

    @Column(name = "deposit_months")
    private Short depositMonths;

    @Column(name = "advance_months")
    private Short advanceMonths;

    @Convert(converter = AmenitiesConverter.class)
    @Column(nullable = false)
    private Set<Amenity> amenities = EnumSet.noneOf(Amenity.class);

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PlaceDetails() {
        // JPA
    }

    public PlaceDetails(UUID propertyId) {
        this.propertyId = propertyId;
    }

    /** Replaced whole: the form is the whole of it, so a blank is a blank. */
    public void set(PlaceDetailsDto details) {
        this.whoCanRent = details.whoCanRent();
        this.curfew = blankToNull(details.curfew());
        this.visitors = details.visitors();
        this.cooking = details.cooking();
        this.pets = details.pets();
        this.smoking = details.smoking();
        this.otherRules = blankToNull(details.otherRules());
        this.depositMonths = details.depositMonths() == null
                ? null : details.depositMonths().shortValue();
        this.advanceMonths = details.advanceMonths() == null
                ? null : details.advanceMonths().shortValue();
        this.amenities = details.amenities() == null || details.amenities().isEmpty()
                ? EnumSet.noneOf(Amenity.class)
                : EnumSet.copyOf(details.amenities());
    }

    @PrePersist
    @PreUpdate
    void touched() {
        this.updatedAt = Instant.now();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public UUID getPropertyId() {
        return propertyId;
    }

    public WhoCanRent getWhoCanRent() {
        return whoCanRent;
    }

    public String getCurfew() {
        return curfew;
    }

    public Visitors getVisitors() {
        return visitors;
    }

    public Boolean getCooking() {
        return cooking;
    }

    public Boolean getPets() {
        return pets;
    }

    public Boolean getSmoking() {
        return smoking;
    }

    public String getOtherRules() {
        return otherRules;
    }

    public Short getDepositMonths() {
        return depositMonths;
    }

    public Short getAdvanceMonths() {
        return advanceMonths;
    }

    public Set<Amenity> getAmenities() {
        return amenities;
    }
}
