-- What a tenant hands over before they move in, and what happens to it after.
--
-- Two different things, kept apart on purpose.
--
-- ADVANCE is rent. It pays for particular months -- the first, by Ariel's
-- call -- and once billing exists it will pay down the earliest unpaid
-- periods. Money the landlord has earned.
--
-- DEPOSIT is not rent. It is held against damage and unpaid bills, and most of
-- it usually goes back when the tenancy ends. Money the landlord is holding,
-- not money they have.
--
-- One "upfront money" column would have made the end of a tenancy
-- unanswerable: nothing could say how much of it was ever owed back.
ALTER TABLE leases
  ADD COLUMN deposit_amount  NUMERIC(10,2),
  ADD COLUMN advance_amount  NUMERIC(10,2);

-- Nullable rather than DEFAULT 0. A landlord who took no deposit and one who
-- has not recorded what they took are different facts, and only null can say
-- the second. The apps render null as a dash and zero as "P0", which is the
-- distinction a tenant asking "did I pay a deposit?" needs.

-- Settling up, recorded when the tenancy ends.
ALTER TABLE leases
  ADD COLUMN deposit_returned      NUMERIC(10,2),
  ADD COLUMN deposit_settlement    TEXT;

-- deposit_returned is likewise nullable: a lease that has not ended has not
-- settled anything, and zero would claim the tenant got nothing back.
--
-- The note is free text and deliberately not a list of itemised deductions.
-- Withholding money is where tenancies go wrong, and a landlord explaining it
-- in their own words is worth more than a form nobody fills in honestly.

ALTER TABLE leases
  ADD CONSTRAINT chk_leases_deposit_amount CHECK (deposit_amount IS NULL OR deposit_amount >= 0),
  ADD CONSTRAINT chk_leases_advance_amount CHECK (advance_amount IS NULL OR advance_amount >= 0),
  ADD CONSTRAINT chk_leases_deposit_returned CHECK (deposit_returned IS NULL OR deposit_returned >= 0);
