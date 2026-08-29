-- Every property gets a short code a tenant can type or scan, which is how
-- they find the place and see what is vacant.

ALTER TABLE properties ADD COLUMN code VARCHAR(8);

-- Every code ever issued, and the reason a code is never handed out twice.
--
-- Deleting a property frees its row in properties, and with it the unique index
-- below -- so without this ledger a later property could mint the same code,
-- and a tenant scanning an old QR or an unchanged sign by the gate would be
-- looking at somebody else's building. Insert-only: nothing removes from here.
CREATE TABLE issued_property_codes (
  code       VARCHAR(8) PRIMARY KEY,
  issued_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One property per code at a time. The ledger says a code is spent; this says
-- who currently holds it.
CREATE UNIQUE INDEX uq_properties_code ON properties(code);

-- Backfilled row by row, because each row needs its own random value and a
-- collision has to be retried rather than aborting. The insert into the ledger
-- is what raises on collision, so it goes first -- claim the code, then use it.
--
-- The alphabet omits 0/O and 1/I/L: these codes get read aloud, chalked on a
-- board by the gate, and typed by someone who has just moved in, and those are
-- the pairs people get wrong.
DO $$
DECLARE
  target     RECORD;
  candidate  TEXT;
  alphabet   TEXT := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  attempts   INT;
BEGIN
  FOR target IN SELECT id FROM properties WHERE code IS NULL LOOP
    attempts := 0;
    LOOP
      candidate := 'PH';
      FOR i IN 1..6 LOOP
        candidate := candidate
          || substr(alphabet, floor(random() * length(alphabet))::int + 1, 1);
      END LOOP;

      BEGIN
        INSERT INTO issued_property_codes(code) VALUES (candidate);
        UPDATE properties SET code = candidate WHERE id = target.id;
        EXIT;
      EXCEPTION WHEN unique_violation THEN
        attempts := attempts + 1;
        IF attempts > 20 THEN
          RAISE EXCEPTION 'Could not find a free property code after % attempts', attempts;
        END IF;
      END;
    END LOOP;
  END LOOP;
END $$;

ALTER TABLE properties ALTER COLUMN code SET NOT NULL;

-- PH, then six characters. Uppercase only: lookup upper-cases what the tenant
-- typed, so without this a lower-case row could exist that no typed code would
-- ever match.
ALTER TABLE properties
  ADD CONSTRAINT chk_properties_code_shape
    CHECK (code ~ '^PH[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}$');

ALTER TABLE issued_property_codes
  ADD CONSTRAINT chk_issued_property_codes_shape
    CHECK (code ~ '^PH[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}$');
