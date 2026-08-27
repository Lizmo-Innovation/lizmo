-- A description a landlord writes for a property.
--
-- Nullable rather than defaulting to an empty string: "no description" and "a
-- description that says nothing" are different, and every other optional field
-- here already draws that line.
--
-- Capped at 2000 characters, which is roughly 300 words. TEXT is unbounded, so
-- without this a paste from a word processor lands in the database and then in
-- every property list response. The API enforces the same limit; this is the
-- guarantee that survives a client that does not.
ALTER TABLE properties
  ADD COLUMN description TEXT,
  ADD CONSTRAINT chk_properties_description_length
    CHECK (description IS NULL OR length(description) <= 2000);
