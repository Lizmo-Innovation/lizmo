-- Reporting something broken, and following what happens to it.
--
-- maintenance_requests has been here since V1 with nothing reading or writing
-- it. Building it turned up three things the original table did not expect.

-- WITHDRAWN. A tenant may take a report back while nobody has started on it --
-- the tap that fixed itself -- and it is kept rather than deleted, so a
-- landlord who saw it arrive can also see it go.
ALTER TABLE maintenance_requests DROP CONSTRAINT chk_maintenance_status;

ALTER TABLE maintenance_requests
  ADD CONSTRAINT chk_maintenance_status CHECK (status IN (
    'SUBMITTED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'WITHDRAWN'
  ));

-- Confirming the fix. A landlord marks something RESOLVED; only the tenant can
-- close it, or say it is still broken and why. The reason is the whole point
-- of saying so, and a report can be reopened more than once, so the latest
-- reason and when it came are what is kept.
ALTER TABLE maintenance_requests
  ADD COLUMN reopen_reason TEXT,
  ADD COLUMN reopened_at   TIMESTAMPTZ,
  ADD COLUMN closed_at     TIMESTAMPTZ;

-- Up to three photographs, kept where every other file is. photo_url held one
-- link, and a link to private storage is the one thing that should never be
-- stored: it is either public or it has expired. The column is left unused
-- rather than dropped.
ALTER TABLE documents DROP CONSTRAINT chk_documents_owner_type;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_owner_type CHECK (owner_type IN (
    'PROPERTY', 'UNIT', 'LEASE', 'TENANT', 'PAYMENT', 'MAINTENANCE_REQUEST'
  ));

-- Telling the landlord something was reported. MAINTENANCE_STATUS_CHANGED has
-- been allowed since V1 and covers everything that happens after that.
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
    'MAINTENANCE_REPORTED'
  ));

-- The two reads: a tenant's own reports, and every report on a landlord's
-- units, both newest first.
CREATE INDEX idx_maintenance_submitted_by
  ON maintenance_requests(submitted_by, submitted_at DESC);

CREATE INDEX idx_maintenance_unit_submitted
  ON maintenance_requests(unit_id, submitted_at DESC);
