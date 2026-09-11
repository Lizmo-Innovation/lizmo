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
    TENANT,

    /**
     * Proof that money moved: a GCash screenshot, a deposit slip.
     *
     * <p>Attached to the payment rather than the lease, so that deleting a
     * rejected payment takes its evidence with it.
     */
    PAYMENT,
    MAINTENANCE_REQUEST
}
