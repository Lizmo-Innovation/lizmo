-- Photographs of a place, for somebody deciding whether to ask about it.
--
-- What a stranger with the code saw was an address, a type, whatever
-- description the landlord typed, and counts per floor. That is enough to
-- decide against somewhere and not nearly enough to decide for it, so anybody
-- seriously looking had to go and stand outside three buildings. A photograph
-- is what lets them shortlist from the jeepney.
--
-- No new table: documents already serves every attachment and already knows
-- about PROPERTY owners. What photographs need that paperwork does not is an
-- order, because the first one is the one that represents the place.

ALTER TABLE documents DROP CONSTRAINT chk_documents_doc_type;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_doc_type CHECK (doc_type IN (
    'LEASE_CONTRACT', 'VALID_ID', 'RECEIPT', 'TENANT_PHOTO', 'OTHER',
    -- Shown to anyone holding the property's code. The landlord chooses what
    -- to put here, which is the only reason it can be shown so widely.
    'PROPERTY_PHOTO'
  ));

-- Null for everything that is not a photograph: paperwork has no order, and a
-- default of zero would be a number nobody set.
ALTER TABLE documents ADD COLUMN sort_order INT;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_sort_order
    CHECK (sort_order IS NULL OR sort_order >= 0);

-- How the photographs of one property are read: in order, every time.
CREATE INDEX idx_documents_photo_order
  ON documents(owner_type, owner_id, sort_order)
  WHERE doc_type = 'PROPERTY_PHOTO';
