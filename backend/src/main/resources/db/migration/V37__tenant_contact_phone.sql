-- How a landlord reaches somebody who asked about a room.
--
-- The request a landlord reads carries users.phone, and registration only ever
-- collects an email -- so that number has been null for every tenant since the
-- first one. A landlord judging a request could not phone the person making it.
--
-- Kept here rather than filled into users.phone: that column is a login
-- identifier and unique, so a household sharing one number could not both have
-- accounts, and a typo would lock somebody out of signing in rather than
-- merely misdirect a call.
--
-- This is also the one thing asked before a tenant may ask for a room. The ID,
-- the emergency contact and the ID photograph are asked later, when the
-- landlord accepts -- a stranger should not have to hand over identity
-- documents to ask whether a bed is still free.

ALTER TABLE tenant_profiles ADD COLUMN contact_phone VARCHAR(30);
