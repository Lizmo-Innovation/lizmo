-- Shut the door Supabase leaves open.
--
-- Supabase serves every table in `public` over PostgREST at
-- https://<ref>.supabase.co/rest/v1/, and the anon key that reaches it is
-- designed to be public -- the security is meant to come from row level
-- security, which none of the 27 migrations before this one ever enabled.
--
-- Nothing in Lizmo uses PostgREST. The apps talk to Cloud Run, and Cloud Run
-- talks to Postgres over JDBC. So the anon key is not distributed anywhere and
-- the practical exposure is narrower than it sounds -- but "nobody has the key
-- yet" is not a security boundary, and every tenant's ID number, emergency
-- contact and payment history sits behind it.
--
-- RLS ON, NO POLICIES
--
-- Deliberately no policies at all. A policy would describe who may read what
-- through PostgREST, and the answer is nobody: that door should be shut, not
-- narrowed.
--
-- This does not affect the application. Postgres exempts a table's owner from
-- RLS unless FORCE ROW LEVEL SECURITY is set, and every one of these tables
-- was created by Flyway using the same credentials the app connects with --
-- so the app owns them and passes through untouched. FORCE is deliberately
-- not used: it would lock out the only legitimate caller.
-- NOT flyway_schema_history.
--
-- Enabling RLS takes an ACCESS EXCLUSIVE lock, and Flyway holds its history
-- table open in a transaction for as long as the migration is running. A loop
-- over every table in the schema therefore deadlocks against the tool running
-- it: the migration hangs, Flyway keeps the lock, and the service never
-- finishes starting. Found by running it -- the API sat at "Migrating schema
-- to version 28" and never came up.
--
-- That table holds migration names and checksums, no user data. It still ought
-- not to be world-readable, and the REVOKE below covers it -- see the note at
-- the end for the one statement that cannot be run from inside Flyway.
DO $$
DECLARE
  t text;
BEGIN
  FOR t IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> 'flyway_schema_history'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END
$$;

-- And take the grants away as well.
--
-- Belt and braces: RLS alone would return empty results, while revoking says
-- no at the permission layer before a row is ever considered. Guarded on the
-- roles existing, because they are Supabase's -- a local Postgres or a test
-- container has neither, which is exactly why this block needs the same care
-- as the one above and gets no local test to prove it.
--
-- Table by table, skipping flyway_schema_history, for the same reason: REVOKE
-- takes an ACCESS EXCLUSIVE lock too, so "ALL TABLES IN SCHEMA public" would
-- deadlock against Flyway in precisely the way the loop above was fixed to
-- avoid -- and only on Supabase, where those roles exist. It would have looked
-- fine here and hung the deploy.
DO $$
DECLARE
  r text;
  t text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    CONTINUE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r);

    FOR t IN
      SELECT tablename FROM pg_tables
      WHERE schemaname = 'public' AND tablename <> 'flyway_schema_history'
    LOOP
      EXECUTE format('REVOKE ALL ON public.%I FROM %I', t, r);
    END LOOP;

    -- Without USAGE on the schema, nothing inside it can be named at all.
    EXECUTE format('REVOKE ALL ON SCHEMA public FROM %I', r);
    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM %I', r);
  END LOOP;
END
$$;

-- TWO THINGS THIS CANNOT DO FROM INSIDE FLYWAY
--
-- 1. RLS on flyway_schema_history, for the deadlock reason above. Run this
--    once by hand in the Supabase SQL editor, when no deploy is in flight:
--
--      ALTER TABLE public.flyway_schema_history ENABLE ROW LEVEL SECURITY;
--
--    The REVOKE above already takes anon's access away, so this is closing a
--    second lock on a door that is bolted.
--
-- 2. Future tables. A migration that creates one should enable RLS on it in
--    the same breath -- nothing does that automatically, and the Supabase
--    advisory that caught this will catch the next.
