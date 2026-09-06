-- Getting back in.
--
-- Until now a forgotten password was permanent: nothing in the app could
-- change one, so the only way back into an account was Ariel editing the hash
-- by hand. That is fine while every user is somebody he knows and unworkable
-- the moment one of them is not.
--
-- Shaped like email_verifications rather than landlord_invitations: a six
-- digit code typed into the app, not a link. Somebody resetting a password
-- already has Lizmo installed, so a browser round trip buys nothing -- and
-- deep links do not work yet, which is exactly why the invitation email has to
-- carry a paste-able token as a fallback.
CREATE TABLE password_resets (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Lower-cased by the application, as everywhere else. Ana@ and ana@ are the
  -- same person.
  --
  -- The address rather than a user id, deliberately: a code is issued without
  -- confirming an account exists, so this row must be writable for an address
  -- that has none. See PasswordResetService on why.
  email        VARCHAR(255) NOT NULL,

  -- Hashed, never the digits. The row is readable by anyone with database
  -- access -- a backup, a support query, a leaked dump -- and a plain code in
  -- it is a working key to somebody's account.
  code_hash    VARCHAR(255) NOT NULL,

  expires_at   TIMESTAMPTZ NOT NULL,

  -- Wrong guesses so far. Six digits with unlimited attempts falls to brute
  -- force in minutes.
  attempts     SMALLINT NOT NULL DEFAULT 0,

  -- Set when the code is used. Spent once: without this the same digits work
  -- again tomorrow, out of an inbox that may no longer be private.
  consumed_at  TIMESTAMPTZ,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE password_resets
  ADD CONSTRAINT chk_password_resets_attempts
    CHECK (attempts >= 0);

-- One live reset per address. Asking again replaces what was there, so the
-- previous code stops working the moment a new one is sent -- which is what
-- "a new code" has to mean, and without which two codes are live at once and
-- the attempt cap counts the wrong one.
CREATE UNIQUE INDEX uq_password_resets_live
  ON password_resets(email)
  WHERE consumed_at IS NULL;

-- The resend limit counts rows in a window.
CREATE INDEX idx_password_resets_email_created
  ON password_resets(email, created_at);
