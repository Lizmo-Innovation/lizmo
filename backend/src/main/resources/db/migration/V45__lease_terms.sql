-- When a lease is meant to end, as distinct from when it did.
--
-- end_date is written when a tenancy actually ends, and the apps read it as
-- "moved out". A planned end is a different fact -- a tenancy past it is
-- still a tenancy until somebody ends it -- so it has its own column rather
-- than borrowing that one.
--
-- Null is the usual case: most rooms here are let month to month.

ALTER TABLE leases ADD COLUMN term_ends_on DATE;

-- The last warning sent about that end, so the daily job says each one once.
-- Cleared whenever the date changes: an extended lease is warned about again.
ALTER TABLE leases ADD COLUMN term_warned VARCHAR(20);

ALTER TABLE leases ADD CONSTRAINT chk_leases_term_warned
  CHECK (term_warned IN ('MONTH', 'WEEK', 'PASSED'));

ALTER TABLE leases ADD CONSTRAINT chk_leases_term_after_start
  CHECK (term_ends_on IS NULL OR term_ends_on > start_date);
