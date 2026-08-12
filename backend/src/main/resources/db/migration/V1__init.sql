CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ========== ENUMS ==========
CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE');
CREATE TYPE property_type AS ENUM ('APARTMENT', 'BOARDING_HOUSE', 'CONDO', 'SINGLE_HOUSE');
CREATE TYPE rental_mode AS ENUM ('WHOLE_UNIT', 'BEDSPACE');
CREATE TYPE unit_status AS ENUM ('VACANT', 'PARTIALLY_OCCUPIED', 'OCCUPIED', 'MAINTENANCE');
CREATE TYPE bed_status AS ENUM ('VACANT', 'OCCUPIED', 'MAINTENANCE');
CREATE TYPE lease_status AS ENUM ('ACTIVE', 'ENDED', 'TERMINATED');
CREATE TYPE billing_period_status AS ENUM ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'OVERDUE');
CREATE TYPE payment_method AS ENUM ('CASH', 'GCASH', 'MAYA', 'BANK_TRANSFER', 'OTHER');
CREATE TYPE payment_status AS ENUM ('PENDING_VERIFICATION', 'CONFIRMED', 'REJECTED');
CREATE TYPE maintenance_status AS ENUM ('SUBMITTED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED');
CREATE TYPE staff_assignment_status AS ENUM ('ACTIVE', 'INACTIVE');
CREATE TYPE staff_permission AS ENUM ('CONFIRM_PAYMENTS', 'MANAGE_MAINTENANCE', 'VIEW_TENANTS', 'VIEW_REPORTS');
CREATE TYPE document_owner_type AS ENUM ('PROPERTY', 'UNIT', 'LEASE', 'TENANT');
CREATE TYPE document_type AS ENUM ('LEASE_CONTRACT', 'VALID_ID', 'RECEIPT', 'OTHER');
CREATE TYPE notice_scope AS ENUM ('ALL_TENANTS', 'SPECIFIC_UNIT', 'SPECIFIC_TENANT');
CREATE TYPE notification_type AS ENUM (
  'RENT_DUE_REMINDER', 'RENT_OVERDUE', 'PAYMENT_CONFIRMED', 'PAYMENT_REJECTED',
  'MAINTENANCE_STATUS_CHANGED', 'NEW_NOTICE_POSTED', 'LEASE_EXPIRING', 'STAFF_ASSIGNED'
);
CREATE TYPE notification_entity_type AS ENUM (
  'BILLING_PERIOD', 'PAYMENT', 'MAINTENANCE_REQUEST', 'NOTICE', 'LEASE', 'STAFF_ASSIGNMENT'
);
CREATE TYPE notification_status AS ENUM ('UNREAD', 'READ');
CREATE TYPE platform_billing_status AS ENUM ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'OVERDUE');
CREATE TYPE platform_payment_status AS ENUM ('PENDING_VERIFICATION', 'CONFIRMED', 'REJECTED');
CREATE TYPE landlord_account_status AS ENUM ('ACTIVE', 'LOCKED');

-- ========== USERS ==========
CREATE TABLE users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            VARCHAR(255) NOT NULL,
  email           VARCHAR(255) UNIQUE,
  phone           VARCHAR(20) UNIQUE,
  password_hash   VARCHAR(255) NOT NULL,
  status          user_status NOT NULL DEFAULT 'ACTIVE',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE TABLE tenant_profiles (
  user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE landlord_profiles (
  user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  account_status  landlord_account_status NOT NULL DEFAULT 'ACTIVE',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash      VARCHAR(255) NOT NULL UNIQUE,
  expires_at      TIMESTAMPTZ NOT NULL,
  revoked_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);

-- ========== PROPERTY / UNIT / BED ==========
CREATE TABLE properties (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  landlord_id     UUID NOT NULL REFERENCES landlord_profiles(user_id),
  name            VARCHAR(255) NOT NULL,
  address         TEXT NOT NULL,
  type            property_type NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_properties_landlord ON properties(landlord_id);

CREATE TABLE units (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  unit_number     VARCHAR(50) NOT NULL,
  floor           VARCHAR(20),
  size_sqm        NUMERIC(8,2),
  rental_mode     rental_mode NOT NULL,
  capacity        INT NOT NULL DEFAULT 1,
  status          unit_status NOT NULL DEFAULT 'VACANT',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_unit_number_per_property UNIQUE (property_id, unit_number)
);
CREATE INDEX idx_units_property ON units(property_id);

CREATE TABLE beds (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id         UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  bed_label       VARCHAR(50) NOT NULL,
  status          bed_status NOT NULL DEFAULT 'VACANT',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_bed_label_per_unit UNIQUE (unit_id, bed_label)
);
CREATE INDEX idx_beds_unit ON beds(unit_id);

-- ========== LEASE ==========
CREATE TABLE leases (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenant_profiles(user_id),
  unit_id         UUID NOT NULL REFERENCES units(id),
  bed_id          UUID REFERENCES beds(id),
  rent_amount     NUMERIC(10,2) NOT NULL,
  due_date_day    SMALLINT NOT NULL CHECK (due_date_day BETWEEN 1 AND 31),
  start_date      DATE NOT NULL,
  end_date        DATE,
  status          lease_status NOT NULL DEFAULT 'ACTIVE',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_leases_tenant ON leases(tenant_id);
CREATE INDEX idx_leases_unit ON leases(unit_id);
CREATE INDEX idx_leases_bed ON leases(bed_id);
CREATE UNIQUE INDEX uq_active_lease_per_bed ON leases(bed_id) WHERE status = 'ACTIVE' AND bed_id IS NOT NULL;

-- ========== BILLING & PAYMENTS ==========
CREATE TABLE billing_periods (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id        UUID NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  period_label    VARCHAR(50) NOT NULL,
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,
  due_date        DATE NOT NULL,
  amount_due      NUMERIC(10,2) NOT NULL,
  amount_paid     NUMERIC(10,2) NOT NULL DEFAULT 0,
  status          billing_period_status NOT NULL DEFAULT 'UNPAID',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_period_per_lease UNIQUE (lease_id, period_start)
);
CREATE INDEX idx_billing_periods_lease ON billing_periods(lease_id);
CREATE INDEX idx_billing_periods_status ON billing_periods(status);

CREATE TABLE payments (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id           UUID NOT NULL REFERENCES leases(id),
  billing_period_id  UUID NOT NULL REFERENCES billing_periods(id),
  amount_paid        NUMERIC(10,2) NOT NULL,
  payment_date       DATE NOT NULL,
  payment_method     payment_method NOT NULL,
  proof_image_url    TEXT NOT NULL,
  status             payment_status NOT NULL DEFAULT 'PENDING_VERIFICATION',
  submitted_by       UUID NOT NULL REFERENCES users(id),
  verified_by        UUID REFERENCES users(id),
  verified_at        TIMESTAMPTZ,
  remarks            TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_payments_billing_period ON payments(billing_period_id);
CREATE INDEX idx_payments_status ON payments(status);

-- ========== MAINTENANCE ==========
CREATE TABLE maintenance_requests (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id          UUID NOT NULL REFERENCES leases(id),
  unit_id           UUID NOT NULL REFERENCES units(id),
  bed_id            UUID REFERENCES beds(id),
  submitted_by      UUID NOT NULL REFERENCES users(id),
  description       TEXT NOT NULL,
  photo_url         TEXT,
  status            maintenance_status NOT NULL DEFAULT 'SUBMITTED',
  landlord_remarks  TEXT,
  submitted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at       TIMESTAMPTZ
);
CREATE INDEX idx_maintenance_lease ON maintenance_requests(lease_id);
CREATE INDEX idx_maintenance_unit ON maintenance_requests(unit_id);
CREATE INDEX idx_maintenance_status ON maintenance_requests(status);

-- ========== STAFF ==========
CREATE TABLE staff_assignments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_user_id   UUID NOT NULL REFERENCES users(id),
  property_id     UUID NOT NULL REFERENCES properties(id),
  landlord_id     UUID NOT NULL REFERENCES landlord_profiles(user_id),
  status          staff_assignment_status NOT NULL DEFAULT 'ACTIVE',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_staff_per_property UNIQUE (staff_user_id, property_id)
);
CREATE INDEX idx_staff_assignments_property ON staff_assignments(property_id);
CREATE INDEX idx_staff_assignments_staff_user ON staff_assignments(staff_user_id);

CREATE TABLE staff_assignment_permissions (
  staff_assignment_id  UUID NOT NULL REFERENCES staff_assignments(id) ON DELETE CASCADE,
  permission           staff_permission NOT NULL,
  PRIMARY KEY (staff_assignment_id, permission)
);

-- ========== DOCUMENTS ==========
CREATE TABLE documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_type      document_owner_type NOT NULL,
  owner_id        UUID NOT NULL,
  uploaded_by     UUID NOT NULL REFERENCES users(id),
  doc_type        document_type NOT NULL,
  file_url        TEXT NOT NULL,
  label           VARCHAR(255),
  uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_documents_owner ON documents(owner_type, owner_id);

-- ========== NOTICES ==========
CREATE TABLE notices (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  posted_by       UUID NOT NULL REFERENCES users(id),
  property_id     UUID NOT NULL REFERENCES properties(id),
  scope           notice_scope NOT NULL,
  unit_id         UUID REFERENCES units(id),
  tenant_id       UUID REFERENCES tenant_profiles(user_id),
  title           VARCHAR(255) NOT NULL,
  message         TEXT NOT NULL,
  attachment_url  TEXT,
  posted_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at      TIMESTAMPTZ,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
  archived_at     TIMESTAMPTZ,
  CONSTRAINT chk_scope_targets CHECK (
    (scope = 'ALL_TENANTS' AND unit_id IS NULL AND tenant_id IS NULL) OR
    (scope = 'SPECIFIC_UNIT' AND unit_id IS NOT NULL AND tenant_id IS NULL) OR
    (scope = 'SPECIFIC_TENANT' AND tenant_id IS NOT NULL)
  )
);
CREATE INDEX idx_notices_property ON notices(property_id);

CREATE TABLE notice_reads (
  notice_id       UUID NOT NULL REFERENCES notices(id) ON DELETE CASCADE,
  tenant_id       UUID NOT NULL REFERENCES tenant_profiles(user_id),
  read_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (notice_id, tenant_id)
);

-- ========== NOTIFICATIONS ==========
CREATE TABLE notifications (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_user_id     UUID NOT NULL REFERENCES users(id),
  type                  notification_type NOT NULL,
  related_entity_type   notification_entity_type,
  related_entity_id     UUID,
  title                 VARCHAR(255) NOT NULL,
  message               TEXT NOT NULL,
  status                notification_status NOT NULL DEFAULT 'UNREAD',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at               TIMESTAMPTZ
);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_user_id, status);

-- ========== PLATFORM BILLING ==========
CREATE TABLE platform_admins (
  user_id         UUID PRIMARY KEY REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE platform_billing_cycles (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  landlord_id              UUID NOT NULL REFERENCES landlord_profiles(user_id),
  billing_date             DATE NOT NULL,
  due_date                 DATE NOT NULL,
  occupied_units_count     INT NOT NULL DEFAULT 0,
  occupied_bedspaces_count INT NOT NULL DEFAULT 0,
  amount_due               NUMERIC(10,2) NOT NULL,
  amount_paid              NUMERIC(10,2) NOT NULL DEFAULT 0,
  status                   platform_billing_status NOT NULL DEFAULT 'UNPAID',
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_billing_cycle_per_landlord UNIQUE (landlord_id, billing_date)
);
CREATE INDEX idx_platform_billing_landlord ON platform_billing_cycles(landlord_id);
CREATE INDEX idx_platform_billing_status ON platform_billing_cycles(status);

CREATE TABLE platform_payments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  billing_cycle_id    UUID NOT NULL REFERENCES platform_billing_cycles(id),
  landlord_id         UUID NOT NULL REFERENCES landlord_profiles(user_id),
  amount_paid         NUMERIC(10,2) NOT NULL,
  payment_date        DATE NOT NULL,
  payment_method      payment_method NOT NULL,
  proof_image_url     TEXT NOT NULL,
  status              platform_payment_status NOT NULL DEFAULT 'PENDING_VERIFICATION',
  submitted_by        UUID NOT NULL REFERENCES users(id),
  verified_by         UUID REFERENCES platform_admins(user_id),
  verified_at         TIMESTAMPTZ,
  remarks             TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_platform_payments_cycle ON platform_payments(billing_cycle_id);
CREATE INDEX idx_platform_payments_status ON platform_payments(status);
