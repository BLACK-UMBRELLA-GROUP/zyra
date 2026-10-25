-- OA-ZYRA-198 RECONSTRUCTED PROBE-SCORE REPLAY BRIDGE
-- REPLAY-ONLY GOVERNED ARTIFACT — NOT RETAINED PRODUCTION HISTORY — DO NOT APPLY
--
-- Founder authority: direct instruction to complete every safe TestFlight
-- prerequisite, 2026-09-11. A destructive full replay still requires a new,
-- exact, single-use Founder GO naming this artifact's final SHA-256.
--
-- Intended future use: copy this exact file into an isolated scratch migration
-- set at artificial ordering version 20260811233812, after unchanged
-- 20260811233755 and before unchanged 20260811233813. Keep it outside
-- SOURCE/supabase/migrations and never apply it to the production project.
--
-- Provenance boundary: no original CREATE statement or migration-history row
-- survives. Read-only production catalog inspection on 2026-09-11 established
-- the exact structural contract: a permanent ordinary table owned by postgres;
-- nullable viewer text, rows_returned integer and score numeric columns in that
-- order; no defaults, identity/generated columns, constraints, indexes,
-- policies, triggers, rules or comments. The retained 2026-08-12 stewardship
-- record proves it was a two-row, RLS-off scoring-analysis scratch table before
-- historical migration 20260811233813 enabled RLS and revoked client grants.
-- This seedless bridge reconstructs schema only and deliberately copies no
-- live scratch rows.

BEGIN;

DO $oa198_probe_preflight$
DECLARE
  v_frontier_count integer;
  v_bridge_count integer;
  v_unexpected_versions text;
BEGIN
  IF pg_catalog.to_regclass(
       'supabase_migrations.schema_migrations'
     ) IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 probe bridge refused: migration history is unavailable';
  END IF;

  IF CURRENT_USER <> 'postgres' THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 probe bridge refused: execution owner is not postgres';
  END IF;

  IF pg_catalog.to_regclass('public.zyra_probe_score') IS NOT NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 probe bridge refused: relation already exists';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_frontier_count
    FROM supabase_migrations.schema_migrations
   WHERE version::text = '20260811233755';

  IF v_frontier_count <> 1 THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 probe bridge refused: exact 20260811233755 frontier is absent';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_bridge_count
    FROM supabase_migrations.schema_migrations
   WHERE version::text = '20260811233812';

  IF v_bridge_count <> 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 probe bridge refused: 20260811233812 is already recorded';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM supabase_migrations.schema_migrations
     WHERE version::text >= '20260811233813'
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 probe bridge refused: 20260811233813 or later already ran';
  END IF;

  SELECT pg_catalog.string_agg(
           version::text,
           ', ' ORDER BY version::text
         )
    INTO v_unexpected_versions
    FROM supabase_migrations.schema_migrations
   WHERE version::text > '20260811233755'
     AND version::text < '20260811233813';

  IF v_unexpected_versions IS NOT NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 probe bridge refused: unexpected frontier version(s): '
                || v_unexpected_versions;
  END IF;
END
$oa198_probe_preflight$;

CREATE TABLE public.zyra_probe_score (
  viewer text,
  rows_returned integer,
  score numeric
);

DO $oa198_probe_postcondition$
DECLARE
  v_relation oid := pg_catalog.to_regclass('public.zyra_probe_score');
  v_column_contract text;
  v_owner text;
  v_relkind "char";
  v_relpersistence "char";
  v_relreplident "char";
  v_rls boolean;
  v_force_rls boolean;
  v_has_index boolean;
  v_has_rules boolean;
  v_has_triggers boolean;
  v_is_partition boolean;
BEGIN
  IF v_relation IS NULL THEN
    RAISE EXCEPTION 'OA-ZYRA-198 probe bridge postcondition: relation absent';
  END IF;

  SELECT pg_catalog.string_agg(
           attribute.attnum::text || ':' ||
           attribute.attname || ':' ||
           pg_catalog.format_type(attribute.atttypid, attribute.atttypmod) || ':' ||
           attribute.attnotnull::text || ':' ||
           attribute.attidentity::text || ':' ||
           attribute.attgenerated::text || ':' ||
           COALESCE(
             pg_catalog.pg_get_expr(default_row.adbin, default_row.adrelid),
             '<null>'
           ),
           '|' ORDER BY attribute.attnum
         )
    INTO v_column_contract
    FROM pg_catalog.pg_attribute attribute
    LEFT JOIN pg_catalog.pg_attrdef default_row
      ON default_row.adrelid = attribute.attrelid
     AND default_row.adnum = attribute.attnum
   WHERE attribute.attrelid = v_relation
     AND attribute.attnum > 0
     AND NOT attribute.attisdropped;

  IF v_column_contract <>
       '1:viewer:text:false:::<null>|' ||
       '2:rows_returned:integer:false:::<null>|' ||
       '3:score:numeric:false:::<null>' THEN
    RAISE EXCEPTION
      'OA-ZYRA-198 probe bridge postcondition: column contract changed: %',
      v_column_contract;
  END IF;

  SELECT pg_catalog.pg_get_userbyid(class_row.relowner),
         class_row.relkind,
         class_row.relpersistence,
         class_row.relreplident,
         class_row.relrowsecurity,
         class_row.relforcerowsecurity,
         class_row.relhasindex,
         class_row.relhasrules,
         class_row.relhastriggers,
         class_row.relispartition
    INTO v_owner,
         v_relkind,
         v_relpersistence,
         v_relreplident,
         v_rls,
         v_force_rls,
         v_has_index,
         v_has_rules,
         v_has_triggers,
         v_is_partition
    FROM pg_catalog.pg_class class_row
   WHERE class_row.oid = v_relation;

  IF v_owner <> 'postgres'
     OR v_relkind <> 'r'
     OR v_relpersistence <> 'p'
     OR v_relreplident <> 'd'
     OR v_rls
     OR v_force_rls
     OR v_has_index
     OR v_has_rules
     OR v_has_triggers
     OR v_is_partition
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 probe bridge postcondition: relation contract changed';
  END IF;

  IF EXISTS (
       SELECT 1
         FROM pg_catalog.pg_constraint constraint_row
        WHERE constraint_row.conrelid = v_relation
     )
     OR EXISTS (
       SELECT 1
         FROM pg_catalog.pg_policy policy_row
        WHERE policy_row.polrelid = v_relation
     )
     OR pg_catalog.obj_description(v_relation, 'pg_class') IS NOT NULL
     OR EXISTS (
       SELECT 1
         FROM pg_catalog.pg_attribute attribute
        WHERE attribute.attrelid = v_relation
          AND attribute.attnum > 0
          AND NOT attribute.attisdropped
          AND pg_catalog.col_description(
                attribute.attrelid,
                attribute.attnum
              ) IS NOT NULL
     )
     OR EXISTS (
       SELECT 1
         FROM public.zyra_probe_score
     )
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 probe bridge postcondition: unexpected structure or row';
  END IF;
END
$oa198_probe_postcondition$;

COMMIT;
