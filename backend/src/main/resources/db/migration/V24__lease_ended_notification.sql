-- Telling a tenant their tenancy is over.
--
-- LEASE_EXPIRING has been in the constraint since V1 and means something
-- else: a warning that an end is coming. This is the end having happened,
-- and a tenant reading "your lease is expiring" the day after they moved out
-- would rightly wonder which of the two the app meant.
--
-- Until now they learned it by opening the app and noticing their tenancy had
-- gone -- the same silence the request notifications were built to close.
ALTER TABLE notifications DROP CONSTRAINT chk_notifications_type;

ALTER TABLE notifications
  ADD CONSTRAINT chk_notifications_type CHECK (type IN (
    -- Anticipated by the schema, still unbuilt.
    'RENT_DUE_REMINDER', 'RENT_OVERDUE', 'PAYMENT_CONFIRMED', 'PAYMENT_REJECTED',
    'MAINTENANCE_STATUS_CHANGED', 'NEW_NOTICE_POSTED', 'LEASE_EXPIRING', 'STAFF_ASSIGNED',

    -- Asking for a room, and being answered.
    'REQUEST_RECEIVED',
    'REQUEST_ACCEPTED',
    'REQUEST_DECLINED',
    'REQUEST_SUPERSEDED',

    -- And leaving it.
    'LEASE_ENDED'
  ));
