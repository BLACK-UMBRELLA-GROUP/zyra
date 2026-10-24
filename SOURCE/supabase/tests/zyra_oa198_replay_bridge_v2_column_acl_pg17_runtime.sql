\set ON_ERROR_STOP on

BEGIN TRANSACTION READ ONLY;

DO $oa198_acl_pg17$
DECLARE
  v_server_version_num integer :=
    pg_catalog.current_setting('server_version_num')::integer;
  v_owner pg_catalog.oid;
  v_aclitem pg_catalog.aclitem;
  v_observed pg_catalog.jsonb;
BEGIN
  IF v_server_version_num < 170000
     OR v_server_version_num >= 180000 THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 V2 ACL test requires PostgreSQL 17';
  END IF;

  SELECT role_row.oid
    INTO STRICT v_owner
    FROM pg_catalog.pg_roles role_row
   WHERE role_row.rolname = current_user;

  v_aclitem := pg_catalog.makeaclitem(
    0::pg_catalog.oid,
    v_owner,
    'SELECT',
    false
  );

  IF pg_catalog.array_ndims(
       pg_catalog.acldefault('c', v_owner)
     ) IS DISTINCT FROM 1
     OR pg_catalog.cardinality(
       pg_catalog.acldefault('c', v_owner)
     ) IS DISTINCT FROM 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'column default ACL is not a valid one-dimensional empty ACL';
  END IF;

  BEGIN
    PERFORM 1
      FROM pg_catalog.aclexplode('{}'::pg_catalog.aclitem[]);

    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'zero-dimensional empty ACL unexpectedly accepted';
  EXCEPTION
    WHEN SQLSTATE '22023' THEN
      NULL;
  END;

  BEGIN
    PERFORM 1
      FROM pg_catalog.aclexplode(
        ARRAY[[v_aclitem]]::pg_catalog.aclitem[]
      );

    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'two-dimensional ACL unexpectedly accepted';
  EXCEPTION
    WHEN SQLSTATE '22023' THEN
      NULL;
  END;

  WITH class_row(relowner) AS (
    VALUES (v_owner)
  ),
  attribute(case_name, attacl) AS (
    VALUES
      ('null'::text, NULL::pg_catalog.aclitem[]),
      (
        'empty'::text,
        pg_catalog.acldefault('c', v_owner)
      ),
      (
        'nonempty'::text,
        ARRAY[v_aclitem]::pg_catalog.aclitem[]
      )
  ),
  expanded AS (
    SELECT
      attribute.case_name,
      (
        SELECT pg_catalog.count(*)
          FROM pg_catalog.aclexplode(
            COALESCE(
              attribute.attacl,
              pg_catalog.acldefault('c', class_row.relowner)
            )
          ) acl
      ) AS privilege_rows
    FROM attribute
    CROSS JOIN class_row
  )
  SELECT pg_catalog.jsonb_object_agg(
           expanded.case_name,
           expanded.privilege_rows
           ORDER BY expanded.case_name
         )
    INTO v_observed
    FROM expanded;

  IF v_observed IS DISTINCT FROM
       '{"empty":0,"nonempty":1,"null":0}'::pg_catalog.jsonb THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = pg_catalog.format(
        'unexpected column ACL results: %s',
        v_observed
      );
  END IF;
END
$oa198_acl_pg17$;

SELECT
  pg_catalog.current_setting('server_version_num') AS server_version_num,
  'OA-ZYRA-198 V2 PG17 COLUMN ACL PASS' AS result;

ROLLBACK;
