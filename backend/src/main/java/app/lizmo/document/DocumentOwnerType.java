package app.lizmo.document;

/**
 * What a document is attached to. Mirrors chk_documents_owner_type.
 *
 * <p>One table serves every kind of attachment, so owner_id means nothing
 * without this beside it.
 */
public enum DocumentOwnerType {
    PROPERTY,
    UNIT,
    LEASE,
    TENANT
}
