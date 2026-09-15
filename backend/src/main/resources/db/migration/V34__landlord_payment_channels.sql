-- How a tenant pays their landlord.
--
-- V33 gave Lizmo a list of its own accounts, each with an optional QR. This is
-- the same thing one level down: a landlord's GCash, Maya or bank details,
-- shown to their tenants beside "I have paid". One list per landlord, covering
-- every property they own -- most small landlords collect into one account.
--
-- A table of its own rather than a landlord column on V33's: Lizmo's admin
-- screens then cannot list a landlord's accounts by accident, and nothing a
-- landlord calls can reach Lizmo's.

CREATE TABLE landlord_payment_channels (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  landlord_id    UUID NOT NULL REFERENCES landlord_profiles(user_id),

  channel        VARCHAR(40)  NOT NULL,
  account_name   VARCHAR(120) NOT NULL,
  account_number VARCHAR(60)  NOT NULL,

  -- Hidden rather than deleted, like Lizmo's: a wallet at its limit for the
  -- month comes back without being retyped.
  visible        BOOLEAN      NOT NULL DEFAULT TRUE,
  sort_order     INTEGER      NOT NULL,

  created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT chk_landlord_payment_channel_filled CHECK (
    btrim(channel) <> '' AND btrim(account_name) <> '' AND btrim(account_number) <> ''
  )
);

CREATE INDEX idx_landlord_payment_channels_landlord
  ON landlord_payment_channels(landlord_id, sort_order);

-- The line under the channels: "Cash to Aling Nena at unit 1A". One per
-- landlord, so it lives on the landlord.
ALTER TABLE landlord_profiles ADD COLUMN payment_note VARCHAR(500);

-- Where a tenant said the money went, written out at the moment they chose it:
-- "GCash · Ariel Asebias · 09771231234". Text rather than a reference to the
-- channel, so editing or deleting the channel later cannot rewrite what a past
-- payment claimed. Null for cash, and for anything recorded before this.
ALTER TABLE payments ADD COLUMN sent_to VARCHAR(250);

-- The QR lives in documents, like every other image.
ALTER TABLE documents DROP CONSTRAINT chk_documents_owner_type;

ALTER TABLE documents
  ADD CONSTRAINT chk_documents_owner_type CHECK (owner_type IN (
    'PROPERTY', 'UNIT', 'LEASE', 'TENANT', 'PAYMENT', 'MAINTENANCE_REQUEST',
    'PLATFORM_PAYMENT', 'PLATFORM_PAYMENT_CHANNEL', 'LANDLORD_PAYMENT_CHANNEL'
  ));

-- Shut the door Supabase leaves open, as V28 did for every table that existed
-- then. This one holds people's account numbers.
ALTER TABLE landlord_payment_channels ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);
    EXECUTE format('REVOKE ALL ON public.landlord_payment_channels FROM %I', r);
  END LOOP;
END
$$;
