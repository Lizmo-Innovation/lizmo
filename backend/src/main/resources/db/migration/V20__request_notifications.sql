-- Telling people what happened.
--
-- The notifications table was designed for rent reminders, payments and
-- maintenance -- none of which exist yet -- and not for the one exchange the
-- app already runs: somebody asks for a room, and a landlord answers.
--
-- Until now nobody was told anything. A tenant learned they had been accepted
-- by reopening the app and noticing the screen had changed. The rivals, whose
-- requests are superseded the moment somebody else is accepted, were told
-- nothing at all -- which is worse than being declined, because a decline at
-- least happens to you.
ALTER TABLE notifications DROP CONSTRAINT chk_notifications_type;

ALTER TABLE notifications
  ADD CONSTRAINT chk_notifications_type CHECK (type IN (
    -- What the schema always anticipated, none of it built yet.
    'RENT_DUE_REMINDER', 'RENT_OVERDUE', 'PAYMENT_CONFIRMED', 'PAYMENT_REJECTED',
    'MAINTENANCE_STATUS_CHANGED', 'NEW_NOTICE_POSTED', 'LEASE_EXPIRING', 'STAFF_ASSIGNED',

    -- The exchange that does exist.
    'REQUEST_RECEIVED',    -- to the landlord: somebody is asking
    'REQUEST_ACCEPTED',    -- to the tenant, carrying the terms
    'REQUEST_DECLINED',    -- to the tenant
    'REQUEST_SUPERSEDED'   -- to everyone else who wanted that bed
  ));

ALTER TABLE notifications DROP CONSTRAINT chk_notifications_entity_type;

ALTER TABLE notifications
  ADD CONSTRAINT chk_notifications_entity_type CHECK (related_entity_type IN (
    'BILLING_PERIOD', 'PAYMENT', 'MAINTENANCE_REQUEST', 'NOTICE', 'LEASE',
    'STAFF_ASSIGNMENT', 'RENTAL_REQUEST'
  ));

-- Every read of this table is "what is waiting for me, newest first", which
-- the original index -- (recipient, status), from before anything raised a
-- notification -- cannot answer without sorting the lot.
DROP INDEX idx_notifications_recipient;

CREATE INDEX idx_notifications_recipient
  ON notifications(recipient_user_id, created_at DESC);

-- The count behind the tab badge, asked for on every app open.
CREATE INDEX idx_notifications_unread
  ON notifications(recipient_user_id)
  WHERE status = 'UNREAD';
