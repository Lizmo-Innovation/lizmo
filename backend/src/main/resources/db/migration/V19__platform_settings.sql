-- Settings an operator can change without a deploy.
--
-- The first is the address somebody writes to when they want their account
-- deleted and cannot use the app. Google Play requires that address to be
-- published, which means it appears on a public page -- and a published
-- address that can only be changed by rebuilding and redeploying the app is
-- one that stays wrong for a week.
--
-- Key/value rather than a column per setting: these are operator knobs, not
-- domain data. A new one should be a row, not a migration.
CREATE TABLE platform_settings (
  key         VARCHAR(64) PRIMARY KEY,
  value       TEXT NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Which admin changed it. A support address is what a stranger is told to
  -- write to; changing it silently should not be possible.
  updated_by  UUID REFERENCES users(id)
);

-- Seeded so the public page has something to show before anybody visits the
-- console. It is also the address the app was built around.
INSERT INTO platform_settings (key, value)
VALUES ('support_email', 'lizmodev@gmail.com');
