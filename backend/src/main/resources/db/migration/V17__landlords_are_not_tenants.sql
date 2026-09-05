-- A landlord is not a tenant.
--
-- The original design made them additive: everybody got a tenant profile, and
-- landlord was added on top, so a caretaker could rent a bedspace elsewhere.
-- Ariel's call is that they are now separate people as far as Lizmo is
-- concerned -- one account is one side of the arrangement.
--
-- What that changes elsewhere: accepting an invitation no longer creates a
-- tenant profile, and an address that already rents cannot be invited at all.
--
-- Existing accounts holding both are cleaned up here, but only where nothing
-- is attached. Anyone who genuinely rents keeps both roles and keeps the
-- role switcher in the app: the rule applies to landlords made from now on,
-- and rewriting somebody's history to satisfy a new rule is how tenancies go
-- missing.
DELETE FROM tenant_profiles t
WHERE EXISTS (
        SELECT 1 FROM landlord_profiles l WHERE l.user_id = t.user_id
      )
  -- A lease is the thing that makes somebody a tenant. The foreign key from
  -- leases would refuse this delete anyway; saying it here means the migration
  -- reports "0 rows" rather than failing on a constraint.
  AND NOT EXISTS (
        SELECT 1 FROM leases lease WHERE lease.tenant_id = t.user_id
      )
  -- A request in flight is a tenancy about to exist. Stripping the profile
  -- underneath it would leave a landlord looking at a request from somebody
  -- Lizmo no longer considers a tenant.
  AND NOT EXISTS (
        SELECT 1 FROM rental_requests r
        WHERE r.tenant_id = t.user_id AND r.status = 'PENDING'
      );

-- Not touched: documents uploaded against a stripped profile. They are rows in
-- stored_documents with no foreign key to here, and a migration is the wrong
-- place to delete objects out of Supabase Storage. DocumentRetentionService is
-- the thing that should learn about them.
