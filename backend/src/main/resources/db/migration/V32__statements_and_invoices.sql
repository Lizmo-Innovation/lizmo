-- A statement to pay, and invoices once it is paid.
--
-- Lizmo issues one statement a month per landlord, itemised by property, and
-- that is the thing money arrives against. Each property's line becomes an
-- invoice -- numbered and dated -- at the moment the statement is settled in
-- full. Before that no invoice exists, because nothing has been paid for.
--
-- This inverts what V16 built, where the per-property row was the demand. It
-- keeps what V16 was protecting: a landlord still sees each building's own
-- figure and can check it against that building's income. What changes is that
-- they pay once, and one debt covers the account.
--
-- Nothing has ever been billed -- both scheduler jobs are still paused and
-- both tables are empty -- so this reshapes rather than migrates.

CREATE TABLE platform_statements (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  landlord_id       UUID NOT NULL REFERENCES landlord_profiles(user_id),
  billing_date      DATE NOT NULL,
  due_date          DATE NOT NULL,
  amount_due        NUMERIC(10,2) NOT NULL,
  amount_paid       NUMERIC(10,2) NOT NULL DEFAULT 0,
  status            VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
  overdue_warned_at TIMESTAMPTZ,
  locked_at         TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_statement_per_landlord UNIQUE (landlord_id, billing_date),
  CONSTRAINT chk_platform_statement_status
    CHECK (status IN ('UNPAID', 'PARTIALLY_PAID', 'PAID'))
);

-- A landlord's own history, newest month first.
CREATE INDEX idx_platform_statements_landlord
  ON platform_statements(landlord_id, billing_date DESC);

-- Everything enforcement has to look at.
CREATE INDEX idx_platform_statements_open
  ON platform_statements(due_date)
  WHERE status <> 'PAID';

-- Shut the door Supabase leaves open, as V28 did for every table that existed
-- then. A new table starts world-readable over PostgREST otherwise.
ALTER TABLE platform_statements ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);
    EXECUTE format('REVOKE ALL ON public.platform_statements FROM %I', r);
  END LOOP;
END
$$;

DELETE FROM platform_payments;
DELETE FROM platform_billing_cycles;

-- The per-property row keeps its table and changes job: a line on a statement
-- until that statement is paid, an invoice afterwards. What it is owed for is
-- still its own; what has been paid belongs to the statement, because that is
-- what somebody pays.
ALTER TABLE platform_billing_cycles
  DROP CONSTRAINT uq_billing_cycle_per_property,
  DROP COLUMN amount_paid,
  DROP COLUMN status,
  DROP COLUMN overdue_warned_at,
  DROP COLUMN locked_at,
  DROP COLUMN due_date,
  DROP COLUMN billing_date,
  ADD COLUMN statement_id UUID NOT NULL REFERENCES platform_statements(id) ON DELETE CASCADE,
  ADD COLUMN invoice_number VARCHAR(32),
  ADD COLUMN issued_at TIMESTAMPTZ;

ALTER TABLE platform_billing_cycles
  ADD CONSTRAINT uq_line_per_property UNIQUE (statement_id, property_id),
  ADD CONSTRAINT uq_platform_invoice_number UNIQUE (invoice_number);

-- What the invoice is called. A landlord files it against a building and
-- quotes it back when something is wrong, so it is a number rather than a
-- UUID: LZM-2026-09-0007.
CREATE SEQUENCE platform_invoice_number_seq;

-- Money arrives against the statement now, never against one property.
ALTER TABLE platform_payments
  DROP COLUMN billing_cycle_id,
  ADD COLUMN statement_id UUID NOT NULL REFERENCES platform_statements(id);

CREATE INDEX idx_platform_payments_statement
  ON platform_payments(statement_id, created_at);

-- Which statement locked a property, so paying lifts the locks that statement
-- placed and never one an admin placed by hand for some other reason. It was
-- a marker on the invoice, which could only ever speak for one property.
ALTER TABLE properties
  ADD COLUMN locked_by_statement_id UUID REFERENCES platform_statements(id);
