-- Where a landlord sends money to Lizmo, as a list rather than a paragraph.
--
-- V19's payment_instructions setting was one free-text box. That reads fine
-- with one GCash number and badly with three accounts, and it cannot carry a
-- QR code -- which is how most people in the Philippines actually pay a
-- wallet. Each channel is now a row: what it is, whose name, which number, and
-- optionally a QR stored as a document.
--
-- The free-text setting stays, demoted to a note shown under the channels
-- ("put your property name in the reference"). Nothing an admin typed is lost.

CREATE TABLE platform_payment_channels (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Free text on purpose: GCash, Maya, BPI, BDO, UnionBank. A fixed list would
  -- flatten every bank into "bank transfer" and need a release for a new wallet.
  channel        VARCHAR(40)  NOT NULL,
  account_name   VARCHAR(120) NOT NULL,
  account_number VARCHAR(60)  NOT NULL,

  -- Hidden rather than deleted when a wallet is at its limit for the month,
  -- so it comes back without being retyped.
  visible        BOOLEAN      NOT NULL DEFAULT TRUE,
  sort_order     INTEGER      NOT NULL,

  created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),

  -- Which admin last changed it. This is where money goes; changing it
  -- silently should not be possible.
  updated_by     UUID REFERENCES users(id),

  -- A channel with no number is a landlord told to pay and unable to.
  CONSTRAINT chk_payment_channel_filled CHECK (
    btrim(channel) <> '' AND btrim(account_name) <> '' AND btrim(account_number) <> ''
  )
);

CREATE INDEX idx_platform_payment_channels_order ON platform_payment_channels(sort_order);

-- The QR lives in documents, like every other image.
--
-- owner_type was VARCHAR(20), and PLATFORM_PAYMENT_CHANNEL is 24. Widened
-- rather than abbreviated: a name somebody reads in a query should say what
-- it is. Growing a varchar is a catalogue change in Postgres, not a rewrite.
ALTER TABLE documents ALTER COLUMN owner_type TYPE VARCHAR(40);

ALTER TABLE documents DROP CONSTRAINT chk_documents_owner_type;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_owner_type CHECK (owner_type IN (
    'PROPERTY', 'UNIT', 'LEASE', 'TENANT', 'PAYMENT', 'MAINTENANCE_REQUEST',
    'PLATFORM_PAYMENT', 'PLATFORM_PAYMENT_CHANNEL'
  ));

-- Shut the door Supabase leaves open, as V28 did for every table that existed
-- then. A new table starts world-readable over PostgREST otherwise -- and this
-- one says where to send money, which is exactly what should not be editable
-- by a stranger.
ALTER TABLE platform_payment_channels ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);
    EXECUTE format('REVOKE ALL ON public.platform_payment_channels FROM %I', r);
  END LOOP;
END
$$;
