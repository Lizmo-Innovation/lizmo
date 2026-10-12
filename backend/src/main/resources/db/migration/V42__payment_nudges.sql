-- Two reminders about a payment a tenant has declared and nobody has
-- answered: one to the landlord, who has to confirm it, and one -- once -- to
-- the tenant, who has been waiting.

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
    'PAYMENT_DECLARED',
    'INQUIRY_MESSAGE',
    -- To the landlord: a declared payment has waited three days, and weekly
    -- after that, until they confirm it or say it did not arrive.
    'PAYMENT_AWAITING_CONFIRMATION',
    -- To the tenant, once: theirs has waited a week. Worth asking.
    'PAYMENT_STILL_UNCONFIRMED'
  ));
