-- Lizmo billing a landlord, and being paid.
--
-- platform_billing_cycles and platform_payments have existed since V1, moved
-- to the property in V16, and nothing has ever written to either. Building the
-- monthly invoice and the payment that settles it turned up four things.

-- The proof of payment lives where every other file lives. proof_image_url
-- held a link, and a link to private storage is the one thing that must never
-- be stored: it is either public or it has expired. Left in place, unused,
-- and no longer required.
ALTER TABLE platform_payments
  ALTER COLUMN proof_image_url DROP NOT NULL;

ALTER TABLE documents DROP CONSTRAINT chk_documents_owner_type;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_owner_type CHECK (owner_type IN (
    'PROPERTY', 'UNIT', 'LEASE', 'TENANT', 'PAYMENT', 'MAINTENANCE_REQUEST',
    'PLATFORM_PAYMENT'
  ));

-- What enforcement has already done about an invoice, so a daily job that runs
-- twice warns once and locks once.
--
-- OVERDUE is still not stored as a status, for the reason it is not stored on
-- rent: whether an invoice is late is a question about today, and a stored
-- answer is wrong from the moment it is written until something corrects it.
--
-- locked_at also says the lock was this invoice's doing. Paying it lifts a
-- lock enforcement placed, and never one an admin placed by hand for some other
-- reason.
ALTER TABLE platform_billing_cycles
  ADD COLUMN overdue_warned_at TIMESTAMPTZ,
  ADD COLUMN locked_at         TIMESTAMPTZ;

-- Every read by enforcement is "what is still owed".
CREATE INDEX idx_platform_billing_open
  ON platform_billing_cycles(due_date)
  WHERE status <> 'PAID';

-- Telling the landlord: an invoice arrived, it is overdue, a property locked
-- because of it, and what became of a payment they sent.
ALTER TABLE notifications DROP CONSTRAINT chk_notifications_type;

ALTER TABLE notifications
  ADD CONSTRAINT chk_notifications_type CHECK (type IN (
    'RENT_DUE_REMINDER', 'RENT_OVERDUE', 'PAYMENT_CONFIRMED', 'PAYMENT_REJECTED',
    'MAINTENANCE_STATUS_CHANGED', 'NEW_NOTICE_POSTED', 'LEASE_EXPIRING', 'STAFF_ASSIGNED',
    'REQUEST_RECEIVED',
    'REQUEST_ACCEPTED',
    'REQUEST_DECLINED',
    'REQUEST_SUPERSEDED',
    'LEASE_ENDED',
    'MAINTENANCE_REPORTED',
    'PLATFORM_INVOICE_ISSUED',
    'PLATFORM_INVOICE_OVERDUE',
    'PLATFORM_PROPERTY_LOCKED',
    'PLATFORM_PAYMENT_CONFIRMED',
    'PLATFORM_PAYMENT_REJECTED'
  ));

ALTER TABLE notifications DROP CONSTRAINT chk_notifications_entity_type;

ALTER TABLE notifications
  ADD CONSTRAINT chk_notifications_entity_type CHECK (related_entity_type IN (
    'BILLING_PERIOD', 'PAYMENT', 'MAINTENANCE_REQUEST', 'NOTICE', 'LEASE',
    'STAFF_ASSIGNMENT', 'RENTAL_REQUEST', 'PLATFORM_INVOICE'
  ));
