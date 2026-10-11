package app.lizmo.document;

/**
 * What a document is. Mirrors chk_documents_doc_type.
 */
public enum DocumentType {

    LEASE_CONTRACT,

    /** A photograph of a government-issued ID. */
    VALID_ID,

    RECEIPT,

    /**
     * A 1x1 or selfie: what the tenant looks like, as against what their ID
     * says. Kept apart from VALID_ID so that "the tenant photograph" stays a
     * question with one answer.
     */
    TENANT_PHOTO,

    /**
      * A photograph of a place, shown to anybody holding its code.
      *
      * <p>The only document type that is deliberately public. The landlord
      * chooses what to put here, which is what makes that safe -- and it is
      * why the EXIF is stripped on the way in, since a phone photograph of a
      * boarding house carries the coordinates of somebody's home.
      */
    PROPERTY_PHOTO,

    OTHER
}
