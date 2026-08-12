-- DEV GUARD CHECKS THE CALLER, NOT THE SUBJECT — closed 2026-08-12
-- (applied live 2026-08-11 23:39 UTC via MCP; file written back the same
-- night).
--
-- zyra_dev_counterpart_complete writes answers/ratings/salams AS the other
-- party, and zyra_dev_rewind_journey DELETEs the other party's messages,
-- answers and notifications — but both only verified the CALLER is
-- @zyra.test. A seeded tester matched with a real account (e.g. the
-- Founder's own Apple/Google sign-in during device testing) could mutate or
-- destroy the real account's data. Both functions now assert EVERY party of
-- every touched match is @zyra.test.
--
-- Implemented as anchor-verified source surgery on the LIVE definitions
-- (pg_get_functiondef -> insert guard -> EXECUTE), so the rest of each body
-- cannot drift from what is deployed. If an anchor is missing the DO block
-- raises and NOTHING changes. Verified after: both live bodies contain the
-- GUARD BOTH PARTIES block.
--
-- The remaining zyra_dev_set_* functions touch only the shared match row and
-- are raised (not patched) — see the stewardship report.

DO $do$
DECLARE
  src    text;
  anchor text;
  guard  text;
BEGIN
  src := pg_get_functiondef('public.zyra_dev_counterpart_complete(uuid, text[])'::regprocedure);
  anchor := $a$  IF m.status <> 'active' THEN$a$;
  IF strpos(src, anchor) = 0 THEN
    RAISE EXCEPTION 'anchor not found in zyra_dev_counterpart_complete — aborting, nothing changed';
  END IF;
  guard := $g$  -- GUARD BOTH PARTIES (2026-08-12): this function writes as the
  -- counterpart, so the counterpart must be a seeded account too.
  IF EXISTS (SELECT 1 FROM auth.users u
              WHERE u.id IN (m.seeker_a_id, m.seeker_b_id)
                AND (u.email IS NULL OR u.email NOT LIKE '%@zyra.test')) THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of the match must be a seeded @zyra.test account.';
  END IF;
$g$;
  src := replace(src, anchor, guard || anchor);
  EXECUTE src;

  src := pg_get_functiondef('public.zyra_dev_rewind_journey(uuid)'::regprocedure);
  anchor := $a$  FOREACH v_id IN ARRAY v_ids LOOP$a$;
  IF strpos(src, anchor) = 0 THEN
    RAISE EXCEPTION 'anchor not found in zyra_dev_rewind_journey — aborting, nothing changed';
  END IF;
  guard := $g$  -- GUARD BOTH PARTIES (2026-08-12): the loop below deletes the other
  -- party's rows, so every party of every affected match must be seeded.
  IF EXISTS (SELECT 1 FROM matches mm
              JOIN auth.users ua ON ua.id = mm.seeker_a_id
              JOIN auth.users ub ON ub.id = mm.seeker_b_id
             WHERE mm.id = ANY(v_ids)
               AND (ua.email IS NULL OR ua.email NOT LIKE '%@zyra.test'
                 OR ub.email IS NULL OR ub.email NOT LIKE '%@zyra.test')) THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of every affected match must be a seeded @zyra.test account.';
  END IF;

$g$;
  src := replace(src, anchor, guard || anchor);
  EXECUTE src;
END $do$;
