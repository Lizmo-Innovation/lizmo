-- The deposit and the advance, as money a tenant pays at move-in and a
-- landlord confirms -- the same as rent.
--
-- Until now both were figures on the lease, assumed taken. The advance was
-- recorded as a confirmed payment the moment the lease was written, whether
-- or not anybody had handed it over; the deposit was never owed, paid or
-- confirmed at all, and appeared only at move-out.

-- A billing period is rent for a month, or the security deposit.
ALTER TABLE billing_periods
  ADD COLUMN kind VARCHAR(20) NOT NULL DEFAULT 'RENT';

ALTER TABLE billing_periods
  ADD CONSTRAINT chk_billing_periods_kind CHECK (kind IN ('RENT', 'DEPOSIT'));

-- The deposit starts on move-in day, as the first month does. One of each
-- kind per day, rather than one of anything.
ALTER TABLE billing_periods DROP CONSTRAINT uq_period_per_lease;

ALTER TABLE billing_periods
  ADD CONSTRAINT uq_period_per_lease UNIQUE (lease_id, kind, period_start);

-- Which leases are billed this way. Every lease already written keeps what it
-- had: an existing tenancy whose later months are not written yet must not
-- find one of them suddenly due -- and overdue -- on the day this ships.
ALTER TABLE leases
  ADD COLUMN charged_at_move_in BOOLEAN NOT NULL DEFAULT false;

-- Their deposits, recorded once as received at move-in: which is what the
-- landlord said when they wrote the lease. Nobody is billed for a deposit
-- they handed over months ago, and a move-out can still be checked against
-- what was actually received.
INSERT INTO billing_periods
  (lease_id, period_label, period_start, period_end, due_date,
   amount_due, amount_paid, status, kind)
SELECT l.id, 'Security deposit', l.start_date, l.start_date, l.start_date,
       l.deposit_amount, l.deposit_amount, 'PAID', 'DEPOSIT'
  FROM leases l
 WHERE l.deposit_amount IS NOT NULL
   AND l.deposit_amount > 0;

-- With the payment behind each, because a period's amount_paid has to agree
-- with the payments it is made of.
INSERT INTO payments
  (lease_id, billing_period_id, amount_paid, payment_date, payment_method,
   status, submitted_by, verified_by, verified_at, remarks)
SELECT bp.lease_id, bp.id, bp.amount_paid, bp.period_start, 'OTHER',
       'CONFIRMED', l.tenant_id, p.landlord_id, now(),
       'Recorded as received when the lease was written.'
  FROM billing_periods bp
  JOIN leases l ON l.id = bp.lease_id
  JOIN units u ON u.id = l.unit_id
  JOIN properties p ON p.id = u.property_id
 WHERE bp.kind = 'DEPOSIT';
