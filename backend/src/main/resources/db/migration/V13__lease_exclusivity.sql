-- Leases become real in this migration. The table has existed unused since V1;
-- what it has been missing is the rule that makes it safe to write to.

-- One active lease per whole unit.
--
-- Its twin, uq_active_lease_per_bed, has been in place since V2. This one was
-- created there too and then dropped during the V8 repair, when a half-applied
-- migration had to be unpicked by hand -- and never put back. Nothing noticed
-- because nothing wrote a lease. The first accepted request would have been
-- able to double-let a room.
--
-- Partial on bed_id IS NULL: a bedspace unit holds one active lease per bed,
-- so unit-level exclusivity must apply only to units let entire.
CREATE UNIQUE INDEX uq_active_lease_per_unit
  ON leases(unit_id)
  WHERE status = 'ACTIVE' AND bed_id IS NULL;

-- Which request became this lease.
--
-- Nullable, because a landlord will eventually be able to write a lease
-- directly for somebody already living there -- an existing boarding house
-- moving onto Lizmo has tenants who never sent a request. Where there is one,
-- it is what lets a tenant open their accepted request and find the lease.
ALTER TABLE leases ADD COLUMN rental_request_id UUID REFERENCES rental_requests(id);

CREATE UNIQUE INDEX uq_leases_rental_request
  ON leases(rental_request_id)
  WHERE rental_request_id IS NOT NULL;
