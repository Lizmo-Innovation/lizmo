-- A request about the place, rather than about one bed.
--
-- Scanning a code used to hand a stranger the whole room list: every unit
-- number, every bed label, and what each one costs. That is more than somebody
-- needs to ask whether there is space, and it is the landlord's business, not
-- a passer-by's. What a tenant sees now is how many beds and units are free on
-- each floor and what they cost; the room itself is chosen by the landlord
-- when they accept, which is how it is settled on the phone anyway.
--
-- So unit_id becomes optional. Requests that already name a unit keep it and
-- still accept as they did: somebody mid-conversation should not have their
-- request invalidated by this.

ALTER TABLE rental_requests ALTER COLUMN unit_id DROP NOT NULL;

-- A bed belongs to a unit, so naming one without the other is meaningless.
ALTER TABLE rental_requests
  ADD CONSTRAINT chk_rental_requests_bed_needs_unit
    CHECK (bed_id IS NULL OR unit_id IS NOT NULL);

-- One live ask per tenant per property, now that a request is about the place.
-- The two indexes below it stay for requests that name a room: both shapes are
-- live at once, and a tenant with a pending property request must not be able
-- to stack a second one.
CREATE UNIQUE INDEX uq_rental_requests_pending_property
  ON rental_requests(tenant_id, property_id)
  WHERE status = 'PENDING' AND unit_id IS NULL;
