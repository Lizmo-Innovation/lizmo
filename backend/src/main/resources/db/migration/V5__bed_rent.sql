-- Lets a landlord price one bed differently from the rest of its unit.
--
-- Nullable on purpose, and null is not "free": it means this bed is let at
-- whatever the unit asks. Most landlords charge the same for every bed in a
-- room, so the unit's rent stays the answer and a per-bed figure is the
-- exception -- a lower bunk that goes for less, a bed by the window for more.
--
-- Mirrors chk_units_rent_positive: zero would read as free rather than unset.
ALTER TABLE beds
  ADD COLUMN rent NUMERIC(10,2),
  ADD CONSTRAINT chk_beds_rent_positive CHECK (rent IS NULL OR rent > 0);
