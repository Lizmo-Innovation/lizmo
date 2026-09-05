-- Billing and locking move from the landlord to the property.
--
-- A landlord with three boarding houses used to have one invoice and one
-- status: fall behind on the portfolio and lose the ability to manage all of
-- it. That is collective punishment across buildings that have nothing to do
-- with each other, and proportionality is what makes an enforcement mechanism
-- legitimate rather than punitive.
--
-- It also matches how landlords already think. They run buildings, not
-- portfolios -- "Sunrise is doing fine, the new one isn't" -- and an invoice
-- per building is a number they can check against that building's income. A
-- single blended charge across three properties is a number nobody can verify.
--
-- Cheap to do now: nothing raises a billing cycle yet, so there is no data to
-- migrate and no landlord has ever been locked.

-- A property that may not be added to. Never affects the tenants living in it:
-- see LandlordAccountStatus's replacement in the application layer.
ALTER TABLE properties
  ADD COLUMN account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE properties
  ADD CONSTRAINT chk_properties_account_status
    CHECK (account_status IN ('ACTIVE', 'LOCKED'));

-- Finding what is locked is a question the admin console asks constantly, and
-- almost nothing is locked, so the index is small.
CREATE INDEX idx_properties_locked
  ON properties(landlord_id)
  WHERE account_status = 'LOCKED';

-- One invoice per property per month, rather than per landlord.
--
-- Empty table: dropping and recreating the column is honest about the fact
-- that no existing row could be assigned a property, since a landlord-level
-- cycle does not know which building it was for.
DELETE FROM platform_payments;
DELETE FROM platform_billing_cycles;

ALTER TABLE platform_billing_cycles
  DROP CONSTRAINT uq_billing_cycle_per_landlord;

ALTER TABLE platform_billing_cycles
  DROP COLUMN landlord_id,
  ADD COLUMN property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE;

ALTER TABLE platform_billing_cycles
  ADD CONSTRAINT uq_billing_cycle_per_property UNIQUE (property_id, billing_date);

-- What the invoice was priced at, stored on the invoice.
--
-- Prices change; an invoice from March must still explain itself in September
-- as "8 beds at 20 pesos". Without this, amount_due is a number nobody can
-- reconstruct -- which is exactly what a landlord will telephone about.
ALTER TABLE platform_billing_cycles
  ADD COLUMN unit_rate NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN bed_rate  NUMERIC(10,2) NOT NULL DEFAULT 0;

-- The landlord who owes it is reachable through the property; keeping a copy
-- here would be a second place for the answer to disagree.
ALTER TABLE platform_payments
  DROP COLUMN landlord_id;

-- The landlord-wide lock is gone. Nothing ever set it: the enforcement job
-- does not exist, so no account was ever locked by it.
ALTER TABLE landlord_profiles
  DROP CONSTRAINT chk_landlord_account_status;

ALTER TABLE landlord_profiles
  DROP COLUMN account_status;
