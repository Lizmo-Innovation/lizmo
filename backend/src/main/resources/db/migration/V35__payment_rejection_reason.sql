-- Why a landlord said a payment did not arrive.
--
-- Until now the reason was written over the payment's remarks, which are the
-- payer's own note ("paid from my sister's number"). Refusing a payment then
-- erased what the tenant said, and a tenant reading their own payment back
-- could not tell whose words they were looking at.
--
-- Older refused payments are left alone: their remarks may be either person's,
-- and there is no way to tell which. Only refusals from here on fill this.

ALTER TABLE payments ADD COLUMN rejection_reason TEXT;
