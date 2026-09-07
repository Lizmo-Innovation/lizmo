-- Rent, as something the app can answer questions about.
--
-- billing_periods and payments have existed since V1 and nothing has ever
-- written to them. Almost nothing needs changing; what follows is the two
-- places the original shape does not fit the way rent is actually collected.

-- 1. Proof is not always possible.
--
-- proof_image_url was NOT NULL, which requires a screenshot for every payment
-- ever recorded. A landlord writing down cash they were handed at the door has
-- none, and a required field nobody can satisfy becomes a field people lie in.
--
-- Dropped rather than made nullable: files belong in `documents` now, with
-- presigned URLs and one retention story, and a second column holding a URL
-- would be a second way to do the same thing.
ALTER TABLE payments DROP COLUMN proof_image_url;

-- 2. An advance is a payment, and not like the others.
--
-- Rent handed over before moving in pays the first month -- Ariel's call. That
-- has to be a payment row, or amount_paid on a period would disagree with the
-- payments behind it, and the first month would read as unpaid to a tenant who
-- had already paid it.
--
-- Its own method rather than OTHER, because "paid in advance at the door" and
-- "paid by some means we did not list" are different facts, and a landlord
-- looking back should not have to read a remark to tell them apart.
ALTER TABLE payments DROP CONSTRAINT chk_payments_method;

ALTER TABLE payments
  ADD CONSTRAINT chk_payments_method CHECK (payment_method IN (
    'CASH', 'GCASH', 'MAYA', 'BANK_TRANSFER', 'OTHER', 'ADVANCE'
  ));

-- Periods are read per lease, oldest first, every time somebody opens the
-- rent screen. The V1 index is on lease alone and leaves the sort to be done
-- each time.
CREATE INDEX idx_billing_periods_lease_start
  ON billing_periods(lease_id, period_start);

-- Nothing writes OVERDUE. Whether rent is late is a question about today, and
-- a stored answer is wrong from the moment it is written until something runs
-- to correct it. The status column holds UNPAID, PARTIALLY_PAID and PAID; the
-- app works out lateness from due_date at the moment it is asked. The value
-- stays in the constraint so old rows -- there are none -- would still load.
