# Lizmo — Product Spec v1

**Tagline:** Rental management for individual Philippine landlords — whole units and bedspaces, made simple.

---

## 1. Overview

Lizmo is a rental management app built for **individual Philippine landlords** managing a small number of properties — a segment underserved by enterprise-grade tools like Buildium or AppFolio, which are priced and built for large property management companies.

**Core differentiators:**
- Native support for **bedspace/shared-room rentals** (common in PH boarding houses), not just whole-unit leases
- **Manual proof-of-payment workflow** (GCash/Maya screenshot + landlord verification) instead of requiring a payment gateway integration
- **Per-property staff assignment** with granular permissions — supports the common PH pattern of one caretaker managing multiple landlords' properties
- Simple, mobile-first, in-app notifications (no SMS/Viber dependency for MVP)

**Primary users:**
- **Landlord** — owns properties, manages units/beds, tenants, staff, and finances
- **Tenant** — rents a whole unit or a bedspace, submits payments and maintenance requests
- **Staff** — assigned by a landlord to a specific property with configurable permissions (e.g., caretaker, collector)

A single person can hold multiple roles simultaneously (e.g., a tenant who is also staff for a different landlord's property).

---

## 2. Domain Model

### 2.1 Property & Unit Hierarchy

```
Property
 ├─ id, name, address, type (apartment / boarding house / condo / single house)
 ├─ owner: LandlordProfile
 └─ Units[]
     ├─ id, unit_number, floor, size_sqm, status
     ├─ rental_mode: WHOLE_UNIT | BEDSPACE
     ├─ capacity (max occupants, relevant for BEDSPACE)
     └─ Beds[]                          ← only populated if BEDSPACE
         ├─ id, bed_label (e.g. "Bed 1", "Upper Bunk A")
         └─ status: VACANT | OCCUPIED | MAINTENANCE
```

**Notes:**
- A property can have one unit (single-house rental) or many (apartment building, boarding house).
- Each unit's rent differs independently even within the same property.
- Unit occupancy is a **derived value**: `occupied_beds / capacity` for BEDSPACE units, or simple vacant/occupied for WHOLE_UNIT.
- Bed is a first-class entity (not just a lease label) because it has its own lifecycle (e.g., can be marked under maintenance independent of tenancy) and retains occupancy history across tenant turnover.

### 2.2 Lease

```
Lease
 ├─ id, tenant_id, unit_id
 ├─ bed_id (nullable — only set if rental_mode = BEDSPACE)
 ├─ rent_amount (per-bed rent if BEDSPACE, per-unit rent if WHOLE_UNIT)
 ├─ due_date (day-of-month, landlord-set — independent per lease, not derived from move-in date)
 ├─ start_date, end_date
 └─ status: ACTIVE | ENDED | TERMINATED
```

**Notes:**
- One unit can have multiple concurrent leases if BEDSPACE (one per bed).
- `due_date` is fully controlled by the landlord at lease creation — not auto-derived from move-in date, and can be standardized across all beds in a unit regardless of when each tenant moved in.
- A tenant's account persists across leases — re-renting (same or different property) attaches a new Lease to the same existing Tenant record rather than creating a duplicate.

### 2.3 Billing & Payments

```
BillingPeriod
 ├─ id, lease_id
 ├─ period_label (e.g. "August 2026")
 ├─ period_start, period_end
 ├─ due_date (from lease's due_date, rolled forward each cycle)
 ├─ amount_due
 ├─ amount_paid (sum of confirmed payments applied to this period)
 └─ status: UNPAID | PARTIALLY_PAID | PAID | OVERDUE

Payment
 ├─ id, lease_id, billing_period_id
 ├─ amount_paid, payment_date
 ├─ payment_method (cash | gcash | maya | bank_transfer | other) — tenant-declared
 ├─ proof_image_url (uploaded screenshot/photo)
 ├─ status: PENDING_VERIFICATION | CONFIRMED | REJECTED
 ├─ submitted_by (tenant_id)
 ├─ verified_by (landlord_id or staff_user_id, nullable until reviewed)
 ├─ verified_at
 └─ remarks (landlord notes, e.g. rejection reason or short-payment note)
```

**Flow:**
1. `BillingPeriod` records are generated per lease per cycle (on lease creation, then rolling forward), independent of whether payment has occurred — this allows overdue tracking even with zero payments submitted.
2. Tenant submits a `Payment` against a specific `BillingPeriod`, attaching proof of payment (no payment gateway integration in MVP).
3. **Period selection dropdown** (tenant-facing): shows only `UNPAID` / `PARTIALLY_PAID` periods for that lease, sorted oldest → newest, with the **oldest overdue period pre-selected** by default (tenant can override to pay a different period).
4. Landlord (or authorized staff) reviews the payment → **Confirm** (applies `amount_paid` to the `BillingPeriod`, updates its status) or **Reject** (with remarks; tenant resubmits).
5. Multiple `Payment` records can apply to one `BillingPeriod`, supporting partial payments.

**Deferred:** Late fee logic (auto-calculated vs. manually added) — parked for a future iteration.

### 2.4 Maintenance Requests

```
MaintenanceRequest
 ├─ id
 ├─ lease_id            ← anchors to the submitting tenant's active lease
 ├─ unit_id              ← derived from the lease
 ├─ bed_id                ← nullable, only if reporter is on a BEDSPACE lease
 ├─ submitted_by (tenant_id)
 ├─ description (plain text — no categories, priorities, or areas)
 ├─ photo_url (optional)
 ├─ status: SUBMITTED | IN_PROGRESS | RESOLVED | CLOSED
 ├─ submitted_at, updated_at, resolved_at
 └─ landlord_remarks (optional, added when status changes)
```

**Notes:**
- Available to **all tenants**, regardless of WHOLE_UNIT or BEDSPACE rental mode.
- Deliberately simple: no category taxonomy, no priority levels, no vendor assignment, no cost tracking — tenant just describes the issue in plain text.
- Tenant has read access to their own submitted requests and sees status updates in real time.

### 2.5 Users, Auth & Staff

```
User (base identity)
 ├─ id, name, email, phone, password_hash
 └─ status: ACTIVE | INACTIVE

TenantProfile
 └─ user_id → Leases[]

LandlordProfile
 └─ user_id → Properties[]

StaffAssignment
 ├─ id
 ├─ staff_user_id       ← the person being assigned (can simultaneously be a tenant elsewhere)
 ├─ property_id           ← ONE property per assignment
 ├─ landlord_id            ← the landlord who owns that property
 ├─ permissions[]           ← e.g. CONFIRM_PAYMENTS, MANAGE_MAINTENANCE, VIEW_TENANTS, VIEW_REPORTS
 └─ status: ACTIVE | INACTIVE
```

**Notes:**
- Roles are **non-exclusive** — a single User can simultaneously be a tenant, a landlord, and/or staff for one or more other landlords.
- Staff assignment is **scoped to one property at a time**; assigning the same staff member to multiple properties creates multiple `StaffAssignment` records, each with independently configured permissions.
- Flow: Landlord selects a Property → "Manage Staff" → assigns a User → configures permissions for that specific property.
- Permission keys (MVP): `CONFIRM_PAYMENTS`, `MANAGE_MAINTENANCE`, `VIEW_TENANTS`, `VIEW_REPORTS`. (`MANAGE_LEASES` excluded from staff scope for MVP — higher trust, landlord-only.)

### 2.6 Documents

```
Document
 ├─ id
 ├─ owner_type: PROPERTY | UNIT | LEASE | TENANT
 ├─ owner_id
 ├─ uploaded_by (user_id)
 ├─ doc_type: LEASE_CONTRACT | VALID_ID | RECEIPT | OTHER
 ├─ file_url
 ├─ label
 └─ uploaded_at
```

**Notes:**
- Pure upload slot — no in-app contract generation/templating for MVP. Landlord or tenant uploads whatever supplementary file is needed (signed contract scan, valid ID, receipt, etc.) and attaches it to the relevant Property/Unit/Lease/Tenant.

### 2.7 Notices & Announcements

```
Notice
 ├─ id, landlord_id (or staff_user_id, if permitted), property_id
 ├─ scope: ALL_TENANTS | SPECIFIC_UNIT | SPECIFIC_TENANT
 ├─ unit_id (nullable), tenant_id (nullable)
 ├─ title, message
 ├─ attachment_url (nullable — optional single image/document)
 ├─ posted_at
 ├─ expires_at (nullable — landlord-set, hides from active feed after this date)
 ├─ is_archived (boolean, default false — landlord can manually archive anytime)
 └─ archived_at (nullable)

NoticeRead
 ├─ notice_id, tenant_id, read_at
```

**Notes:**
- `ALL_TENANTS` scope is **dynamically evaluated**, not a snapshot — a tenant added after posting will still see the notice and appear as "unread" in landlord read receipts, as long as it hasn't expired/archived.
- A notice is **active** (visible in tenant feed) if `is_archived = false` AND (`expires_at` is null OR in the future).
- Landlord can see read receipts: who has/hasn't viewed a given notice.
- Single attachment per notice for MVP (multi-attachment deferred).

### 2.8 Notifications

```
Notification
 ├─ id
 ├─ recipient_user_id
 ├─ type: RENT_DUE_REMINDER | RENT_OVERDUE | PAYMENT_CONFIRMED | PAYMENT_REJECTED |
 │         MAINTENANCE_STATUS_CHANGED | NEW_NOTICE_POSTED | LEASE_EXPIRING | STAFF_ASSIGNED
 ├─ related_entity_type (BILLING_PERIOD | PAYMENT | MAINTENANCE_REQUEST | NOTICE | LEASE | STAFF_ASSIGNMENT)
 ├─ related_entity_id
 ├─ title, message
 ├─ status: UNREAD | READ
 ├─ created_at, read_at
```

**Notes:**
- **In-app only for MVP** — no SMS/Viber gateway integration. Schema leaves room to add a `channel` field later without breaking changes.
- Event-triggered: billing period approaching/passing due date, payment confirmed/rejected, maintenance status change, new notice posted, lease nearing expiry, staff assignment created.

### 2.9 Reporting & Dashboard

No new entities — all derived via aggregation queries over existing data:

- **Occupancy** — units/beds occupied vs. vacant, per property
- **Rent roll** — all BillingPeriods for a given month across all leases, with status
- **Income summary** — confirmed payments total, by property, by month
- **Overdue tenants** — leases with unpaid/overdue BillingPeriods
- **Maintenance summary** — open vs. resolved requests, per property

MVP uses **live queries** (no caching/materialization) — appropriate given the target scale of a handful of units per landlord.

---

## 3. Revenue Model

Lizmo charges landlords **per occupied slot**, not a flat subscription — small landlords pay little, boarding-house operators with many bedspaces pay more, and vacant inventory costs nothing.

**Pricing:**
| Slot type | Rate |
|---|---|
| Occupied bedspace (bed with an ACTIVE lease) | ₱50/month |
| Occupied whole unit (unit with an ACTIVE lease, WHOLE_UNIT mode) | ₱150/month |

- **No free tier** — billing starts from the first occupied slot.
- **Flat rate, no volume discount** — pricing stays simple and predictable as a landlord scales up.
- Vacant units/beds are never billed.

**Billing cycle:**
- Calculated via a **monthly snapshot**, not daily proration — on a fixed billing date (e.g., the 1st of each month), the system counts each landlord's currently occupied slots (active leases as of that date) and generates one invoice.
- A slot that becomes occupied mid-month is picked up on the *next* billing snapshot, not charged pro-rata for the partial month — keeps the model simple and easy for landlords to understand ("what's occupied on the 1st is what you're billed for").

**Payment collection:**
- Landlord pays Lizmo using the **same manual proof-of-payment pattern** used for tenant rent — pay via GCash/Maya/bank transfer, upload proof, Lizmo (platform admin, not the landlord's own staff) reviews and confirms. No payment gateway integration for MVP, consistent with the rest of the system.

**Non-payment policy:**
- Each `PlatformBillingCycle` has a **due date** (set to the billing/snapshot date — payment is due upon invoicing).
- A **7-day grace period** follows the due date. A **warning notification** is sent to the landlord as soon as the invoice becomes overdue (start of the grace period), prompting payment before lockout.
- If payment isn't confirmed by the end of the 7-day grace period, the landlord's account is **locked out** — they (and any staff assigned under them) lose access to landlord-side management functions (creating/editing leases, confirming tenant payments, posting notices, managing staff, etc.) until the outstanding invoice is paid and confirmed.
- **Tenants are not locked out** — a tenant's ability to view their lease, submit rent payments, and submit maintenance requests continues regardless of their landlord's platform account status, since that's independent of the landlord–Lizmo relationship.
- Lockout lifts automatically once an admin confirms a payment that brings the overdue cycle(s) to `PAID`.

**New entities this implies** (to be added to the tech spec / DB schema):

```
PlatformBillingCycle
 ├─ id, landlord_id
 ├─ billing_date (snapshot date, e.g. 1st of the month)
 ├─ due_date (= billing_date; grace period counts from here)
 ├─ occupied_units_count, occupied_bedspaces_count
 ├─ amount_due   (= occupied_units_count × 150 + occupied_bedspaces_count × 50)
 ├─ amount_paid
 └─ status: UNPAID | PARTIALLY_PAID | PAID | OVERDUE

PlatformPayment
 ├─ id, billing_cycle_id, landlord_id
 ├─ amount_paid, payment_date, payment_method
 ├─ proof_image_url
 ├─ status: PENDING_VERIFICATION | CONFIRMED | REJECTED
 ├─ submitted_by (landlord's user_id)
 ├─ verified_by (Lizmo platform admin user_id — a new internal role, distinct from landlord/tenant/staff)
 ├─ verified_at
 └─ remarks

LandlordProfile (updated)
 └─ account_status: ACTIVE | LOCKED     ← flips to LOCKED after 7-day grace period expires unpaid
```

---

## 4. Tech Stack

| Layer | Choice |
|---|---|
| Mobile app (Landlord + Tenant) | Flutter |
| Backend | Spring Boot / Java 21 |
| Database | PostgreSQL |
| Auth | JWT-based, role-aware (User can hold multiple simultaneous profiles) |

---

## 5. MVP Scope Summary

**In scope:**
- Property → Unit → Bed → Lease management (whole-unit and bedspace)
- Manual proof-of-payment workflow with per-period tracking
- Plain-text maintenance requests
- Multi-role users (tenant/landlord/staff can overlap)
- Per-property staff assignment with configurable permissions
- Document uploads (no generation)
- Notices with dynamic audience, expiry/archiving, single attachment, read receipts
- In-app notifications
- Landlord reporting/dashboard (occupancy, rent roll, income, overdue, maintenance)
- Per-slot platform billing (₱50/bedspace, ₱150/unit, monthly snapshot, manual proof-of-payment to Lizmo)

**Explicitly deferred:**
- Late fee auto-calculation
- Payment gateway integration (GCash/Maya API)
- SMS/Viber notification channel
- Lease contract template generation
- Multi-attachment notices
- Vendor management for maintenance

---

*Document version 1 — consolidated from product discovery session, August 2026.*
