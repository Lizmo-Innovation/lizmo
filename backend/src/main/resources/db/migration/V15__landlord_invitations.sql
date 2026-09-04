-- How somebody becomes a landlord.
--
-- Not by asking. The old sign-up had a checkbox, which meant a landlord was
-- anyone who fancied the extra buttons; Lizmo bills landlords and answers to
-- them, so the relationship starts with Lizmo inviting them by name.
--
-- A table of its own for the same reason email_verifications is: nothing about
-- the person exists until they accept. An invitation that is never taken up
-- expires and leaves no half-made account behind.
CREATE TABLE landlord_invitations (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Lower-cased by the application, as everywhere else. Ana@ and ana@ are the
  -- same person, including to the check for an existing account.
  email        VARCHAR(255) NOT NULL,

  -- Hashed, never the token itself. The link in the email is a working key to
  -- a landlord account, and this row is readable by anyone with a backup or a
  -- support query.
  --
  -- Plain SHA-256 rather than bcrypt: the token is 256 bits of randomness
  -- already, so there is nothing to brute-force, and bcrypt would silently
  -- truncate it at 72 bytes besides.
  token_hash   VARCHAR(255) NOT NULL,

  -- Which admin sent it. Granting somebody the ability to own property, and
  -- to read the details of everyone who asks to live there, should not be
  -- anonymous.
  invited_by   UUID NOT NULL REFERENCES users(id),

  -- Long enough to survive a weekend and a forwarded email; short enough that
  -- a link found in an old inbox two years from now is worthless.
  expires_at   TIMESTAMPTZ NOT NULL,

  -- Set when it is used. One invitation, one landlord: without this the same
  -- link makes a second account, or re-adds a profile that was deliberately
  -- taken away.
  accepted_at  TIMESTAMPTZ,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One live invitation per address. Inviting again replaces what was there, so
-- the older link stops working the moment a new one is sent -- otherwise two
-- links are valid at once and revoking means finding every one of them.
CREATE UNIQUE INDEX uq_landlord_invitations_live
  ON landlord_invitations(email)
  WHERE accepted_at IS NULL;

-- Accepting looks the invitation up by nothing but its token.
CREATE INDEX idx_landlord_invitations_token
  ON landlord_invitations(token_hash);
