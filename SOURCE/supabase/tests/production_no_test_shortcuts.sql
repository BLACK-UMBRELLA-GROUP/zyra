-- Queue 110. Run after applying the reviewed baseline to a disposable database.
-- App-owned objects live in public and private. Supabase platform objects
-- and extension members are outside the production baseline.
DO $check$
DECLARE
  violations text;
BEGIN
  WITH application_tables AS (
    SELECT n.nspname, c.relname, c.relkind, c.relrowsecurity
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'private')
      AND c.relkind IN ('r', 'p', 'v', 'm')
      AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_depend AS d
        WHERE d.classid = 'pg_catalog.pg_class'::regclass
          AND d.objid = c.oid AND d.deptype = 'e'
      )
  ), application_routines AS (
    SELECT n.nspname, p.proname, pg_catalog.pg_get_functiondef(p.oid) AS definition
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public', 'private')
      AND p.prokind IN ('f', 'p')
      AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_depend AS d
        WHERE d.classid = 'pg_catalog.pg_proc'::regclass
          AND d.objid = p.oid AND d.deptype = 'e'
      )
  ), findings AS (
    SELECT format('disallowed table %I.%I', nspname, relname) AS problem
    FROM application_tables WHERE relname ~* '(dev|probe|seed|guard_results)'
    UNION ALL
    SELECT format('row-level security disabled on %I.%I', nspname, relname)
    FROM application_tables
    WHERE nspname = 'public' AND relkind IN ('r', 'p') AND NOT relrowsecurity
    UNION ALL
    SELECT format('test-data marker remains on %s', attrelid::regclass)
    FROM pg_catalog.pg_attribute
    WHERE attrelid IN ('public.onboarding_answers'::regclass, 'public.seeker_details'::regclass)
      AND attname = 'is_synthetic' AND NOT attisdropped
    UNION ALL
    SELECT format('disallowed routine %I.%I', nspname, proname)
    FROM application_routines
    WHERE proname ~* '(dev|probe|seed|guard_results|^mock_|^zyra_debug_)'
      OR definition ILIKE '%@zyra.test%'
  )
  SELECT string_agg(problem, E'\n' ORDER BY problem) INTO violations FROM findings;

  IF violations IS NOT NULL THEN
    RAISE EXCEPTION 'Production baseline violates test-only and access rules'
      USING DETAIL = violations;
  END IF;
END;
$check$;
