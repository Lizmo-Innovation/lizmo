-- Acknowledgement receipts: one for every payment a landlord has confirmed
-- or recorded.
--
-- A receipt is what was true when the money was acknowledged, kept as it was.
-- So it copies what it says rather than pointing at it: a property renamed
-- next year must not rewrite a receipt somebody handed to their employer.
--
-- Not a BIR official receipt, and the apps say so on its face.

CREATE TABLE receipts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id      UUID NOT NULL REFERENCES payments(id),
  lease_id        UUID NOT NULL REFERENCES leases(id),
  landlord_id     UUID NOT NULL REFERENCES users(id),
  tenant_id       UUID NOT NULL REFERENCES users(id),

  -- Numbered per landlord, per year, in the order they were issued: how a
  -- landlord files them. "2026-0042".
  year            SMALLINT NOT NULL,
  sequence        INTEGER NOT NULL,
  number          VARCHAR(20) NOT NULL,
  issued_at       TIMESTAMPTZ NOT NULL,

  received_from   VARCHAR(255) NOT NULL,
  received_by     VARCHAR(255) NOT NULL,
  property_name   VARCHAR(255) NOT NULL,
  place           VARCHAR(255) NOT NULL,
  period_label    VARCHAR(100) NOT NULL,
  kind            VARCHAR(20) NOT NULL,
  amount          NUMERIC(12, 2) NOT NULL,
  payment_method  VARCHAR(20) NOT NULL,
  sent_to         VARCHAR(255),
  paid_on         DATE NOT NULL,
  -- What was left of that month, or the deposit, once this was counted.
  still_owed      NUMERIC(12, 2) NOT NULL,

  CONSTRAINT uq_receipts_payment UNIQUE (payment_id),
  CONSTRAINT uq_receipts_number UNIQUE (landlord_id, year, sequence),
  CONSTRAINT chk_receipts_kind CHECK (kind IN ('RENT', 'DEPOSIT'))
);

CREATE INDEX idx_receipts_lease ON receipts(lease_id);

-- The last number each landlord was given each year. One row, updated in
-- place, so two confirmations at the same moment cannot share a number.
CREATE TABLE receipt_counters (
  landlord_id  UUID NOT NULL REFERENCES users(id),
  year         SMALLINT NOT NULL,
  last_number  INTEGER NOT NULL,
  PRIMARY KEY (landlord_id, year)
);

-- Every payment already confirmed gets its receipt, numbered in the order
-- it was confirmed, so a tenant's history has them as well as what comes
-- next. "Still owed" is worked out as it stood after each payment.
WITH confirmed AS (
  SELECT pay.id AS payment_id,
         pay.lease_id,
         p.landlord_id,
         l.tenant_id,
         COALESCE(pay.verified_at, pay.created_at) AS issued_at,
         tenant.name AS received_from,
         landlord.name AS received_by,
         p.name AS property_name,
         CASE WHEN b.id IS NULL THEN 'Unit ' || u.unit_number
              ELSE b.bed_label || ', ' || u.unit_number END AS place,
         bp.period_label,
         bp.kind,
         pay.amount_paid AS amount,
         pay.payment_method,
         pay.sent_to,
         pay.payment_date AS paid_on,
         GREATEST(bp.amount_due - SUM(pay.amount_paid) OVER (
             PARTITION BY pay.billing_period_id
             ORDER BY COALESCE(pay.verified_at, pay.created_at), pay.id
             ROWS UNBOUNDED PRECEDING), 0) AS still_owed
    FROM payments pay
    JOIN billing_periods bp ON bp.id = pay.billing_period_id
    JOIN leases l ON l.id = pay.lease_id
    JOIN units u ON u.id = l.unit_id
    JOIN properties p ON p.id = u.property_id
    JOIN users tenant ON tenant.id = l.tenant_id
    JOIN users landlord ON landlord.id = p.landlord_id
    LEFT JOIN beds b ON b.id = l.bed_id
   WHERE pay.status = 'CONFIRMED'
     AND NOT EXISTS (SELECT 1 FROM receipts r WHERE r.payment_id = pay.id)
), numbered AS (
  SELECT c.*,
         EXTRACT(YEAR FROM c.issued_at AT TIME ZONE 'Asia/Manila')::SMALLINT AS year,
         ROW_NUMBER() OVER (
             PARTITION BY c.landlord_id,
                          EXTRACT(YEAR FROM c.issued_at AT TIME ZONE 'Asia/Manila')
             ORDER BY c.issued_at, c.payment_id)::INTEGER AS sequence
    FROM confirmed c
)
INSERT INTO receipts
  (payment_id, lease_id, landlord_id, tenant_id, year, sequence, number,
   issued_at, received_from, received_by, property_name, place, period_label,
   kind, amount, payment_method, sent_to, paid_on, still_owed)
SELECT payment_id, lease_id, landlord_id, tenant_id, year, sequence,
       year || '-' || LPAD(sequence::TEXT, 4, '0'),
       issued_at, received_from, received_by, property_name, place, period_label,
       kind, amount, payment_method, sent_to, paid_on, still_owed
  FROM numbered;

INSERT INTO receipt_counters (landlord_id, year, last_number)
SELECT landlord_id, year, MAX(sequence)
  FROM receipts
 GROUP BY landlord_id, year
ON CONFLICT (landlord_id, year)
DO UPDATE SET last_number = GREATEST(receipt_counters.last_number, EXCLUDED.last_number);

-- Like every table: nothing reachable through Supabase's own API roles.
DO $$
DECLARE
  r text;
  t text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);
    FOREACH t IN ARRAY ARRAY['receipts', 'receipt_counters'] LOOP
      EXECUTE format('REVOKE ALL ON public.%I FROM %I', t, r);
    END LOOP;
  END LOOP;
END
$$;

ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipt_counters ENABLE ROW LEVEL SECURITY;
