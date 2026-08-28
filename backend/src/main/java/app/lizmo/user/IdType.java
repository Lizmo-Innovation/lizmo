package app.lizmo.user;

/**
 * The identity documents a Philippine tenant is likely to carry.
 *
 * <p>Mirrors chk_tenant_profiles_id_type. A closed list because a landlord
 * recognises these on sight and a free-text field would collect twelve
 * spellings of "drivers license"; OTHER exists so that carrying something
 * unusual does not stop someone renting a bed.
 */
public enum IdType {

    /** The national ID. */
    PHILSYS,

    UMID,
    SSS,
    GSIS,
    DRIVERS_LICENSE,
    PASSPORT,
    PHILHEALTH,
    POSTAL,
    VOTERS,
    TIN,

    /** Professional Regulation Commission — nurses, teachers, engineers. */
    PRC,

    OTHER
}
