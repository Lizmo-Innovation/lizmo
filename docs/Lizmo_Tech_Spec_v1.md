# Lizmo — Technical Specification v1

Companion document to `Lizmo_Product_Spec_v1.md`. Covers system architecture, database schema, API design, auth flow, local Docker setup, and AWS infrastructure-as-code.

---

## 1. System Architecture

```
                              ┌─────────────────────┐
                              │   Flutter Mobile     │
                              │  (Landlord/Tenant/    │
                              │      Staff app)       │
                              └──────────┬───────────┘
                                         │ HTTPS/REST + JWT
                                         ▼
                              ┌─────────────────────┐
                              │   ALB (HTTPS term.)  │
                              └──────────┬───────────┘
                                         ▼
                              ┌─────────────────────┐
                              │  ECS Fargate Service  │
                              │  Spring Boot API      │
                              │  (Java 21)             │
                              └──────┬───────┬───────┘
                                     │       │
                         ┌───────────┘       └───────────┐
                         ▼                                ▼
               ┌─────────────────┐               ┌─────────────────┐
               │  RDS PostgreSQL   │               │   S3 (uploads)    │
               │  (leases, payments,│              │  proof-of-payment, │
               │   notices, etc.)   │              │  documents, photos │
               └─────────────────┘               └─────────────────┘
```

**Components:**
- **Client:** Single Flutter codebase, role-aware UI (tenant / landlord / staff views based on active profile context)
- **API:** Spring Boot monolith (modular by domain package — not microservices; unnecessary complexity at this scale)
- **DB:** PostgreSQL (RDS in prod, containerized locally)
- **File storage:** S3 for payment proofs, documents, notice attachments, maintenance photos (LocalStack emulates this locally, per your existing Dockerized dev pattern)
- **Auth:** Stateless JWT, issued by the API, validated on every request via a Spring Security filter

---

## 2. Database Schema (PostgreSQL DDL)

```sql
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

CREATE TYPE landlord_account_status AS ENUM ('ACTIVE', 'LOCKED');

CREATE TABLE landlord_profiles (
  user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  account_status  landlord_account_status NOT NULL DEFAULT 'ACTIVE',   -- LOCKED after 7-day unpaid grace period
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

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
  capacity        INT NOT NULL DEFAULT 1,          -- relevant when rental_mode = BEDSPACE
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
  bed_id          UUID REFERENCES beds(id),          -- nullable; set only if unit.rental_mode = BEDSPACE
  rent_amount     NUMERIC(10,2) NOT NULL,
  due_date_day    SMALLINT NOT NULL CHECK (due_date_day BETWEEN 1 AND 31),  -- landlord-set day-of-month
  start_date      DATE NOT NULL,
  end_date        DATE,
  status          lease_status NOT NULL DEFAULT 'ACTIVE',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_leases_tenant ON leases(tenant_id);
CREATE INDEX idx_leases_unit ON leases(unit_id);
CREATE INDEX idx_leases_bed ON leases(bed_id);
-- Only one ACTIVE lease per bed (or per unit if WHOLE_UNIT) — enforced at application layer
-- (partial unique index alternative shown for bed-level, since bed_id is nullable):
CREATE UNIQUE INDEX uq_active_lease_per_bed ON leases(bed_id) WHERE status = 'ACTIVE' AND bed_id IS NOT NULL;

-- ========== BILLING & PAYMENTS ==========
CREATE TABLE billing_periods (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id        UUID NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  period_label    VARCHAR(50) NOT NULL,              -- e.g. "August 2026"
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
  posted_by       UUID NOT NULL REFERENCES users(id),      -- landlord or authorized staff
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

-- ========== PLATFORM BILLING (Lizmo's own revenue) ==========
CREATE TABLE platform_admins (
  user_id         UUID PRIMARY KEY REFERENCES users(id),   -- internal Lizmo staff, distinct from landlord/tenant/staff
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE platform_billing_cycles (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  landlord_id             UUID NOT NULL REFERENCES landlord_profiles(user_id),
  billing_date            DATE NOT NULL,                    -- snapshot date, e.g. 1st of the month
  due_date                DATE NOT NULL,                    -- = billing_date; 7-day grace period counts from here
  occupied_units_count    INT NOT NULL DEFAULT 0,
  occupied_bedspaces_count INT NOT NULL DEFAULT 0,
  amount_due              NUMERIC(10,2) NOT NULL,            -- = units*150 + bedspaces*50
  amount_paid             NUMERIC(10,2) NOT NULL DEFAULT 0,
  status                  platform_billing_status NOT NULL DEFAULT 'UNPAID',
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
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
  payment_method      payment_method NOT NULL,               -- reuses cash/gcash/maya/bank_transfer/other
  proof_image_url     TEXT NOT NULL,
  status              platform_payment_status NOT NULL DEFAULT 'PENDING_VERIFICATION',
  submitted_by        UUID NOT NULL REFERENCES users(id),     -- the landlord
  verified_by         UUID REFERENCES platform_admins(user_id), -- Lizmo admin, not the landlord's own staff
  verified_at         TIMESTAMPTZ,
  remarks             TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_platform_payments_cycle ON platform_payments(billing_cycle_id);
CREATE INDEX idx_platform_payments_status ON platform_payments(status);
```

**Schema notes:**
- All PKs are UUIDs (`gen_random_uuid()`, requires `pgcrypto` extension) — avoids sequential-ID enumeration and works cleanly with distributed/offline-first mobile sync later if needed.
- `leases.bed_id` nullable + partial unique index enforces "one active lease per bed" without complicating the WHOLE_UNIT case.
- `notices` scope/target consistency is enforced via a CHECK constraint, not just app logic.
- Enable required extension once per DB: `CREATE EXTENSION IF NOT EXISTS pgcrypto;`

---

## 3. API Design (REST)

Base path: `/api/v1`. All endpoints (except `/auth/*`) require a valid JWT (`Authorization: Bearer <token>`).

### 3.1 Auth
| Method | Path | Description |
|---|---|---|
| POST | `/auth/register` | Create a User (base identity) |
| POST | `/auth/login` | Returns access + refresh token |
| POST | `/auth/refresh` | Exchange refresh token for new access token |
| POST | `/auth/logout` | Invalidate refresh token |

### 3.2 Properties / Units / Beds (landlord-scoped)
| Method | Path | Description |
|---|---|---|
| GET/POST | `/properties` | List / create properties (landlord's own) |
| GET/PUT/DELETE | `/properties/{id}` | Manage a property |
| GET/POST | `/properties/{id}/units` | List / create units under a property |
| GET/PUT/DELETE | `/units/{id}` | Manage a unit |
| GET/POST | `/units/{id}/beds` | List / create beds (BEDSPACE units only) |
| GET/PUT/DELETE | `/beds/{id}` | Manage a bed |

### 3.3 Leases & Billing
| Method | Path | Description |
|---|---|---|
| GET/POST | `/leases` | List / create leases (filterable by tenant, unit, property, status) |
| GET/PUT | `/leases/{id}` | View / update / end a lease |
| GET | `/leases/{id}/billing-periods` | List billing periods for a lease |
| GET | `/leases/{id}/billing-periods/unpaid` | Unpaid/partial periods — powers the tenant payment dropdown, oldest-first |
| GET/POST | `/leases/{id}/payments` | List / submit a payment (tenant) |
| PUT | `/payments/{id}/confirm` | Landlord/staff confirms a payment |
| PUT | `/payments/{id}/reject` | Landlord/staff rejects a payment, with remarks |

### 3.4 Maintenance
| Method | Path | Description |
|---|---|---|
| GET/POST | `/maintenance-requests` | List (own, if tenant; property-scoped, if landlord/staff) / create |
| GET/PUT | `/maintenance-requests/{id}` | View / update status (landlord/staff only for status changes) |

### 3.5 Staff
| Method | Path | Description |
|---|---|---|
| GET/POST | `/properties/{id}/staff-assignments` | List / create staff assignments for a property |
| PUT/DELETE | `/staff-assignments/{id}` | Update permissions / deactivate |
| GET | `/me/staff-assignments` | Staff user views their own assignments across landlords |

### 3.6 Documents
| Method | Path | Description |
|---|---|---|
| POST | `/documents` | Upload (multipart), with `owner_type` + `owner_id` |
| GET | `/documents?owner_type=&owner_id=` | List documents for an owner |
| DELETE | `/documents/{id}` | Remove a document |

### 3.7 Notices
| Method | Path | Description |
|---|---|---|
| GET/POST | `/properties/{id}/notices` | List / post notices for a property |
| PUT | `/notices/{id}/archive` | Manually archive |
| GET | `/notices/{id}/reads` | Landlord: read-receipt list |
| POST | `/notices/{id}/read` | Tenant: mark as read (auto-called on view) |
| GET | `/me/notices` | Tenant's active notice feed (dynamic ALL_TENANTS evaluation) |

### 3.8 Notifications
| Method | Path | Description |
|---|---|---|
| GET | `/me/notifications` | List own notifications |
| PUT | `/notifications/{id}/read` | Mark as read |

### 3.9 Platform Billing (Lizmo revenue — landlord-facing + internal admin)
| Method | Path | Description |
|---|---|---|
| GET | `/me/billing-cycles` | Landlord: list their own platform invoices |
| GET | `/billing-cycles/{id}` | View one invoice (occupied slot counts, amount due) |
| GET/POST | `/billing-cycles/{id}/payments` | List / submit a platform payment (landlord uploads proof) |
| PUT | `/admin/platform-payments/{id}/confirm` | **Internal admin only** — confirm a platform payment |
| PUT | `/admin/platform-payments/{id}/reject` | **Internal admin only** — reject with remarks |
| GET | `/admin/billing-cycles?status=` | **Internal admin only** — view all landlords' invoices, e.g. to chase overdue accounts |

`/admin/*` routes require the requesting user to have a `platform_admins` record — a separate authorization layer from the landlord/tenant/staff checks described in Section 4, gated at the Spring Security filter level by role rather than resource ownership.

### 3.10 Reporting (landlord/staff, permission-gated)
| Method | Path | Description |
|---|---|---|
| GET | `/properties/{id}/reports/occupancy` | Unit/bed occupancy |
| GET | `/properties/{id}/reports/rent-roll?period=` | Rent roll for a given month |
| GET | `/properties/{id}/reports/income-summary?from=&to=` | Confirmed income totals |
| GET | `/properties/{id}/reports/overdue-tenants` | Overdue billing periods |
| GET | `/properties/{id}/reports/maintenance-summary` | Open vs resolved counts |

---

## 4. Auth & Multi-Role Access

Since a single `User` can simultaneously be a tenant, a landlord, and staff on multiple properties, the JWT and authorization model need to reflect **capabilities**, not a single fixed role.

**JWT payload (access token):**
```json
{
  "sub": "user-uuid",
  "profiles": ["TENANT", "LANDLORD"],
  "iat": 1234567890,
  "exp": 1234571490
}
```

- `profiles` reflects which profile records exist for the user (`TenantProfile`, `LandlordProfile`) — **not** staff assignments, since those are property-specific and too granular/volatile for a token claim.
- Staff permissions are **not embedded in the JWT** — they're checked server-side per request against `staff_assignments` + `staff_assignment_permissions` for the specific `property_id` in the request path. This avoids stale-permission tokens (e.g., landlord revokes access, but staff's token is still valid for its TTL).

**Authorization layers (Spring Security):**
1. **Authentication filter** — validates JWT signature/expiry, loads `User`.
2. **Ownership checks** — e.g., a landlord can only act on their own `Property`/`Unit`/`Lease` (`landlord_id` match).
3. **Staff permission checks** — for landlord-owned-resource actions performed by a staff user, verify an `ACTIVE` `StaffAssignment` exists for that `property_id` with the required `staff_permission`.
4. **Tenant self-scope checks** — a tenant can only view/act on their own `Lease`, `Payment`, `MaintenanceRequest`, `Notification` records.
5. **Landlord account-lock check** — for any landlord-management write action (lease create/edit, payment confirmation, notice posting, staff management, etc.) performed by the landlord themself *or* their staff, the filter checks `landlord_profiles.account_status`. If `LOCKED`, the request is rejected with `403` and a specific error code (`ACCOUNT_LOCKED_UNPAID_INVOICE`) so the client can route the user to the outstanding `PlatformBillingCycle` for payment. This check is skipped for tenant-scoped requests (layer 4), since tenants remain unaffected by their landlord's platform account status.

**Token strategy:** short-lived access token (~1 hour) + longer-lived refresh token (~30 days), refresh tokens stored server-side (hashed) to allow revocation on logout/staff deactivation.

---

## 5. Local Development — Docker

**`docker-compose.yml`**
```yaml
version: "3.9"
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: lizmo
      POSTGRES_USER: lizmo
      POSTGRES_PASSWORD: lizmo_dev
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  localstack:
    image: localstack/localstack:3
    environment:
      SERVICES: s3
      DEFAULT_REGION: ap-southeast-1
    ports:
      - "4566:4566"
    volumes:
      - localstack_data:/var/lib/localstack

  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      SPRING_PROFILES_ACTIVE: local
      DB_URL: jdbc:postgresql://postgres:5432/lizmo
      DB_USER: lizmo
      DB_PASSWORD: lizmo_dev
      AWS_S3_ENDPOINT: http://localstack:4566
      AWS_REGION: ap-southeast-1
      JWT_SECRET: dev-only-secret-change-me
    depends_on:
      - postgres
      - localstack
    ports:
      - "8080:8080"

volumes:
  pgdata:
  localstack_data:
```

**`backend/Dockerfile`**
```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY . .
RUN ./gradlew bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

A local `init` script creates the S3 bucket in LocalStack on startup (`awslocal s3 mb s3://lizmo-uploads-local`), matching your existing LocalStack pattern.

---

## 6. AWS Infrastructure as Code (CloudFormation)

**Stack breakdown** (nested stacks, deployed via a root template or `aws cloudformation deploy` per stack):

1. **`network.yaml`** — VPC, public + private subnets (2 AZs), NAT gateway, security groups
2. **`data.yaml`** — RDS PostgreSQL (Multi-AZ optional, start Single-AZ for cost), S3 bucket for uploads, Secrets Manager entries for DB credentials
3. **`compute.yaml`** — ECS Fargate cluster, task definition (Spring Boot container from ECR), ALB + target group + HTTPS listener (ACM cert), auto-scaling policy
4. **`iam.yaml`** — Task execution role, task role (S3 read/write scoped to the uploads bucket, Secrets Manager read)

**Key resource sketch — `data.yaml` (excerpt):**
```yaml
Resources:
  LizmoDB:
    Type: AWS::RDS::DBInstance
    Properties:
      Engine: postgres
      EngineVersion: "16"
      DBInstanceClass: db.t4g.micro          # right-sized for MVP scale
      AllocatedStorage: 20
      MasterUsername: lizmo
      MasterUserPassword: !Sub "{{resolve:secretsmanager:${DBSecret}:SecretString:password}}"
      VPCSecurityGroups: [!Ref DBSecurityGroup]
      DBSubnetGroupName: !Ref DBSubnetGroup
      PubliclyAccessible: false
      BackupRetentionPeriod: 7

  DBSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      GenerateSecretString:
        SecretStringTemplate: '{"username":"lizmo"}'
        GenerateStringKey: password
        PasswordLength: 24
        ExcludeCharacters: '"@/\'

  UploadsBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub "lizmo-uploads-${AWS::AccountId}"
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
```

**Key resource sketch — `compute.yaml` (excerpt):**
```yaml
Resources:
  LizmoCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: lizmo-cluster

  LizmoTaskDef:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: lizmo-api
      Cpu: "512"
      Memory: "1024"
      NetworkMode: awsvpc
      RequiresCompatibilities: [FARGATE]
      ExecutionRoleArn: !Ref TaskExecutionRole
      TaskRoleArn: !Ref TaskRole
      ContainerDefinitions:
        - Name: lizmo-api
          Image: !Sub "${ECRRepoUri}:latest"
          PortMappings: [{ ContainerPort: 8080 }]
          Environment:
            - Name: SPRING_PROFILES_ACTIVE
              Value: prod
          Secrets:
            - Name: DB_PASSWORD
              ValueFrom: !Ref DBSecret
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: /ecs/lizmo-api
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: lizmo

  LizmoService:
    Type: AWS::ECS::Service
    Properties:
      Cluster: !Ref LizmoCluster
      TaskDefinition: !Ref LizmoTaskDef
      LaunchType: FARGATE
      DesiredCount: 1                       # scale later as tenant base grows
      NetworkConfiguration:
        AwsvpcConfiguration:
          Subnets: !Ref PrivateSubnetIds
          SecurityGroups: [!Ref ServiceSecurityGroup]
      LoadBalancers:
        - ContainerName: lizmo-api
          ContainerPort: 8080
          TargetGroupArn: !Ref TargetGroup
```

**Deploy workflow:**
1. Build Docker image → push to ECR
2. `aws cloudformation deploy` for `network` → `data` → `iam` → `compute` (in dependency order, or via a root stack with nested `AWS::CloudFormation::Stack` resources)
3. Flyway/Liquibase runs schema migrations against RDS on app startup or as a separate CI step (recommend **Flyway**, given the DDL above maps cleanly to versioned migration files)

**Cost-conscious defaults for MVP scale:** `db.t4g.micro` RDS, single Fargate task (0.5 vCPU / 1GB), no Multi-AZ, no NAT gateway redundancy across AZs — all upgradeable later without architecture changes as usage grows.

---

## 7. Non-Functional Notes

- **Migrations:** Flyway, versioned `V1__init.sql`, `V2__...` etc., run automatically on API startup in each environment.
- **File uploads:** client uploads directly to S3 via a pre-signed URL issued by the API (`POST /documents/presign`) rather than proxying binary through the Spring Boot app — reduces backend load and simplifies the Fargate task sizing.
- **Time zone:** all `TIMESTAMPTZ` stored in UTC; `due_date`/period dates stored as `DATE` (no TZ ambiguity) since these are calendar-day concepts (rent due "on the 5th"), not instants.
- **Soft state, not hard delete:** entities like `Property`, `Unit`, `Lease` should generally be deactivated/status-flagged rather than hard-deleted, to preserve billing/audit history.
- **Platform billing snapshot job:** a scheduled task (Spring `@Scheduled`, or an EventBridge-triggered Lambda/ECS task in prod) runs on the fixed monthly billing date. For each landlord, it counts `ACTIVE` leases as of that date — split into whole-unit vs. bedspace — and creates one `platform_billing_cycles` row with `amount_due = occupied_units_count * 150 + occupied_bedspaces_count * 50` and `due_date = billing_date`. This is a separate concern from tenant `BillingPeriod` generation (Section 2.3 of the product spec), which runs per-lease on its own cycle.
- **Platform billing enforcement job:** a second scheduled task (daily) sweeps `platform_billing_cycles` where `status IN ('UNPAID', 'PARTIALLY_PAID')`:
  - On the day `due_date` passes → flip cycle `status` to `OVERDUE` and fire a `Notification` (warning) to the landlord.
  - If still unpaid **7 days after `due_date`** → set `landlord_profiles.account_status = LOCKED` for that landlord.
  - When an admin later confirms a `PlatformPayment` that brings all of a landlord's overdue cycles to `PAID`, the confirmation handler flips `account_status` back to `ACTIVE` in the same transaction.

---

*Document version 1 — companion to Lizmo_Product_Spec_v1.md, August 2026.*
