-- Gives a unit its own rent: what the landlord asks for it.
--
-- The tech spec put rent only on the lease, but the product spec also says
-- "each unit's rent differs independently even within the same property" — a
-- statement about the unit, not about whoever happens to be renting it. A
-- landlord knows a bedspace is ₱2,500 before any tenant exists; that is what
-- they advertise, and today there is nowhere to record it.
--
-- This does NOT replace leases.rent_amount. The lease stays authoritative for
-- what a tenant actually pays, because that legitimately differs: an old tenant
-- on an old rate, a discount for a long stay. Unit rent is the default a new
-- lease starts from, nothing more.
--
-- Nullable on purpose. Units created before this migration have no asking price
-- and inventing one would be a lie; the UI shows "not set" rather than ₱0.00,
-- which would read as free.
ALTER TABLE units
  ADD COLUMN rent NUMERIC(10,2),
  ADD CONSTRAINT chk_units_rent_positive CHECK (rent IS NULL OR rent > 0);

COMMENT ON COLUMN units.rent IS
  'Asking rent: per bed for BEDSPACE, for the whole unit for WHOLE_UNIT. '
  'A default for new leases; leases.rent_amount is what is actually charged.';
