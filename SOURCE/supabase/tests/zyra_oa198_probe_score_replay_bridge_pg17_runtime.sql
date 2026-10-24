-- OA-ZYRA-198 probe-score replay bridge — PostgreSQL 17 post-target proof.
--
-- Run only after the quarantined 20260811233812 reconstruction and the two
-- unchanged table statements from historical migration 20260811233813 have
-- executed in a disposable, credential-free PostgreSQL 17 database.
-- This harness is read-only and always rolls back.

\set ON_ERROR_STOP on

BEGIN TRANSACTION READ ONLY;

DO $oa198_probe_runtime$
DECLARE
  v_relation oid := pg_catalog.to_regclass('public.zyra_probe_score');
  v_column_contract text;
  v_relation_contract text;
  v_grantee text;
  v_privilege text;
BEGIN
  IF pg_catalog.current_setting('server_version_num')::integer < 170000
     OR pg_catalog.current_setting('server_version_num')::integer >= 180000
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 probe runtime requires PostgreSQL 17';
  END IF;

  IF v_relation IS NULL THEN
    RAISE EXCEPTION 'OA-ZYRA-198 probe runtime: relation absent';
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
      'OA-ZYRA-198 probe runtime: column contract changed: %',
      v_column_contract;
  END IF;

  SELECT pg_catalog.concat_ws(
           '|',
           pg_catalog.pg_get_userbyid(class_row.relowner),
           class_row.relkind::text,
           class_row.relpersistence::text,
           class_row.relreplident::text,
           class_row.relrowsecurity::text,
           class_row.relforcerowsecurity::text,
           class_row.relhasindex::text,
           class_row.relhasrules::text,
           class_row.relhastriggers::text,
           class_row.relispartition::text,
           COALESCE(class_row.relacl::text, '<null>')
         )
    INTO v_relation_contract
    FROM pg_catalog.pg_class class_row
   WHERE class_row.oid = v_relation;

  IF v_relation_contract <>
       'postgres|r|p|d|true|false|false|false|false|false|'
       || '{postgres=arwdDxtm/postgres,service_role=arwdDxtm/postgres}' THEN
    RAISE EXCEPTION
      'OA-ZYRA-198 probe runtime: relation contract changed: %',
      v_relation_contract;
  END IF;

  IF EXISTS (
       SELECT 1
         FROM pg_catalog.pg_constraint constraint_row
        WHERE constraint_row.conrelid = v_relation
     )
     OR EXISTS (
       SELECT 1
         FROM pg_catalog.pg_index index_row
        WHERE index_row.indrelid = v_relation
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
    RAISE EXCEPTION 'OA-ZYRA-198 probe runtime: unexpected structure or row';
  END IF;

  FOREACH v_grantee IN ARRAY ARRAY['anon', 'authenticated']
  LOOP
    FOREACH v_privilege IN ARRAY ARRAY[
      'SELECT',
      'INSERT',
      'UPDATE',
      'DELETE',
      'TRUNCATE',
      'REFERENCES',
      'TRIGGER',
      'MAINTAIN'
    ]
    LOOP
      IF pg_catalog.has_table_privilege(
           v_grantee,
           v_relation,
           v_privilege
         ) THEN
        RAISE EXCEPTION
          'OA-ZYRA-198 probe runtime: % retains %',
          v_grantee,
          v_privilege;
      END IF;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'OA-ZYRA-198 PROBE SCORE BRIDGE PG17 PASS';
END
$oa198_probe_runtime$;

ROLLBACK;
