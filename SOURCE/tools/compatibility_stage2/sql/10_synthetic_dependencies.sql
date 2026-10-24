-- Candidate-only synthetic dependencies. Not production user/relationship tables.
\set ON_ERROR_STOP on
SET ROLE s2_owner;
CREATE TABLE s2_private.subjects (
  subject_id text PRIMARY KEY CHECK(subject_id ~ '^synthetic-'),
  db_role name UNIQUE,
  sex text NOT NULL CHECK(sex IN ('male','female')),
  account_kind text NOT NULL DEFAULT 'seeker' CHECK(account_kind IN ('seeker','guardian')),
  status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','suspended','deleted')),
  visible boolean NOT NULL DEFAULT true,
  demo_only boolean NOT NULL DEFAULT false,
  revision bigint NOT NULL DEFAULT 1
);
CREATE TABLE s2_private.pair_access (
  viewer text NOT NULL REFERENCES s2_private.subjects,
  target text NOT NULL REFERENCES s2_private.subjects,
  blocked boolean NOT NULL DEFAULT false,
  safety_restricted boolean NOT NULL DEFAULT false,
  revision bigint NOT NULL DEFAULT 1,
  PRIMARY KEY(viewer,target), CHECK(viewer<>target)
);
CREATE TABLE s2_private.configuration (
  id integer PRIMARY KEY CHECK(id=1),
  plus_enabled boolean NOT NULL DEFAULT false,
  manifest_version text,
  policy_version text NOT NULL DEFAULT 'synthetic-policy-v1',
  allowed_categories text[] NOT NULL DEFAULT ARRAY[]::text[],
  min_categories integer NOT NULL DEFAULT 2 CHECK(min_categories BETWEEN 1 AND 12),
  standard_price integer NOT NULL DEFAULT 1 CHECK(standard_price>0),
  plus_price integer NOT NULL DEFAULT 1 CHECK(plus_price>0),
  revision bigint NOT NULL DEFAULT 1
);
INSERT INTO s2_private.configuration(id) VALUES(1);
COMMENT ON TABLE s2_private.configuration IS 'All prices/policies/usefulness values are synthetic local test parameters, not product decisions.';
CREATE TABLE s2_private.journeys (
  viewer text NOT NULL REFERENCES s2_private.subjects,
  target text NOT NULL REFERENCES s2_private.subjects,
  stage text NOT NULL DEFAULT 'unrevealed',
  mutual_reveal boolean NOT NULL DEFAULT false,
  reveal_permitted boolean NOT NULL DEFAULT false,
  attempt_id text NOT NULL DEFAULT 'synthetic-attempt-1',
  PRIMARY KEY(viewer,target)
);
CREATE TABLE s2_private.guardians (
  target text PRIMARY KEY REFERENCES s2_private.subjects,
  first_name text,
  relationship text,
  city text,
  is_main boolean NOT NULL DEFAULT true,
  lookup_state text NOT NULL DEFAULT 'unavailable' CHECK(lookup_state IN ('linked','unlinked','unavailable'))
);
CREATE FUNCTION s2_private.current_actor() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,s2_private,pg_temp
AS $$ SELECT subject_id FROM s2_private.subjects WHERE db_role=session_user::name $$;
REVOKE ALL ON FUNCTION s2_private.current_actor() FROM PUBLIC;
-- Forced RLS has an explicit narrowly scoped owner policy. Ordinary roles have
-- no grants and no policy; the SECURITY DEFINER owner is not a superuser.
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['sandbox_identity','subjects','pair_access','configuration','journeys','guardians'] LOOP
    EXECUTE format('ALTER TABLE s2_private.%I ENABLE ROW LEVEL SECURITY',t);
    EXECUTE format('ALTER TABLE s2_private.%I FORCE ROW LEVEL SECURITY',t);
    EXECUTE format('CREATE POLICY owner_only ON s2_private.%I TO s2_owner USING(true) WITH CHECK(true)',t);
  END LOOP;
END $$;
RESET ROLE;
