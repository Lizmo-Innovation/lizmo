-- Announcements from a landlord to the people renting from them.
--
-- The tables have been here since the start, unused; this is the first code
-- to write them. What a tenant sees is worked out from where they live now,
-- by property and unit, and which of them have read a notice by tenant -- so
-- both are looked up that way.

CREATE INDEX IF NOT EXISTS idx_notices_unit ON notices(unit_id);
CREATE INDEX IF NOT EXISTS idx_notice_reads_tenant ON notice_reads(tenant_id);
