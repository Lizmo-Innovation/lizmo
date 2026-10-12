-- The phones a person has signed in on, so a notification can reach them as
-- a push as well as in the app's bell.
--
-- One row per token. A token belongs to one app install, so it is unique:
-- the same phone signing into a different account moves its token across
-- rather than being told about both people's business.

CREATE TABLE device_tokens (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token         TEXT NOT NULL,
  platform      VARCHAR(20) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_device_tokens_token UNIQUE (token),
  CONSTRAINT chk_device_tokens_platform CHECK (platform IN ('ANDROID', 'IOS'))
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);

-- Like every table: nothing reachable through Supabase's own API roles.
DO $$
DECLARE
  r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);
    EXECUTE format('REVOKE ALL ON public.device_tokens FROM %I', r);
  END LOOP;
END
$$;

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
