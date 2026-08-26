-- Fixed monthly utility charges on a unit.
--
-- A row per utility rather than columns on units: the set grows -- LPG and
-- garbage collection are both common here -- and a new one should be a
-- constraint change, not a migration of the units table.
--
-- enabled and amount are kept apart on purpose. Switching a utility off keeps
-- the figure, so a landlord who turns WiFi off for a month and back on again
-- does not have to remember what they were charging. The same reasoning as a
-- bed keeping its rent while out of service.
CREATE TABLE unit_utilities (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id     UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  kind        VARCHAR(20) NOT NULL,
  enabled     BOOLEAN NOT NULL DEFAULT false,
  amount      NUMERIC(10,2),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_utility_per_unit UNIQUE (unit_id, kind),
  CONSTRAINT chk_unit_utilities_kind CHECK (kind IN ('WIFI', 'ELECTRICITY', 'WATER')),
  -- Zero would read as free rather than unset, as everywhere else money is
  -- stored; and a utility that is on has to say what it costs.
  CONSTRAINT chk_unit_utilities_amount CHECK (amount IS NULL OR amount > 0),
  CONSTRAINT chk_unit_utilities_enabled_has_amount CHECK (NOT enabled OR amount IS NOT NULL)
);

CREATE INDEX idx_unit_utilities_unit ON unit_utilities(unit_id);
