-- How a unit's utility charges reach the tenant.
--
-- COMBINED folds them into the rent billing period, so the tenant sees one
-- amount and pays once. SEPARATE issues them as their own charge, which is what
-- a landlord wants when rent and utilities are settled at different times, or
-- when a tenant pays rent by bank transfer and utilities in cash.
--
-- Defaults to COMBINED: it is the simpler of the two for everyone, and it is
-- what every unit created before this migration was implicitly doing.
ALTER TABLE units
  ADD COLUMN utility_billing VARCHAR(20) NOT NULL DEFAULT 'COMBINED',
  ADD CONSTRAINT chk_units_utility_billing
    CHECK (utility_billing IN ('COMBINED', 'SEPARATE'));
