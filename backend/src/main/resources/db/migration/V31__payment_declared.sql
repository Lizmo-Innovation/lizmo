-- A tenant saying they have paid is not a payment being confirmed.
--
-- The landlord's notification for it was raised as PAYMENT_CONFIRMED, which
-- is the type for the opposite event: a landlord agreeing money arrived. The
-- wording on the row was right ("A tenant says they have paid"), so nobody
-- reading the app saw anything wrong -- but the stored type said the payment
-- had been confirmed when it was waiting to be.
--
-- Rows already written keep the old type. What somebody was told is a fact
-- about the past, and rewriting history to tidy an enum would be worse than
-- the untidiness: the app routes both to the same place.
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
    'PLATFORM_PAYMENT_REJECTED',
    'PAYMENT_DECLARED'
  ));
