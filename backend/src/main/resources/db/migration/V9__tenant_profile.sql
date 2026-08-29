-- What a tenant tells a landlord before signing a lease.
--
-- Name, phone and email stay on users: they are identity, and a landlord
-- account has them too. What lives here is what a landlord asks a tenant
-- specifically -- who to call in an emergency, what ID they carry, where they
-- are from.
--
-- Every column is nullable. A tenant fills this in on a phone at move-in and
-- will skip whatever they can; a half-finished profile is worth more than an
-- abandoned one. Which fields a *lease* requires is a separate rule, enforced
-- where leases are created rather than by the shape of this table.
ALTER TABLE tenant_profiles
  ADD COLUMN birthdate DATE,
  ADD COLUMN permanent_address TEXT,
  ADD COLUMN occupation VARCHAR(255),

  -- Asked by every boarding house, and the one field that matters most on the
  -- day it is needed.
  ADD COLUMN emergency_contact_name VARCHAR(255),
  ADD COLUMN emergency_contact_relationship VARCHAR(100),
  ADD COLUMN emergency_contact_phone VARCHAR(30),

  ADD COLUMN id_type VARCHAR(30),
  ADD COLUMN id_number VARCHAR(50);

-- The IDs a Philippine tenant is likely to carry. OTHER exists so a valid ID
-- that is not on this list does not stop someone renting a bed.
ALTER TABLE tenant_profiles
  ADD CONSTRAINT chk_tenant_profiles_id_type CHECK (id_type IS NULL OR id_type IN (
    'PHILSYS', 'UMID', 'SSS', 'GSIS', 'DRIVERS_LICENSE', 'PASSPORT',
    'PHILHEALTH', 'POSTAL', 'VOTERS', 'TIN', 'PRC', 'OTHER'
  ));

-- A birthdate in the future is a typo, and one before 1900 is a slipped digit.
ALTER TABLE tenant_profiles
  ADD CONSTRAINT chk_tenant_profiles_birthdate
    CHECK (birthdate IS NULL OR (birthdate > DATE '1900-01-01' AND birthdate < now()));
