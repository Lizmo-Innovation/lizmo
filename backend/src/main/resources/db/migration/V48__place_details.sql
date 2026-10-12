-- What a tenant wants to know before asking: who can rent, the house rules,
-- the money up front, and what comes with the place.
--
-- Its own table rather than more columns on properties: none of it is the
-- property's identity, a landlord fills it in separately, and every part is
-- optional -- a row of nulls means "not said", which the apps show as
-- nothing rather than as "no rules".

CREATE TABLE place_details (
  property_id     UUID PRIMARY KEY REFERENCES properties(id) ON DELETE CASCADE,
  who_can_rent    VARCHAR(10),
  curfew          VARCHAR(5),
  visitors        VARCHAR(10),
  cooking         BOOLEAN,
  pets            BOOLEAN,
  smoking         BOOLEAN,
  other_rules     TEXT,
  -- In months, because rent differs from room to room; the apps turn them
  -- into pesos for whichever room is being looked at.
  deposit_months  SMALLINT,
  advance_months  SMALLINT,
  amenities       VARCHAR(200) NOT NULL DEFAULT '',
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_place_who CHECK (who_can_rent IN ('ANYONE', 'WOMEN', 'MEN')),
  CONSTRAINT chk_place_visitors CHECK (visitors IN ('ALLOWED', 'DAYTIME', 'NONE')),
  CONSTRAINT chk_place_curfew CHECK (curfew ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
  CONSTRAINT chk_place_deposit CHECK (deposit_months BETWEEN 0 AND 6),
  CONSTRAINT chk_place_advance CHECK (advance_months BETWEEN 0 AND 6)
);

-- A vacant room that is not ready yet -- being repainted, say -- and from
-- when it is. Null, or a day gone by, is ready now.
ALTER TABLE units ADD COLUMN ready_from DATE;

-- Like every table: nothing reachable through Supabase's own API roles.
DO $$
DECLARE
  r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);
    EXECUTE format('REVOKE ALL ON public.place_details FROM %I', r);
  END LOOP;
END
$$;

ALTER TABLE place_details ENABLE ROW LEVEL SECURITY;
