-- Proof of a payment, where every other file in Lizmo lives.
--
-- A GCash screenshot is a document like a lease contract or an ID: private
-- object storage, a presigned URL good for minutes, one retention story. The
-- documents table already does all of that and only lacked a way to say what
-- a file was attached to.
ALTER TABLE documents DROP CONSTRAINT chk_documents_owner_type;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_owner_type CHECK (owner_type IN (
    'PROPERTY', 'UNIT', 'LEASE', 'TENANT', 'PAYMENT'
  ));

-- RECEIPT has been an allowed doc_type since V1 and is what a proof of payment
-- is, so nothing needs adding there.

-- Every read is "the payments against this month, oldest first", which is what
-- a landlord scrolls when a tenant says they paid in two halves.
CREATE INDEX idx_payments_period_created
  ON payments(billing_period_id, created_at);
