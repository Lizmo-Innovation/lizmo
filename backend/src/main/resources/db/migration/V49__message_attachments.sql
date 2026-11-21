-- Photos and PDFs in a conversation.
--
-- Stored as documents like every other upload, owned by the message they were
-- sent with. A photo is two rows: the photo itself, re-encoded with nothing
-- but pixels left in it, and a small preview for the thread, so a phone on
-- mobile data is not handed a 2000px picture to draw at 200.

ALTER TABLE documents DROP CONSTRAINT chk_documents_owner_type;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_owner_type CHECK (owner_type IN (
    'PROPERTY', 'UNIT', 'LEASE', 'TENANT', 'PAYMENT', 'MAINTENANCE_REQUEST',
    'PLATFORM_PAYMENT', 'PLATFORM_PAYMENT_CHANNEL', 'LANDLORD_PAYMENT_CHANNEL',
    'INQUIRY_MESSAGE'
  ));

ALTER TABLE documents DROP CONSTRAINT chk_documents_doc_type;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_doc_type CHECK (doc_type IN (
    'LEASE_CONTRACT', 'VALID_ID', 'RECEIPT', 'TENANT_PHOTO', 'OTHER',
    'PROPERTY_PHOTO',
    'MESSAGE_PHOTO', 'MESSAGE_PREVIEW', 'MESSAGE_FILE'
  ));

-- A message can now be a photo and nothing else. The app still refuses one
-- with neither words nor a file; the database only keeps it within length.
ALTER TABLE inquiry_messages DROP CONSTRAINT chk_inquiry_messages_body;

ALTER TABLE inquiry_messages
  ADD CONSTRAINT chk_inquiry_messages_body CHECK (length(body) <= 2000);
