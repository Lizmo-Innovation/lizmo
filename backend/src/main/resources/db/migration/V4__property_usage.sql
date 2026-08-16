-- Lets a landlord say whether a property is residential or commercial.
--
-- The four types that existed before this migration are all residential
-- building forms, so backfilling every existing row to RESIDENTIAL is correct
-- rather than merely convenient.
--
-- usage is a non-reserved keyword in PostgreSQL, so it needs no quoting.

ALTER TABLE properties
  ADD COLUMN usage VARCHAR(20) NOT NULL DEFAULT 'RESIDENTIAL';

-- The default existed to backfill; the API always supplies the value, and
-- leaving it would let a bug that omits usage silently write RESIDENTIAL.
ALTER TABLE properties
  ALTER COLUMN usage DROP DEFAULT;

ALTER TABLE properties
  ADD CONSTRAINT chk_properties_usage CHECK (usage IN ('RESIDENTIAL', 'COMMERCIAL'));

-- Replaced rather than extended: the pairing constraint below already restricts
-- type to the eight valid values, so keeping both would be redundant.
ALTER TABLE properties
  DROP CONSTRAINT chk_properties_type;

ALTER TABLE properties
  ADD CONSTRAINT chk_properties_usage_type CHECK (
    (usage = 'RESIDENTIAL' AND type IN ('APARTMENT', 'BOARDING_HOUSE', 'CONDO', 'SINGLE_HOUSE')) OR
    (usage = 'COMMERCIAL'  AND type IN ('OFFICE', 'RETAIL_SPACE', 'WAREHOUSE', 'STALL'))
  );
