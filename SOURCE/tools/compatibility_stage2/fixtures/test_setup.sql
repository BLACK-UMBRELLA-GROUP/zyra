-- ADMIN-ONLY synthetic fixture setup; never a production migration.
\set ON_ERROR_STOP on
CREATE TABLE s2_fixture.seed_cache(id integer PRIMARY KEY CHECK(id=1),payload jsonb NOT NULL);
REVOKE ALL ON s2_fixture.seed_cache FROM PUBLIC,s2_authenticated,s2_anon;
CREATE FUNCTION s2_fixture.seed(p_export jsonb) RETURNS void
LANGUAGE plpgsql SET search_path=pg_catalog,s2_private,s2_fixture,pg_temp AS $$
DECLARE v_manifest jsonb:=p_export->'manifest'; v_subject record; v_basis jsonb;
BEGIN
  IF current_database()<>'zyra_compat_stage2_research' OR NOT EXISTS
    (SELECT 1 FROM s2_private.sandbox_identity WHERE marker='compatibility-stage2-synthetic-only') THEN
    RAISE EXCEPTION 'refuse fixture reset outside exact candidate sandbox';
  END IF;
  IF session_user<>'postgres' THEN RAISE EXCEPTION 'privileged local fixture setup only'; END IF;
  IF jsonb_typeof(v_manifest)<>'object' OR NOT p_export ? 'subjects' THEN RAISE EXCEPTION 'invalid synthetic export'; END IF;
  INSERT INTO s2_fixture.seed_cache VALUES(1,p_export) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload;
  TRUNCATE s2_private.repair_audit,s2_private.input_evidence,s2_private.disclosure_bindings,
    s2_private.ledger,s2_private.entitlements,s2_private.operations,s2_private.pair_bindings,
    s2_private.snapshots,s2_private.input_heads,s2_private.input_revisions,
    s2_private.wallets,s2_private.journeys,s2_private.guardians,s2_private.pair_access,
    s2_private.subjects RESTART IDENTITY;
  INSERT INTO s2_private.manifests(version,payload,fingerprint)
    VALUES(v_manifest->>'version',v_manifest,encode(sha256(convert_to(v_manifest::text,'UTF8')),'hex')) ON CONFLICT(version) DO NOTHING;
  IF NOT EXISTS(SELECT 1 FROM s2_private.manifests WHERE version=v_manifest->>'version' AND payload=v_manifest) THEN
    RAISE EXCEPTION 'manifest identity collision';
  END IF;
  UPDATE s2_private.configuration SET plus_enabled=false,manifest_version=v_manifest->>'version',
    policy_version='synthetic-policy-v1',allowed_categories=ARRAY(SELECT jsonb_array_elements_text(v_manifest->'categories')),
    min_categories=2,standard_price=1,plus_price=1,revision=1 WHERE id=1;
  INSERT INTO s2_private.subjects(subject_id,db_role,sex,demo_only) VALUES
    ('synthetic-viewer','s2_viewer','male',false),('synthetic-viewer2','s2_viewer2','male',false),
    ('synthetic-target','s2_target','female',false),('synthetic-target2','s2_target2','female',false),
    ('synthetic-other','s2_other','male',false),('synthetic-guardian','s2_guardian','male',false),
    ('synthetic-demo','s2_demo','male',true);
  UPDATE s2_private.subjects SET account_kind='guardian' WHERE subject_id='synthetic-guardian';
  INSERT INTO s2_private.pair_access(viewer,target)
    SELECT a.subject_id,b.subject_id FROM s2_private.subjects a CROSS JOIN s2_private.subjects b WHERE a.subject_id<>b.subject_id;
  FOR v_subject IN SELECT subject_id,sex FROM s2_private.subjects LOOP
    v_basis:=p_export->'subjects'->v_subject.sex;
    PERFORM s2_private.capture(v_subject.subject_id,'answers',v_basis->'answers');
    PERFORM s2_private.capture(v_subject.subject_id,'preferences',v_basis->'preferences');
  END LOOP;
  INSERT INTO s2_private.wallets(actor,balance) VALUES('synthetic-viewer',4),('synthetic-viewer2',4),('synthetic-demo',4);
  INSERT INTO s2_private.ledger(actor,amount,kind) VALUES('synthetic-viewer',4,'grant'),('synthetic-viewer2',4,'grant'),('synthetic-demo',4,'grant');
  INSERT INTO s2_private.journeys(viewer,target,stage,mutual_reveal,reveal_permitted)
    VALUES('synthetic-viewer','synthetic-target','reveal',true,true);
  INSERT INTO s2_private.guardians(target,first_name,relationship,city,is_main,lookup_state)
    VALUES('synthetic-target','Synthetic Guardian','Father','Synthetic City',true,'linked');
END $$;
REVOKE ALL ON FUNCTION s2_fixture.seed(jsonb) FROM PUBLIC,s2_authenticated,s2_anon;

CREATE FUNCTION s2_fixture.reset() RETURNS void LANGUAGE sql
SET search_path=pg_catalog,s2_private,s2_fixture,pg_temp AS $$
  SELECT s2_fixture.seed(payload) FROM s2_fixture.seed_cache WHERE id=1;
$$;
REVOKE ALL ON FUNCTION s2_fixture.reset() FROM PUBLIC,s2_authenticated,s2_anon;

CREATE FUNCTION s2_fixture.latest_payload(p_subject text,p_kind text) RETURNS jsonb
LANGUAGE sql SET search_path=pg_catalog,s2_private,pg_temp AS $$
  SELECT r.raw_payload FROM s2_private.input_heads h JOIN s2_private.input_revisions r USING(revision_id)
  WHERE h.subject_id=p_subject AND h.kind=p_kind;
$$;
REVOKE ALL ON FUNCTION s2_fixture.latest_payload(text,text) FROM PUBLIC,s2_authenticated,s2_anon;

-- Privileged fixture-only barriers/failures. No API argument can configure one.
CREATE TABLE s2_fixture.injections(
  point text PRIMARY KEY CHECK(point IN ('snapshots','entitlements','ledger','disclosure_bindings','operations')),
  advisory_key bigint,
  fail boolean NOT NULL DEFAULT false
);
REVOKE ALL ON s2_fixture.injections FROM PUBLIC,s2_authenticated,s2_anon;
CREATE FUNCTION s2_fixture.inject_at_boundary() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,s2_fixture,pg_temp AS $$
DECLARE injection s2_fixture.injections%ROWTYPE;
BEGIN
  SELECT * INTO injection FROM s2_fixture.injections WHERE point=TG_TABLE_NAME;
  IF NOT FOUND THEN RETURN NEW; END IF;
  IF TG_TABLE_NAME='ledger' THEN
    IF NEW.kind<>'debit' THEN RETURN NEW; END IF;
  END IF;
  IF TG_TABLE_NAME='operations' THEN
    IF NEW.state<>'committed' THEN RETURN NEW; END IF;
  END IF;
  IF injection.advisory_key IS NOT NULL THEN PERFORM pg_advisory_xact_lock(injection.advisory_key); END IF;
  IF injection.fail THEN RAISE EXCEPTION 'synthetic boundary failure: %',TG_TABLE_NAME USING ERRCODE='P0001'; END IF;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION s2_fixture.inject_at_boundary() FROM PUBLIC,s2_authenticated,s2_anon;
CREATE TRIGGER fixture_snapshot_boundary BEFORE INSERT ON s2_private.snapshots FOR EACH ROW EXECUTE FUNCTION s2_fixture.inject_at_boundary();
CREATE TRIGGER fixture_entitlement_boundary BEFORE INSERT ON s2_private.entitlements FOR EACH ROW EXECUTE FUNCTION s2_fixture.inject_at_boundary();
CREATE TRIGGER fixture_ledger_boundary BEFORE INSERT ON s2_private.ledger FOR EACH ROW EXECUTE FUNCTION s2_fixture.inject_at_boundary();
CREATE TRIGGER fixture_disclosure_boundary BEFORE INSERT ON s2_private.disclosure_bindings FOR EACH ROW EXECUTE FUNCTION s2_fixture.inject_at_boundary();
CREATE TRIGGER fixture_operation_boundary BEFORE UPDATE ON s2_private.operations FOR EACH ROW EXECUTE FUNCTION s2_fixture.inject_at_boundary();
