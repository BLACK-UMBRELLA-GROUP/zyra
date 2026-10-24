-- CANDIDATE ONLY: raw list validation before canonical JSON, synthetic captures.
\set ON_ERROR_STOP on
SET ROLE s2_owner;
CREATE TABLE s2_private.manifests (
  version text PRIMARY KEY,
  payload jsonb NOT NULL,
  fingerprint text NOT NULL CHECK(fingerprint=encode(sha256(convert_to(payload::text,'UTF8')),'hex'))
);
CREATE TABLE s2_private.input_revisions (
  revision_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  subject_id text NOT NULL REFERENCES s2_private.subjects,
  kind text NOT NULL CHECK(kind IN ('answers','preferences')),
  manifest_version text NOT NULL REFERENCES s2_private.manifests,
  semantics_version text NOT NULL,
  raw_payload jsonb NOT NULL,
  canonical_payload jsonb,
  fingerprint text NOT NULL,
  quality text NOT NULL CHECK(quality IN ('validated','legacy_repair')),
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  UNIQUE(revision_id,subject_id,kind),
  CHECK((quality='validated' AND canonical_payload IS NOT NULL) OR quality='legacy_repair')
);
CREATE TABLE s2_private.input_heads (
  subject_id text NOT NULL REFERENCES s2_private.subjects,
  kind text NOT NULL CHECK(kind IN ('answers','preferences')),
  revision_id bigint NOT NULL,
  PRIMARY KEY(subject_id,kind),
  FOREIGN KEY(revision_id,subject_id,kind) REFERENCES s2_private.input_revisions(revision_id,subject_id,kind)
);
CREATE FUNCTION s2_private.input_immutable() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,s2_private,pg_temp AS $$
BEGIN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='immutable semantic/configuration revision'; END $$;
CREATE TRIGGER immutable_manifest BEFORE UPDATE ON s2_private.manifests
FOR EACH ROW EXECUTE FUNCTION s2_private.input_immutable();
CREATE TRIGGER immutable_input BEFORE UPDATE ON s2_private.input_revisions
FOR EACH ROW EXECUTE FUNCTION s2_private.input_immutable();

CREATE FUNCTION s2_private.invalid(p_reason text) RETURNS void
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
BEGIN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE=p_reason; END $$;

CREATE FUNCTION s2_private.exact_keys(p_value jsonb,p_allowed text[],p_required text[] DEFAULT ARRAY[]::text[])
RETURNS void LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE k text;
BEGIN
  IF jsonb_typeof(p_value) IS DISTINCT FROM 'object' THEN PERFORM s2_private.invalid('object required'); END IF;
  FOR k IN SELECT jsonb_object_keys(p_value) LOOP
    IF NOT k=ANY(p_allowed) THEN PERFORM s2_private.invalid('unknown object field'); END IF;
  END LOOP;
  FOREACH k IN ARRAY p_required LOOP
    IF NOT p_value ? k THEN PERFORM s2_private.invalid('missing object field'); END IF;
  END LOOP;
END $$;

CREATE FUNCTION s2_private.field_map(p_entries jsonb,p_allowed text[]) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE e jsonb; k text; result jsonb:='{}';
BEGIN
  IF jsonb_typeof(p_entries) IS DISTINCT FROM 'array' THEN PERFORM s2_private.invalid('raw field list required'); END IF;
  FOR e IN SELECT value FROM jsonb_array_elements(p_entries) LOOP
    PERFORM s2_private.exact_keys(e,ARRAY['key','value'],ARRAY['key','value']);
    IF jsonb_typeof(e->'key') IS DISTINCT FROM 'string' THEN PERFORM s2_private.invalid('invalid field identity'); END IF;
    k:=e->>'key';
    IF NOT k=ANY(p_allowed) OR result ? k THEN PERFORM s2_private.invalid('unknown or duplicate field'); END IF;
    result:=result||jsonb_build_object(k,e->'value');
  END LOOP;
  RETURN result;
END $$;

CREATE FUNCTION s2_private.options(p_values jsonb,p_vocabulary jsonb,p_empty boolean DEFAULT false) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE e jsonb; seen jsonb:='[]';
BEGIN
  IF jsonb_typeof(p_values) IS DISTINCT FROM 'array' OR
     (NOT p_empty AND jsonb_array_length(p_values)=0) THEN PERFORM s2_private.invalid('invalid selection list'); END IF;
  FOR e IN SELECT value FROM jsonb_array_elements(p_values) LOOP
    IF jsonb_typeof(e)<>'string' OR NOT p_vocabulary @> jsonb_build_array(e) OR seen @> jsonb_build_array(e) THEN
      PERFORM s2_private.invalid('unknown or duplicate option');
    END IF;
    seen:=seen||jsonb_build_array(e);
  END LOOP;
  RETURN seen;
END $$;

CREATE FUNCTION s2_private.semantics(p_semantics text,p_values jsonb) RETURNS void
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
BEGIN
  IF p_semantics='prefer-open-not-for-me-research-v1' THEN RETURN; END IF;
  IF p_semantics IS NOT NULL AND p_semantics<>'legacy-no-preference' THEN PERFORM s2_private.invalid('unknown preference semantics'); END IF;
  IF p_values @> '["amber"]'::jsonb OR p_values @> '["yellow"]'::jsonb THEN
    PERFORM s2_private.invalid('legacy amber review required');
  END IF;
END $$;

CREATE FUNCTION s2_private.light_map(p_entries jsonb,p_vocab jsonb,p_semantics text) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE e jsonb; result jsonb:='{}'; vals jsonb:='[]'; k text; light text;
BEGIN
  IF jsonb_typeof(p_entries) IS DISTINCT FROM 'array' THEN PERFORM s2_private.invalid('raw light list required'); END IF;
  FOR e IN SELECT value FROM jsonb_array_elements(p_entries) LOOP
    PERFORM s2_private.exact_keys(e,ARRAY['option','value'],ARRAY['option','value']);
    IF jsonb_typeof(e->'option') IS DISTINCT FROM 'string' OR jsonb_typeof(e->'value') IS DISTINCT FROM 'string' THEN
      PERFORM s2_private.invalid('invalid light entry');
    END IF;
    k:=e->>'option'; light:=e->>'value';
    IF NOT p_vocab @> jsonb_build_array(k) OR result ? k OR light NOT IN ('green','amber','red') THEN
      PERFORM s2_private.invalid('unknown duplicate or invalid light');
    END IF;
    result:=result||jsonb_build_object(k,light); vals:=vals||jsonb_build_array(light);
  END LOOP;
  PERFORM s2_private.semantics(p_semantics,vals);
  IF s2_private.object_length(result)<>jsonb_array_length(p_vocab) THEN PERFORM s2_private.invalid('missing required light'); END IF;
  RETURN result;
END $$;

-- PostgreSQL has no jsonb_object_length builtin. Central private helper avoids
-- relying on client-normalised map sizes as capture evidence.
CREATE FUNCTION s2_private.object_length(p_value jsonb) RETURNS integer
LANGUAGE sql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp
AS $$ SELECT count(*)::integer FROM jsonb_object_keys(p_value) $$;

CREATE FUNCTION s2_private.canonical_json(p_value jsonb) RETURNS text
LANGUAGE plpgsql IMMUTABLE STRICT SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE result text;
BEGIN
  IF jsonb_typeof(p_value)='object' THEN
    SELECT '{'||coalesce(string_agg(to_jsonb(key)::text||':'||s2_private.canonical_json(value),',' ORDER BY key COLLATE "C"),'')||'}'
      INTO result FROM jsonb_each(p_value);
  ELSIF jsonb_typeof(p_value)='array' THEN
    SELECT '['||coalesce(string_agg(s2_private.canonical_json(value),',' ORDER BY ordinal),'')||']'
      INTO result FROM jsonb_array_elements(p_value) WITH ORDINALITY AS element(value,ordinal);
  ELSE result:=p_value::text; END IF;
  RETURN result;
END $$;

CREATE FUNCTION s2_private.validate_manifest(p_m jsonb) RETURNS void
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE a jsonb; p jsonb; parent jsonb; seen jsonb:='{}'; prefs jsonb:='{}'; expected text; k text; n integer; mapped jsonb;
DECLARE cats jsonb:='["deen_practice","marriage_intentions","children_parenting","family_in_laws","finances_provision","education_career","home_roles","communication_conflict","personality_connection","lifestyle_wellbeing","digital_boundaries","culture_language"]';
BEGIN
  PERFORM s2_private.exact_keys(p_m,ARRAY['version','bank_provenance','applicability_version','category_version','hard_version','semantics_version','categories','answers','preferences','chapter2_vocabulary'],ARRAY['version','bank_provenance','applicability_version','category_version','hard_version','semantics_version','categories','answers','preferences','chapter2_vocabulary']);
  -- Independent code pin of the full exported, Stage1-validated registry.
  -- A self-consistent mutant cannot claim the source bank version by merely
  -- recomputing its table checksum. This exact finite research vocabulary is
  -- not a production custom-value normalisation policy.
  IF encode(sha256(convert_to(s2_private.canonical_json(p_m),'UTF8')),'hex') IS DISTINCT FROM
    '1fac439a6556922b06ee9810fe8daec076c86cf03a38cc8f961460dd7c02e862' THEN
    PERFORM s2_private.invalid('unapproved exact manifest fingerprint');
  END IF;
  IF p_m->>'version' IS DISTINCT FROM 'compatibility-stage1-research-v1' OR p_m->>'bank_provenance' IS DISTINCT FROM 'sha256:5208df8f7315d5d4a29a890a57268700c2c5bcda88e4f8ec4e329c9a7394e52d'
    OR p_m->>'applicability_version' IS DISTINCT FROM 'counterpart-applicability-stage1-v1'
    OR p_m->>'category_version' IS DISTINCT FROM 'twelve-categories-stage1-v1'
    OR p_m->>'hard_version' IS DISTINCT FROM 'source-hard-capability-stage1-v1'
    OR p_m->>'semantics_version' IS DISTINCT FROM 'prefer-open-not-for-me-research-v1'
    OR p_m->'categories' IS DISTINCT FROM cats THEN PERFORM s2_private.invalid('unsupported configuration version/category order'); END IF;
  IF jsonb_typeof(p_m->'answers') IS DISTINCT FROM 'array' OR jsonb_array_length(p_m->'answers')<>105
    OR jsonb_typeof(p_m->'preferences') IS DISTINCT FROM 'array' OR jsonb_array_length(p_m->'preferences')<>72 THEN
    PERFORM s2_private.invalid('incomplete manifest');
  END IF;
  FOR a IN SELECT value FROM jsonb_array_elements(p_m->'answers') LOOP
    k:=a->>'key';
    IF k IS NULL OR seen ? k OR NOT cats @> jsonb_build_array(a->>'category') THEN PERFORM s2_private.invalid('duplicate/missing answer category'); END IF;
    IF a->>'question_id' !~ '^ch3_q([1-9][0-9]{0,2})$' THEN PERFORM s2_private.invalid('unknown question identity'); END IF;
    n:=substring(a->>'question_id' from 6)::integer;
    IF n<1 OR n>104 THEN PERFORM s2_private.invalid('unknown question'); END IF;
    expected:=CASE
      WHEN n=ANY(ARRAY[33,34,35,36,37,38,39,40,41,42,43,44,45,46,49,50,51]) THEN 'deen_practice'
      WHEN n=ANY(ARRAY[1,23,25,26,27,28,31,32]) THEN 'marriage_intentions'
      WHEN n=ANY(ARRAY[2,3,24,29,48]) THEN 'children_parenting'
      WHEN n=ANY(ARRAY[4,5,6,7,8,9,10]) THEN 'family_in_laws'
      WHEN n=ANY(ARRAY[12,13,14,15,19,20,21,22,47,67,68]) THEN 'finances_provision'
      WHEN n=ANY(ARRAY[11,16,17,18,63]) THEN 'education_career'
      WHEN n=ANY(ARRAY[64,65,66,69,70,71,72,73]) THEN 'home_roles'
      WHEN n=ANY(ARRAY[74,75,76,77,78,79,80,81,82,83]) THEN 'communication_conflict'
      WHEN n=ANY(ARRAY[61,62,84]) THEN 'personality_connection'
      WHEN n=ANY(ARRAY[85,86,87,88,89,90,91,92,93]) THEN 'digital_boundaries'
      ELSE 'lifestyle_wellbeing' END;
    IF a->>'category' IS DISTINCT FROM expected THEN PERFORM s2_private.invalid('wrong canonical category mapping'); END IF;
    IF a->>'eligible' IS DISTINCT FROM (CASE WHEN n=ANY(ARRAY[1,2,3,4,5,6,7,8,9,11,12,13,14,15,16,18,20,22,23,24,25,26,28,29,30,31,33,34,35,36,37,38,39,40,43,44,46,47,48,49,50,51,52,53,54,55,56,57,60,61,63,64,65,66,67,68,70,71,72,73,74,75,78,81,84,85,86,87,90,95,97]) THEN 'true' ELSE 'false' END) THEN
      PERFORM s2_private.invalid('wrong scoring eligibility'); END IF;
    expected:=a->>'question_id';
    IF n=26 THEN
      IF a->>'variant' NOT IN ('male','female') OR a->>'variant' IS NULL THEN PERFORM s2_private.invalid('wrong q26 variant'); END IF;
      expected:=expected||'::'||(a->>'variant');
    ELSIF n=39 THEN
      IF a->>'variant' IS DISTINCT FROM 'male' THEN PERFORM s2_private.invalid('wrong q39 variant'); END IF;
      expected:=expected||'::male';
    ELSIF a->>'variant' IS NOT NULL THEN PERFORM s2_private.invalid('wrong answer variant'); END IF;
    IF k<>expected THEN PERFORM s2_private.invalid('wrong answer alias'); END IF;
    PERFORM s2_private.options(a->'options',a->'options');
    IF a->>'selection' IS DISTINCT FROM (CASE WHEN n IN (37,62,97) THEN 'multi' ELSE 'single' END) THEN
      PERFORM s2_private.invalid('invalid selection metadata'); END IF;
    IF a->'exclusive_options' IS DISTINCT FROM (CASE WHEN n IN (37,97) THEN '["None"]'::jsonb ELSE '[]'::jsonb END) THEN
      PERFORM s2_private.invalid('invalid exclusive metadata'); END IF;
    IF n=24 THEN
      IF a->>'parent_key' IS DISTINCT FROM 'ch3_q3' OR a->'hidden_options' IS DISTINCT FROM '["No"]'::jsonb THEN
        PERFORM s2_private.invalid('invalid q24 applicability'); END IF;
    ELSIF a->>'parent_key' IS NOT NULL OR a->'hidden_options' IS DISTINCT FROM '[]'::jsonb THEN PERFORM s2_private.invalid('unknown parent condition'); END IF;
    IF jsonb_typeof(a->'eligible') IS DISTINCT FROM 'boolean' OR jsonb_typeof(a->'hard_supported') IS DISTINCT FROM 'boolean' THEN
      PERFORM s2_private.invalid('invalid capability metadata'); END IF;
    seen:=seen||jsonb_build_object(k,a);
  END LOOP;
  FOR n IN 1..104 LOOP
    IF n=26 THEN
      IF NOT seen ? 'ch3_q26::male' OR NOT seen ? 'ch3_q26::female' THEN PERFORM s2_private.invalid('missing q26 variants'); END IF;
    ELSIF n=39 THEN
      IF NOT seen ? 'ch3_q39::male' THEN PERFORM s2_private.invalid('missing q39'); END IF;
    ELSIF NOT seen ? ('ch3_q'||n) THEN PERFORM s2_private.invalid('missing question'); END IF;
  END LOOP;
  IF seen->'ch3_q26::male'->'options'=seen->'ch3_q26::female'->'options' THEN PERFORM s2_private.invalid('collapsed q26 vocabulary'); END IF;
  FOR p IN SELECT value FROM jsonb_array_elements(p_m->'preferences') LOOP
    k:=p->>'id'; a:=seen->(p->>'target_key');
    IF a IS NULL OR NOT (a->>'eligible')::boolean OR k IS DISTINCT FROM 'pref:'||(a->>'key') OR prefs ? k
      OR p->'options' IS DISTINCT FROM a->'options' OR p->'category' IS DISTINCT FROM a->'category'
      OR p->'hard_supported' IS DISTINCT FROM a->'hard_supported'
      OR p->'target_pool' IS DISTINCT FROM (CASE WHEN a->>'variant' IS NULL THEN '["male","female"]'::jsonb ELSE jsonb_build_array(a->>'variant') END) THEN
      PERFORM s2_private.invalid('invalid preference mapping'); END IF;
    prefs:=prefs||jsonb_build_object(k,p);
  END LOOP;
  FOR a IN SELECT value FROM jsonb_each(seen) LOOP
    IF (a->>'eligible')::boolean AND NOT prefs ? ('pref:'||(a->>'key')) THEN PERFORM s2_private.invalid('missing preference mapping'); END IF;
  END LOOP;
  PERFORM s2_private.exact_keys(p_m->'chapter2_vocabulary',ARRAY['sect','country_of_birth','nationality','ethnicity','languages','location'],ARRAY['sect','country_of_birth','nationality','ethnicity','languages','location']);
  FOR mapped IN SELECT value FROM jsonb_each(p_m->'chapter2_vocabulary') LOOP PERFORM s2_private.options(mapped,mapped); END LOOP;
  IF NOT p_m->'chapter2_vocabulary'->'sect' @> '["sunni","shia"]'::jsonb THEN PERFORM s2_private.invalid('synthetic sect registry missing'); END IF;
END $$;

CREATE FUNCTION s2_private.capture_text(p_subject text,p_kind text,p_payload text,p_quality text DEFAULT 'validated') RETURNS bigint
LANGUAGE plpgsql SECURITY INVOKER SET search_path=pg_catalog,s2_private,pg_temp AS $$
BEGIN
  IF p_payload IS NULL OR NOT (p_payload IS JSON WITH UNIQUE KEYS) THEN
    PERFORM s2_private.invalid('invalid raw JSON or duplicate object member');
  END IF;
  RETURN s2_private.capture(p_subject,p_kind,p_payload::jsonb,p_quality);
END $$;

CREATE FUNCTION s2_private.validate_answers(p_m jsonb,p_sex text,p_raw jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE defs jsonb; ans jsonb; ch2 jsonb; a jsonb; k text; selected jsonb; applicable boolean; keylist text[]; v jsonb;
BEGIN
  PERFORM s2_private.exact_keys(p_raw,ARRAY['answers','chapter2'],ARRAY['answers','chapter2']);
  SELECT coalesce(jsonb_agg(value),'[]') INTO defs FROM jsonb_array_elements(p_m->'answers') WHERE value->>'variant' IS NULL OR value->>'variant'=p_sex;
  SELECT array_agg(value->>'key') INTO keylist FROM jsonb_array_elements(defs);
  ans:=s2_private.field_map(p_raw->'answers',keylist);
  FOR a IN SELECT value FROM jsonb_array_elements(defs) LOOP
    k:=a->>'key';
    IF ans ? k THEN
      IF a->>'selection'='single' THEN
        IF jsonb_typeof(ans->k) IS DISTINCT FROM 'string' OR NOT a->'options' @> jsonb_build_array(ans->k) THEN PERFORM s2_private.invalid('invalid scalar answer'); END IF;
        ans:=jsonb_set(ans,ARRAY[k],jsonb_build_array(ans->k));
      ELSE
        selected:=s2_private.options(ans->k,a->'options');
        IF jsonb_array_length(selected)>1 AND selected ?| ARRAY(SELECT jsonb_array_elements_text(a->'exclusive_options')) THEN PERFORM s2_private.invalid('exclusive answer conflict'); END IF;
      END IF;
    END IF;
  END LOOP;
  FOR a IN SELECT value FROM jsonb_array_elements(defs) LOOP
    k:=a->>'key'; applicable:=true;
    IF a->>'parent_key' IS NOT NULL THEN
      IF NOT ans ? (a->>'parent_key') THEN PERFORM s2_private.invalid('missing parent evidence'); END IF;
      applicable:=NOT (ans->(a->>'parent_key') ?| ARRAY(SELECT jsonb_array_elements_text(a->'hidden_options')));
    END IF;
    IF applicable AND NOT ans ? k THEN PERFORM s2_private.invalid('missing required answer'); END IF;
    IF NOT applicable AND ans ? k THEN PERFORM s2_private.invalid('stale hidden answer'); END IF;
  END LOOP;
  ch2:=s2_private.field_map(p_raw->'chapter2',ARRAY['sect','revert','country_of_birth','nationality','ethnicity','languages','location']);
  PERFORM s2_private.exact_keys(ch2,ARRAY['sect','revert','country_of_birth','nationality','ethnicity','languages','location'],ARRAY['sect','revert','country_of_birth','nationality','ethnicity','languages']);
  FOREACH k IN ARRAY ARRAY['sect','country_of_birth','nationality','ethnicity'] LOOP
    IF jsonb_typeof(ch2->k) IS DISTINCT FROM 'string' OR NOT p_m->'chapter2_vocabulary'->k @> jsonb_build_array(ch2->k) THEN PERFORM s2_private.invalid('unknown chapter2 option'); END IF;
  END LOOP;
  IF jsonb_typeof(ch2->'revert') IS DISTINCT FROM 'boolean' THEN PERFORM s2_private.invalid('invalid revert'); END IF;
  PERFORM s2_private.options(ch2->'languages',p_m->'chapter2_vocabulary'->'languages');
  IF ch2 ? 'location' AND (jsonb_typeof(ch2->'location') IS DISTINCT FROM 'string' OR length(btrim(ch2->>'location'))=0) THEN PERFORM s2_private.invalid('invalid unscored location'); END IF;
  RETURN jsonb_build_object('answers',ans,'chapter2',ch2);
END $$;

CREATE FUNCTION s2_private.validate_preferences(p_m jsonb,p_raw jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE p jsonb; c jsonb; controls jsonb:='{}'; blocks jsonb:='{}'; expected jsonb; opts jsonb; hards jsonb; b jsonb; fields jsonb; k text; light text; pool jsonb; semantics text;
BEGIN
  PERFORM s2_private.exact_keys(p_raw,ARRAY['pool','controls','chapter2'],ARRAY['pool','controls','chapter2']);
  pool:=s2_private.options(p_raw->'pool','["male","female"]');
  IF jsonb_array_length(pool)<>1 THEN PERFORM s2_private.invalid('unsupported counterpart pool'); END IF;
  SELECT coalesce(jsonb_agg(value),'[]') INTO expected FROM jsonb_array_elements(p_m->'preferences') WHERE value->'target_pool' @> pool;
  IF jsonb_typeof(p_raw->'controls') IS DISTINCT FROM 'array' THEN PERFORM s2_private.invalid('raw controls required'); END IF;
  FOR p IN SELECT value FROM jsonb_array_elements(p_raw->'controls') LOOP
    PERFORM s2_private.exact_keys(p,ARRAY['id','lights','hards','semantics'],ARRAY['id','lights','hards']);
    IF jsonb_typeof(p->'id') IS DISTINCT FROM 'string' THEN PERFORM s2_private.invalid('invalid preference identity'); END IF;
    k:=p->>'id'; SELECT value INTO c FROM jsonb_array_elements(expected) WHERE value->>'id'=k;
    IF c IS NULL OR controls ? k THEN PERFORM s2_private.invalid('unknown duplicate or hidden preference alias'); END IF;
    opts:=s2_private.light_map(p->'lights',c->'options',p->>'semantics');
    hards:=s2_private.options(p->'hards',c->'options',true);
    IF NOT (c->>'hard_supported')::boolean AND jsonb_array_length(hards)>0 THEN PERFORM s2_private.invalid('unsupported hard requirement'); END IF;
    controls:=controls||jsonb_build_object(k,jsonb_build_object('lights',opts,'hards',hards));
  END LOOP;
  IF s2_private.object_length(controls)<>jsonb_array_length(expected) THEN PERFORM s2_private.invalid('missing required preference'); END IF;
  IF jsonb_typeof(p_raw->'chapter2') IS DISTINCT FROM 'array' THEN PERFORM s2_private.invalid('raw chapter2 controls required'); END IF;
  FOR b IN SELECT value FROM jsonb_array_elements(p_raw->'chapter2') LOOP
    PERFORM s2_private.exact_keys(b,ARRAY['key','fields','semantics'],ARRAY['key','fields']);
    k:=b->>'key'; semantics:=b->>'semantics';
    IF k IS NULL OR k NOT IN ('sect','revert','country_of_birth','nationality','ethnicity','languages') OR blocks ? k THEN PERFORM s2_private.invalid('unknown duplicate chapter2 control'); END IF;
    IF k='sect' THEN
      fields:=s2_private.field_map(b->'fields',ARRAY['matrix','hard_requirement','outside_flexibility']);
      PERFORM s2_private.exact_keys(fields,ARRAY['matrix','hard_requirement','outside_flexibility'],ARRAY['matrix','hard_requirement']);
      opts:=s2_private.light_map(fields->'matrix',p_m->'chapter2_vocabulary'->'sect',semantics);
      hards:=s2_private.options(fields->'hard_requirement',p_m->'chapter2_vocabulary'->'sect',true);
      IF fields ? 'outside_flexibility' THEN
        light:=fields->>'outside_flexibility';
        IF light NOT IN ('green','amber','red') OR jsonb_typeof(fields->'outside_flexibility') IS DISTINCT FROM 'string' THEN PERFORM s2_private.invalid('invalid outside flexibility'); END IF;
        PERFORM s2_private.semantics(semantics,jsonb_build_array(light));
      END IF;
      fields:=jsonb_build_object('matrix',opts,'hard_requirement',hards);
    ELSIF k='revert' THEN
      fields:=s2_private.field_map(b->'fields',ARRAY['flexibility']);
      light:=fields->>'flexibility';
      IF light IS NULL OR light NOT IN ('green','amber','red') OR jsonb_typeof(fields->'flexibility') IS DISTINCT FROM 'string' THEN PERFORM s2_private.invalid('missing invalid revert preference'); END IF;
      PERFORM s2_private.semantics(semantics,jsonb_build_array(light));
    ELSE
      fields:=s2_private.field_map(b->'fields',ARRAY['preferred','flexibility','skipped']);
      PERFORM s2_private.exact_keys(fields,ARRAY['preferred','flexibility','skipped'],ARRAY['preferred','skipped']);
      IF jsonb_typeof(fields->'skipped') IS DISTINCT FROM 'boolean' THEN PERFORM s2_private.invalid('invalid skip evidence'); END IF;
      opts:=s2_private.options(fields->'preferred',p_m->'chapter2_vocabulary'->k,true);
      light:=fields->>'flexibility';
      IF fields ? 'flexibility' THEN
        IF light IS NULL OR light NOT IN ('green','amber','red') OR jsonb_typeof(fields->'flexibility') IS DISTINCT FROM 'string' THEN PERFORM s2_private.invalid('invalid flexibility'); END IF;
        PERFORM s2_private.semantics(semantics,jsonb_build_array(light));
      END IF;
      IF NOT (fields->>'skipped')::boolean AND jsonb_array_length(opts)>0 AND light IS NULL THEN PERFORM s2_private.invalid('missing required flexibility'); END IF;
      IF (fields->>'skipped')::boolean AND jsonb_array_length(opts)>0 THEN PERFORM s2_private.invalid('contradictory skip'); END IF;
    END IF;
    blocks:=blocks||jsonb_build_object(k,fields);
  END LOOP;
  IF s2_private.object_length(blocks)<>6 THEN PERFORM s2_private.invalid('missing chapter2 control'); END IF;
  RETURN jsonb_build_object('pool',pool,'controls',controls,'chapter2',blocks);
END $$;

CREATE FUNCTION s2_private.capture(p_subject text,p_kind text,p_payload jsonb,p_quality text DEFAULT 'validated') RETURNS bigint
LANGUAGE plpgsql SECURITY INVOKER SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE m jsonb; sex text; v_manifest_version text; canon jsonb; rid bigint; captured_semantics text;
BEGIN
  SELECT s.sex INTO sex FROM s2_private.subjects s WHERE subject_id=p_subject FOR UPDATE;
  IF sex IS NULL OR p_kind NOT IN ('answers','preferences') OR p_quality NOT IN ('validated','legacy_repair') THEN PERFORM s2_private.invalid('invalid synthetic capture identity'); END IF;
  SELECT c.manifest_version INTO v_manifest_version FROM s2_private.configuration c WHERE c.id=1;
  SELECT registry.payload INTO m FROM s2_private.manifests registry WHERE registry.version=v_manifest_version;
  PERFORM s2_private.validate_manifest(m);
  IF p_quality='validated' THEN
    canon:=CASE WHEN p_kind='answers' THEN s2_private.validate_answers(m,sex,p_payload) ELSE s2_private.validate_preferences(m,p_payload) END;
  ELSE canon:=NULL; END IF;
  IF p_kind='answers' THEN captured_semantics:='not-applicable-own-answer-capture';
  ELSE
    -- Preserve the actual per-control capture versions, including unversioned
    -- green/red controls; validation is not fictional future recapture.
    SELECT coalesce(jsonb_agg(captured)::text,'[]') INTO captured_semantics FROM (
      SELECT jsonb_build_object('id',entry->>'id','semantics',entry->'semantics') AS captured
      FROM jsonb_array_elements(CASE WHEN jsonb_typeof(p_payload->'controls')='array' THEN p_payload->'controls' ELSE '[]'::jsonb END) AS raw(entry)
      UNION ALL
      SELECT jsonb_build_object('id','ch2:'||(entry->>'key'),'semantics',entry->'semantics')
      FROM jsonb_array_elements(CASE WHEN jsonb_typeof(p_payload->'chapter2')='array' THEN p_payload->'chapter2' ELSE '[]'::jsonb END) AS raw(entry)
    ) AS capture_versions;
  END IF;
  INSERT INTO s2_private.input_revisions(subject_id,kind,manifest_version,semantics_version,raw_payload,canonical_payload,fingerprint,quality)
  VALUES(p_subject,p_kind,v_manifest_version,captured_semantics,p_payload,canon,encode(sha256(convert_to(p_payload::text,'UTF8')),'hex'),p_quality) RETURNING revision_id INTO rid;
  INSERT INTO s2_private.input_heads(subject_id,kind,revision_id) VALUES(p_subject,p_kind,rid)
  ON CONFLICT(subject_id,kind) DO UPDATE SET revision_id=EXCLUDED.revision_id;
  RETURN rid;
END $$;
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['manifests','input_revisions','input_heads'] LOOP
    EXECUTE format('ALTER TABLE s2_private.%I ENABLE ROW LEVEL SECURITY',t);
    EXECUTE format('ALTER TABLE s2_private.%I FORCE ROW LEVEL SECURITY',t);
    EXECUTE format('CREATE POLICY owner_only ON s2_private.%I TO s2_owner USING(true) WITH CHECK(true)',t);
  END LOOP;
END $$;
RESET ROLE;
