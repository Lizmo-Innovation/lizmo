-- Which of a landlord's ways to be paid apply to which property.
--
-- V34 kept one list per landlord and showed all of it to every tenant, which
-- is right for the landlord collecting everything into one GCash wallet and
-- wrong for the one who keeps a property's rent in its own account -- or
-- manages a property whose owner is paid directly.
--
-- Rows here, rather than a property column on the channel: one account can
-- serve several properties, and most do.
--
-- Existing channels get no rows, so they apply nowhere until their landlord
-- says where. Deliberate, and the reason the apps say plainly when a property
-- has no way to pay: an account silently serving a property its landlord
-- never chose is the worse mistake, since it is somebody's rent going to the
-- wrong wallet.

CREATE TABLE landlord_payment_channel_properties (
  channel_id   UUID NOT NULL REFERENCES landlord_payment_channels(id) ON DELETE CASCADE,
  property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

  PRIMARY KEY (channel_id, property_id)
);

CREATE INDEX idx_landlord_payment_channel_properties_property
  ON landlord_payment_channel_properties(property_id);

-- Shut the door Supabase leaves open, as V34 did for the channels themselves.
ALTER TABLE landlord_payment_channel_properties ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);
    EXECUTE format(
      'REVOKE ALL ON public.landlord_payment_channel_properties FROM %I', r);
  END LOOP;
END
$$;
