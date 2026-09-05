-- Deleting an account.
--
-- Required by Google Play: an app that lets somebody create an account must
-- let them delete it, from inside the app and from a web page, and must say
-- what is removed and what is kept.
--
-- Soft, deliberately. A tenancy is a record between two people, and a lease,
-- its dates and its rent are as much the landlord's as the tenant's -- erasing
-- a user row would take a landlord's own history with it. So the account stops
-- existing as an account, and the records of what happened remain.
--
-- What does NOT survive is anything personal with no reason to be kept: the
-- name, the phone number, the address, and the photographs of a government ID.
-- Those are deleted by the application, which can also remove the objects from
-- storage -- something a migration cannot do.
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;

-- Signing in checks this, so a deleted account cannot be used even with the
-- right password. Partial, because almost every row is null.
CREATE INDEX idx_users_deleted ON users(deleted_at) WHERE deleted_at IS NOT NULL;

COMMENT ON COLUMN users.deleted_at IS
  'When the person asked to be deleted. The row survives so that leases and '
  'billing history stay readable to the other party; the identifying columns '
  'are overwritten at the same moment.';
