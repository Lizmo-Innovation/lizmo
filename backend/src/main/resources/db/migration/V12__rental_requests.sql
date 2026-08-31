-- A tenant asking a landlord for a specific bed or whole unit.
--
-- Its own table rather than a lease in a PENDING state. Several people should
-- be able to ask about the same bed and let the landlord choose; a lease is
-- exclusive by nature, so modelling the ask as a not-yet-real lease would have
-- meant either one enquiry per bed or an exclusivity rule that lies.
CREATE TABLE rental_requests (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id    UUID NOT NULL REFERENCES users(id),

  -- Denormalised from the unit so the landlord's inbox is one indexed read
  -- rather than a join through units for every property they own.
  property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,

  unit_id      UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,

  -- Null for a whole unit. Set only when the unit is let bed by bed.
  bed_id       UUID REFERENCES beds(id) ON DELETE CASCADE,

  status       VARCHAR(20) NOT NULL DEFAULT 'PENDING',

  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- When it stopped being pending, whichever way it went. Null while it waits.
  decided_at   TIMESTAMPTZ
);

ALTER TABLE rental_requests
  ADD CONSTRAINT chk_rental_requests_status CHECK (status IN (
    'PENDING',
    'ACCEPTED',
    'DECLINED',
    -- The tenant changed their mind, or took a room elsewhere.
    'WITHDRAWN',
    -- The landlord gave the slot to somebody else. Distinct from DECLINED:
    -- nobody judged this tenant, they were simply not first.
    'SUPERSEDED'
  ));

ALTER TABLE rental_requests
  ADD CONSTRAINT chk_rental_requests_decided
    CHECK ((status = 'PENDING') = (decided_at IS NULL));

-- One live ask per tenant per slot. Tapping the button twice is a double
-- request, not two enquiries, and a landlord should never see the same person
-- asking for the same bed twice.
--
-- Two indexes because bed_id is null for a whole unit, and null is not equal to
-- itself: a single index over (tenant_id, unit_id, bed_id) would let a tenant
-- stack any number of pending requests on the same whole unit.
CREATE UNIQUE INDEX uq_rental_requests_pending_bed
  ON rental_requests(tenant_id, bed_id)
  WHERE status = 'PENDING' AND bed_id IS NOT NULL;

CREATE UNIQUE INDEX uq_rental_requests_pending_unit
  ON rental_requests(tenant_id, unit_id)
  WHERE status = 'PENDING' AND bed_id IS NULL;

-- Deliberately not unique on the slot alone. Five people asking about one bed
-- is the point: the landlord picks.
CREATE INDEX idx_rental_requests_property_status
  ON rental_requests(property_id, status);

CREATE INDEX idx_rental_requests_tenant
  ON rental_requests(tenant_id, status);
