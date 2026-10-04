-- The lease comes out of the conversation now.
--
-- A lease pointed at the rental request that produced it. Requests are gone:
-- what a tenant does first is start a thread, and what a landlord does when
-- they have agreed is write the tenancy from inside it. So the lease points at
-- the thread instead, which is the same link to the same two people and now
-- also to everything they said to each other on the way.

ALTER TABLE leases ADD COLUMN inquiry_id UUID REFERENCES inquiries(id);

-- Every lease that came from a request belongs to the thread that request
-- became in V39, which is the one with the same tenant and the same property.
UPDATE leases l
   SET inquiry_id = i.id
  FROM rental_requests r
  JOIN inquiries i
    ON i.tenant_id = r.tenant_id
   AND i.property_id = r.property_id
 WHERE l.rental_request_id = r.id;

-- One *running* tenancy per thread. Not one ever: a tenant who moved out and
-- came back to the same landlord is the same conversation, and starting a
-- second thread between the same two people about the same building would
-- throw away everything they had already said to each other. Two at once is
-- the mistake, and that is what this forbids.
CREATE UNIQUE INDEX uq_leases_inquiry_active
  ON leases(inquiry_id)
  WHERE inquiry_id IS NOT NULL AND status = 'ACTIVE';

-- Still nullable, for the same reason as before: a landlord moving a boarding
-- house onto Lizmo has tenants who never asked anybody anything.
ALTER TABLE leases DROP COLUMN rental_request_id;

-- Nothing reads this table any more. Its contents became threads in V39 and
-- the lease links moved above, so what is left is a form nobody fills in.
DROP TABLE rental_requests;

-- RENTAL_REQUEST stays allowed as a notification's subject: rows raised before
-- this exist, and they are a record of something that happened. They resolve
-- to nothing now, which is what a notification about a vanished thing should
-- do -- rather than being deleted, which would edit somebody's history.
