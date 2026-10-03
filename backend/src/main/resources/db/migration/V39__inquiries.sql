-- A conversation between somebody asking about a place and the landlord.
--
-- Replaces the rental request as the thing that happens first. A request was a
-- form: a tenant pressed a button, a landlord read five rows of facts, and the
-- only moves were accept or decline. Neither side could say a word -- not "I
-- want it from November", not "can you come and see it Saturday" -- so every
-- real conversation happened on the phone, outside Lizmo, and what was agreed
-- was never written anywhere.
--
-- One thread per tenant per property, reopened rather than duplicated: asking
-- twice about the same building is the same conversation, picked up again.
-- The lease comes out of the thread, which is what the next migration takes up.
--
-- No landlord_id here. It is the property's owner, and a property can change
-- hands: stored, it would quietly go stale and start showing a thread to
-- somebody who no longer owns the building.

CREATE TABLE inquiries (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  property_id   UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  tenant_id     UUID NOT NULL REFERENCES users(id),

  status        VARCHAR(20) NOT NULL DEFAULT 'OPEN',

  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Null until somebody says something. The list is ordered by it, so a thread
  -- with nothing in it sorts by when it was started.
  last_message_at TIMESTAMPTZ,

  -- Whether each side has something they have not seen. A flag rather than a
  -- "last read" stamp: a stamp has to be compared against the last message,
  -- and the two are written in the same breath -- same transaction, same
  -- clock reading -- so an equal pair reads as "seen" when nobody has seen
  -- anything. A flag says what is meant and cannot be off by a microsecond.
  tenant_unread    BOOLEAN NOT NULL DEFAULT false,
  landlord_unread  BOOLEAN NOT NULL DEFAULT false,

  -- When it stopped being open, whichever way it went.
  closed_at     TIMESTAMPTZ
);

ALTER TABLE inquiries
  ADD CONSTRAINT chk_inquiries_status CHECK (status IN (
    'OPEN',
    -- Either side can end it: a tenant who found somewhere else, a landlord
    -- with nothing to offer. One state, because "declined" and "withdrawn"
    -- were a distinction only the database cared about.
    'CLOSED',
    -- A tenancy came out of it. The thread stays readable, and usable: it is
    -- the same two people, and a tenancy needs somewhere to talk.
    'LEASED'
  ));

ALTER TABLE inquiries
  ADD CONSTRAINT chk_inquiries_closed
    CHECK ((status = 'OPEN') = (closed_at IS NULL));

-- One thread per pair. Asking again reopens this row rather than starting a
-- second conversation nobody can tell apart from the first.
CREATE UNIQUE INDEX uq_inquiries_tenant_property
  ON inquiries(tenant_id, property_id);

-- The landlord's inbox: every thread on the properties they own, newest
-- activity first.
CREATE INDEX idx_inquiries_property
  ON inquiries(property_id, last_message_at DESC);

CREATE TABLE inquiry_messages (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  inquiry_id   UUID NOT NULL REFERENCES inquiries(id) ON DELETE CASCADE,

  -- Either side. Not a role column: who sent it is a user, and the role is
  -- whatever that user is to this thread.
  sender_id    UUID NOT NULL REFERENCES users(id),

  body         TEXT NOT NULL,

  sent_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE inquiry_messages
  ADD CONSTRAINT chk_inquiry_messages_body
    CHECK (length(btrim(body)) BETWEEN 1 AND 2000);

CREATE INDEX idx_inquiry_messages_thread
  ON inquiry_messages(inquiry_id, sent_at);

-- Shut the door Supabase leaves open, as every table here does.
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiry_messages ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  r text;
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['inquiries', 'inquiry_messages'] LOOP
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
      CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);
      EXECUTE format('REVOKE ALL ON public.%I FROM %I', t, r);
    END LOOP;
  END LOOP;
END
$$;

-- What has already been asked becomes a thread, so nobody mid-conversation
-- loses it. A tenant may hold several requests on one property -- one per room
-- they asked about -- and they collapse into the single thread they always
-- were in practice: accepted outranks pending, which outranks everything that
-- is over.
INSERT INTO inquiries (
  property_id, tenant_id, status, created_at, updated_at, last_message_at, closed_at)
SELECT
  property_id,
  tenant_id,
  CASE
    WHEN bool_or(status = 'ACCEPTED') THEN 'LEASED'
    WHEN bool_or(status = 'PENDING')  THEN 'OPEN'
    ELSE 'CLOSED'
  END,
  min(created_at),
  max(updated_at),
  -- Nothing was ever said in them, so there is no last message.
  NULL,
  CASE
    WHEN bool_or(status = 'PENDING') THEN NULL
    ELSE coalesce(max(decided_at), max(updated_at))
  END
FROM rental_requests
GROUP BY property_id, tenant_id;

-- rental_requests itself stays until the endpoints that read it are gone,
-- which is the next change. Dropping it here would leave the running code
-- pointing at a table that is not there.

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
    -- Somebody wrote in a thread, said to whoever did not write it.
    'INQUIRY_MESSAGE'
  ));

ALTER TABLE notifications DROP CONSTRAINT chk_notifications_entity_type;

ALTER TABLE notifications
  ADD CONSTRAINT chk_notifications_entity_type CHECK (related_entity_type IN (
    'BILLING_PERIOD', 'PAYMENT', 'MAINTENANCE_REQUEST', 'NOTICE', 'LEASE',
    'STAFF_ASSIGNMENT', 'RENTAL_REQUEST', 'PLATFORM_INVOICE',
    'INQUIRY'
  ));
