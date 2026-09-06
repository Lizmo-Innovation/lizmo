-- Supporting paperwork on a lease.
--
-- Almost nothing is needed here: documents has carried owner_type 'LEASE' and
-- doc_type 'LEASE_CONTRACT' since V1, the "one per kind" unique index is
-- scoped to owner_type = 'TENANT' so a lease may hold many, and the label
-- column has been sitting unused since it was written.
--
-- What is genuinely new is who may read them. A tenant's ID belongs to the
-- tenant and is shown to the landlord; a lease attachment is the landlord's,
-- and some of it -- the signed contract -- is the tenant's business too, while
-- the rest -- a clearance the landlord chased down, a note to themselves -- is
-- not. Nothing in the table could tell those apart.
ALTER TABLE documents
  ADD COLUMN shared_with_tenant BOOLEAN NOT NULL DEFAULT FALSE;

-- Default FALSE, and the application defaults it TRUE for lease attachments.
-- Those disagree on purpose. Every row that already exists is a tenant's own
-- photograph, which is not "shared with the tenant" in this sense at all --
-- the column is meaningless for them, and FALSE is the honest meaningless
-- value. Backfilling TRUE would read as a decision nobody made.

-- Attachments are listed per lease, newest first, every time a landlord opens
-- a tenant. The V1 index is (owner_type, owner_id), which finds the rows but
-- leaves the sort to be done each time.
CREATE INDEX idx_documents_lease_uploaded
  ON documents(owner_id, uploaded_at DESC)
  WHERE owner_type = 'LEASE';
