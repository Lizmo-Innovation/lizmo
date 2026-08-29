-- Documents a tenant uploads about themselves: a photograph of a valid ID, and
-- a 1x1 or selfie. Both are needed before a lease can be signed.

-- V1 called this file_url, and it never held one. Objects live in S3 and are
-- served through presigned URLs minted per request and valid for minutes, so
-- what is stored is the key. A column named file_url would invite a client to
-- put it in an <img src>, where it would 403 -- or worse, would tempt someone
-- to store a long-lived public URL in it and make every ID world-readable.
ALTER TABLE documents RENAME COLUMN file_url TO storage_key;

-- A 1x1 is none of LEASE_CONTRACT, VALID_ID, RECEIPT or OTHER. OTHER would
-- have worked and would have made "the tenant's photograph" unqueryable.
ALTER TABLE documents DROP CONSTRAINT chk_documents_doc_type;
ALTER TABLE documents
  ADD CONSTRAINT chk_documents_doc_type CHECK (doc_type IN (
    'LEASE_CONTRACT', 'VALID_ID', 'RECEIPT', 'TENANT_PHOTO', 'OTHER'
  ));

-- What is stored is always what the API wrote: normalised, re-encoded JPEG.
-- Recorded rather than assumed, so a later format is not a guess about which
-- rows predate it.
ALTER TABLE documents ADD COLUMN content_type VARCHAR(100);
ALTER TABLE documents ADD COLUMN byte_size BIGINT;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_byte_size
    CHECK (byte_size IS NULL OR byte_size > 0);

-- One current ID and one current photograph per tenant. A re-upload replaces
-- what is there rather than stacking a second row that nothing chooses
-- between: without this, "the tenant's ID" becomes a question with two answers
-- and the newest is only probably the right one.
--
-- Partial, because leases and properties will hold many documents of a kind
-- and must not inherit this rule.
CREATE UNIQUE INDEX uq_documents_one_per_tenant_kind
  ON documents(owner_id, doc_type)
  WHERE owner_type = 'TENANT';
