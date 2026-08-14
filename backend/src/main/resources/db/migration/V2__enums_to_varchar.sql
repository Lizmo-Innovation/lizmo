-- Replaces the 22 native enum types with varchar + CHECK constraints.
--
-- The tech spec specifies PostgreSQL enums. They are stricter, but they fight
-- JPA: Hibernate has no built-in mapping, so every insert and update needs an
-- explicit ::enum cast, and native queries and parameter binding get awkward.
-- varchar + CHECK maps directly to @Enumerated(EnumType.STRING) and keeps the
-- same guarantee at the database level.
--
-- It also makes the values easier to extend: adding a payment method becomes a
-- constraint swap inside a transaction, where ALTER TYPE ... ADD VALUE cannot
-- run in one and cannot remove a value at all.
--
-- USING col::text preserves existing rows; the tables are empty today, but this
-- migration must stay correct for environments where they are not.

-- ========== USERS ==========
ALTER TABLE users
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(20) USING status::text,
  ALTER COLUMN status SET DEFAULT 'ACTIVE',
  ADD CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'INACTIVE'));

ALTER TABLE landlord_profiles
  ALTER COLUMN account_status DROP DEFAULT,
  ALTER COLUMN account_status TYPE VARCHAR(20) USING account_status::text,
  ALTER COLUMN account_status SET DEFAULT 'ACTIVE',
  ADD CONSTRAINT chk_landlord_account_status CHECK (account_status IN ('ACTIVE', 'LOCKED'));

-- ========== PROPERTY / UNIT / BED ==========
ALTER TABLE properties
  ALTER COLUMN type TYPE VARCHAR(30) USING type::text,
  ADD CONSTRAINT chk_properties_type CHECK (type IN ('APARTMENT', 'BOARDING_HOUSE', 'CONDO', 'SINGLE_HOUSE'));

ALTER TABLE units
  ALTER COLUMN rental_mode TYPE VARCHAR(20) USING rental_mode::text,
  ADD CONSTRAINT chk_units_rental_mode CHECK (rental_mode IN ('WHOLE_UNIT', 'BEDSPACE'));

ALTER TABLE units
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(30) USING status::text,
  ALTER COLUMN status SET DEFAULT 'VACANT',
  ADD CONSTRAINT chk_units_status CHECK (status IN ('VACANT', 'PARTIALLY_OCCUPIED', 'OCCUPIED', 'MAINTENANCE'));

ALTER TABLE beds
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(20) USING status::text,
  ALTER COLUMN status SET DEFAULT 'VACANT',
  ADD CONSTRAINT chk_beds_status CHECK (status IN ('VACANT', 'OCCUPIED', 'MAINTENANCE'));

-- ========== LEASE ==========
-- The partial unique index references status, so it is dropped and recreated
-- around the type change.
DROP INDEX uq_active_lease_per_bed;

ALTER TABLE leases
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(20) USING status::text,
  ALTER COLUMN status SET DEFAULT 'ACTIVE',
  ADD CONSTRAINT chk_leases_status CHECK (status IN ('ACTIVE', 'ENDED', 'TERMINATED'));

CREATE UNIQUE INDEX uq_active_lease_per_bed
  ON leases(bed_id) WHERE status = 'ACTIVE' AND bed_id IS NOT NULL;

-- ========== BILLING & PAYMENTS ==========
ALTER TABLE billing_periods
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(20) USING status::text,
  ALTER COLUMN status SET DEFAULT 'UNPAID',
  ADD CONSTRAINT chk_billing_periods_status CHECK (status IN ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'OVERDUE'));

ALTER TABLE payments
  ALTER COLUMN payment_method TYPE VARCHAR(20) USING payment_method::text,
  ADD CONSTRAINT chk_payments_method CHECK (payment_method IN ('CASH', 'GCASH', 'MAYA', 'BANK_TRANSFER', 'OTHER'));

ALTER TABLE payments
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(30) USING status::text,
  ALTER COLUMN status SET DEFAULT 'PENDING_VERIFICATION',
  ADD CONSTRAINT chk_payments_status CHECK (status IN ('PENDING_VERIFICATION', 'CONFIRMED', 'REJECTED'));

-- ========== MAINTENANCE ==========
ALTER TABLE maintenance_requests
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(20) USING status::text,
  ALTER COLUMN status SET DEFAULT 'SUBMITTED',
  ADD CONSTRAINT chk_maintenance_status CHECK (status IN ('SUBMITTED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'));

-- ========== STAFF ==========
ALTER TABLE staff_assignments
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(20) USING status::text,
  ALTER COLUMN status SET DEFAULT 'ACTIVE',
  ADD CONSTRAINT chk_staff_assignments_status CHECK (status IN ('ACTIVE', 'INACTIVE'));

ALTER TABLE staff_assignment_permissions
  ALTER COLUMN permission TYPE VARCHAR(30) USING permission::text,
  ADD CONSTRAINT chk_staff_permission CHECK (permission IN ('CONFIRM_PAYMENTS', 'MANAGE_MAINTENANCE', 'VIEW_TENANTS', 'VIEW_REPORTS'));

-- ========== DOCUMENTS ==========
ALTER TABLE documents
  ALTER COLUMN owner_type TYPE VARCHAR(20) USING owner_type::text,
  ADD CONSTRAINT chk_documents_owner_type CHECK (owner_type IN ('PROPERTY', 'UNIT', 'LEASE', 'TENANT'));

ALTER TABLE documents
  ALTER COLUMN doc_type TYPE VARCHAR(30) USING doc_type::text,
  ADD CONSTRAINT chk_documents_doc_type CHECK (doc_type IN ('LEASE_CONTRACT', 'VALID_ID', 'RECEIPT', 'OTHER'));

-- ========== NOTICES ==========
-- chk_scope_targets compares scope against literals, so it is rebuilt too.
ALTER TABLE notices DROP CONSTRAINT chk_scope_targets;

ALTER TABLE notices
  ALTER COLUMN scope TYPE VARCHAR(20) USING scope::text,
  ADD CONSTRAINT chk_notices_scope CHECK (scope IN ('ALL_TENANTS', 'SPECIFIC_UNIT', 'SPECIFIC_TENANT'));

ALTER TABLE notices
  ADD CONSTRAINT chk_scope_targets CHECK (
    (scope = 'ALL_TENANTS' AND unit_id IS NULL AND tenant_id IS NULL) OR
    (scope = 'SPECIFIC_UNIT' AND unit_id IS NOT NULL AND tenant_id IS NULL) OR
    (scope = 'SPECIFIC_TENANT' AND tenant_id IS NOT NULL)
  );

-- ========== NOTIFICATIONS ==========
ALTER TABLE notifications
  ALTER COLUMN type TYPE VARCHAR(40) USING type::text,
  ADD CONSTRAINT chk_notifications_type CHECK (type IN (
    'RENT_DUE_REMINDER', 'RENT_OVERDUE', 'PAYMENT_CONFIRMED', 'PAYMENT_REJECTED',
    'MAINTENANCE_STATUS_CHANGED', 'NEW_NOTICE_POSTED', 'LEASE_EXPIRING', 'STAFF_ASSIGNED'
  ));

ALTER TABLE notifications
  ALTER COLUMN related_entity_type TYPE VARCHAR(30) USING related_entity_type::text,
  ADD CONSTRAINT chk_notifications_entity_type CHECK (related_entity_type IN (
    'BILLING_PERIOD', 'PAYMENT', 'MAINTENANCE_REQUEST', 'NOTICE', 'LEASE', 'STAFF_ASSIGNMENT'
  ));

ALTER TABLE notifications
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(20) USING status::text,
  ALTER COLUMN status SET DEFAULT 'UNREAD',
  ADD CONSTRAINT chk_notifications_status CHECK (status IN ('UNREAD', 'READ'));

-- ========== PLATFORM BILLING ==========
ALTER TABLE platform_billing_cycles
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(20) USING status::text,
  ALTER COLUMN status SET DEFAULT 'UNPAID',
  ADD CONSTRAINT chk_platform_billing_status CHECK (status IN ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'OVERDUE'));

ALTER TABLE platform_payments
  ALTER COLUMN payment_method TYPE VARCHAR(20) USING payment_method::text,
  ADD CONSTRAINT chk_platform_payments_method CHECK (payment_method IN ('CASH', 'GCASH', 'MAYA', 'BANK_TRANSFER', 'OTHER'));

ALTER TABLE platform_payments
  ALTER COLUMN status DROP DEFAULT,
  ALTER COLUMN status TYPE VARCHAR(30) USING status::text,
  ALTER COLUMN status SET DEFAULT 'PENDING_VERIFICATION',
  ADD CONSTRAINT chk_platform_payments_status CHECK (status IN ('PENDING_VERIFICATION', 'CONFIRMED', 'REJECTED'));

-- ========== DROP THE NOW-UNUSED TYPES ==========
DROP TYPE user_status;
DROP TYPE landlord_account_status;
DROP TYPE property_type;
DROP TYPE rental_mode;
DROP TYPE unit_status;
DROP TYPE bed_status;
DROP TYPE lease_status;
DROP TYPE billing_period_status;
DROP TYPE payment_method;
DROP TYPE payment_status;
DROP TYPE maintenance_status;
DROP TYPE staff_assignment_status;
DROP TYPE staff_permission;
DROP TYPE document_owner_type;
DROP TYPE document_type;
DROP TYPE notice_scope;
DROP TYPE notification_type;
DROP TYPE notification_entity_type;
DROP TYPE notification_status;
DROP TYPE platform_billing_status;
DROP TYPE platform_payment_status;
