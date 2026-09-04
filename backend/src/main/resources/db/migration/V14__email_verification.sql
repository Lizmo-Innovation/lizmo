-- Proving somebody owns the address they typed, before an account exists.
--
-- A table of its own rather than columns on users, because nothing is created
-- until the password is set. An abandoned sign-up leaves a row here that
-- expires and is swept up; created as a passwordless user instead, it would
-- squat on that address for good -- unreachable, and blocking the person who
-- comes back to finish properly.
CREATE TABLE email_verifications (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Lower-cased by the application before it lands here. Addresses are
  -- compared as typed otherwise, and Ana@ would be a different person to ana@.
  email        VARCHAR(255) NOT NULL,

  -- Hashed, never the digits. The row is readable by anyone with database
  -- access -- a backup, a support query, a leaked dump -- and a plain code in
  -- it is a working key to somebody's sign-up.
  code_hash    VARCHAR(255) NOT NULL,

  expires_at   TIMESTAMPTZ NOT NULL,

  -- Wrong guesses so far. Six digits with unlimited attempts falls to brute
  -- force in minutes, which is the difference between a real check and a
  -- decorative one.
  attempts     SMALLINT NOT NULL DEFAULT 0,

  -- Set when the code is used. A verification is spent once: without this the
  -- same digits work again tomorrow, out of an inbox that may no longer be
  -- private.
  consumed_at  TIMESTAMPTZ,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE email_verifications
  ADD CONSTRAINT chk_email_verifications_attempts
    CHECK (attempts >= 0);

-- One live verification per address. Asking again replaces what was there, so
-- the previous code stops working the moment a new one is sent -- which is
-- what "a new code" has to mean.
CREATE UNIQUE INDEX uq_email_verifications_live
  ON email_verifications(email)
  WHERE consumed_at IS NULL;

-- The resend limit counts rows in a window, and the sweep deletes old ones.
CREATE INDEX idx_email_verifications_email_created
  ON email_verifications(email, created_at);

-- Every account that exists today was created before any of this and has never
-- proved an address. Marking them verified keeps Ariel's own test accounts and
-- both test phones working; they are his, not strangers'.
ALTER TABLE users ADD COLUMN email_verified_at TIMESTAMPTZ;

UPDATE users SET email_verified_at = created_at WHERE email IS NOT NULL;
