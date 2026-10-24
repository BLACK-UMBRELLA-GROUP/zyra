-- Private Stage 2 research scorer. No ordinary EXECUTE; no client version input.
\set ON_ERROR_STOP on
SET ROLE s2_owner;
CREATE FUNCTION s2_private.gcd_numeric(p_a numeric,p_b numeric) RETURNS numeric
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE a numeric:=abs(p_a); b numeric:=abs(p_b); r numeric;
BEGIN
  IF a<>trunc(a) OR b<>trunc(b) THEN PERFORM s2_private.invalid('noninteger rational'); END IF;
  WHILE b<>0 LOOP r:=mod(a,b); a:=b; b:=r; END LOOP;
  RETURN greatest(a,1);
END $$;
CREATE FUNCTION s2_private.fraction_add(p_an numeric,p_ad numeric,p_bn numeric,p_bd numeric) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE n numeric; d numeric; g numeric;
BEGIN
  IF p_ad<=0 OR p_bd<=0 THEN PERFORM s2_private.invalid('invalid denominator'); END IF;
  n:=p_an*p_bd+p_bn*p_ad; d:=p_ad*p_bd; g:=s2_private.gcd_numeric(n,d);
  RETURN jsonb_build_object('earned_n',div(n,g),'earned_d',div(d,g));
END $$;

CREATE FUNCTION s2_private.calculate_bundle(p_viewer text,p_target text,p_bundle jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE SECURITY INVOKER SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE m jsonb; va jsonb; ta jsonb; vp jsonb; control jsonb; pref jsonb; selected jsonb; opt jsonb; cat text;
DECLARE units jsonb:='[]'; lights jsonb; ch2 jsonb; target_ch2 jsonb; k text; matches boolean; preferred jsonb;
DECLARE categories jsonb:='{}'; total_n numeric:=0; total_d numeric:=1; available integer:=0;
DECLARE unit jsonb; l text; light_sum integer; unit_n numeric; unit_d numeric; sum_fraction jsonb; category_sum jsonb;
DECLARE category_order jsonb; versions jsonb;
BEGIN
  -- Caller identity/access is deliberately outside this internal calculation.
  -- Public purpose interfaces must derive identity and authorise every read.
  IF p_viewer IS NULL OR p_target IS NULL OR p_viewer=p_target OR p_bundle IS NULL THEN
    RETURN jsonb_build_object('state','configuration_failure');
  END IF;
  m:=p_bundle->'manifest';
  BEGIN
    PERFORM s2_private.validate_manifest(m);
    IF p_bundle->>'viewer_sex' NOT IN ('male','female') OR p_bundle->>'viewer_sex' IS NULL
      OR p_bundle->>'target_sex' NOT IN ('male','female') OR p_bundle->>'target_sex' IS NULL THEN
      PERFORM s2_private.invalid('invalid captured sex'); END IF;
  EXCEPTION WHEN OTHERS THEN RETURN jsonb_build_object('state','configuration_failure'); END;
  BEGIN
    va:=s2_private.validate_answers(m,p_bundle->>'viewer_sex',p_bundle->'viewer_answers');
    vp:=s2_private.validate_preferences(m,p_bundle->'viewer_preferences');
    IF NOT ((vp->'pool') @> jsonb_build_array(p_bundle->>'target_sex')) THEN PERFORM s2_private.invalid('wrong counterpart pool'); END IF;
  EXCEPTION
    WHEN SQLSTATE '22023' THEN RETURN jsonb_build_object('state','owner_repair');
    WHEN OTHERS THEN RETURN jsonb_build_object('state','configuration_failure');
  END;
  BEGIN
    ta:=s2_private.validate_answers(m,p_bundle->>'target_sex',p_bundle->'target_answers');
  EXCEPTION
    WHEN SQLSTATE '22023' THEN RETURN jsonb_build_object('state','target_unavailable');
    WHEN OTHERS THEN RETURN jsonb_build_object('state','configuration_failure');
  END;
  FOR control IN SELECT value FROM jsonb_array_elements(m->'preferences')
    WHERE (value->'target_pool') @> (vp->'pool') LOOP
    selected:=ta->'answers'->(control->>'target_key');
    IF selected IS NULL THEN CONTINUE; END IF; -- only validated conditional skip
    pref:=vp->'controls'->(control->>'id'); lights:='[]';
    FOR opt IN SELECT value FROM jsonb_array_elements(selected) LOOP
      IF (pref->'hards') @> jsonb_build_array(opt) THEN RETURN jsonb_build_object('state','hard_excluded'); END IF;
      lights:=lights||jsonb_build_array(pref->'lights'->(opt#>>'{}'));
    END LOOP;
    units:=units||jsonb_build_array(jsonb_build_object('id',control->>'id','category',control->>'category','lights',lights));
  END LOOP;
  ch2:=vp->'chapter2'; target_ch2:=ta->'chapter2';
  IF (ch2->'sect'->'hard_requirement') @> jsonb_build_array(target_ch2->'sect') THEN RETURN jsonb_build_object('state','hard_excluded'); END IF;
  units:=units||jsonb_build_array(jsonb_build_object('id','ch2:sect','category','deen_practice','lights',jsonb_build_array(ch2->'sect'->'matrix'->(target_ch2->>'sect'))));
  IF (target_ch2->>'revert')::boolean THEN
    units:=units||jsonb_build_array(jsonb_build_object('id','ch2:revert','category','deen_practice','lights',jsonb_build_array(ch2->'revert'->'flexibility')));
  END IF;
  FOREACH k IN ARRAY ARRAY['country_of_birth','nationality','ethnicity','languages'] LOOP
    pref:=ch2->k;
    IF (pref->>'skipped')::boolean THEN CONTINUE; END IF;
    SELECT coalesce(jsonb_agg(value),'[]') INTO preferred FROM jsonb_array_elements(pref->'preferred')
      WHERE k<>'languages' OR value<>'"en"'::jsonb;
    IF jsonb_array_length(preferred)=0 THEN CONTINUE; END IF;
    IF k='languages' THEN
      SELECT EXISTS(SELECT 1 FROM jsonb_array_elements(target_ch2->k) WHERE preferred @> jsonb_build_array(value)) INTO matches;
    ELSE matches:=preferred @> jsonb_build_array(target_ch2->k); END IF;
    lights:=jsonb_build_array(CASE WHEN matches THEN '"green"'::jsonb ELSE pref->'flexibility' END);
    units:=units||jsonb_build_array(jsonb_build_object('id','ch2:'||k,'category','culture_language','lights',lights));
  END LOOP;
  category_order:=m->'categories';
  FOR cat IN SELECT jsonb_array_elements_text(category_order) LOOP
    categories:=categories||jsonb_build_object(cat,jsonb_build_object('earned_n',0,'earned_d',1,'available',0));
  END LOOP;
  FOR unit IN SELECT value FROM jsonb_array_elements(units) LOOP
    light_sum:=0;
    FOR l IN SELECT jsonb_array_elements_text(unit->'lights') LOOP
      light_sum:=light_sum+CASE l WHEN 'green' THEN 2 WHEN 'amber' THEN 1 WHEN 'red' THEN 0 ELSE NULL END;
    END LOOP;
    IF light_sum IS NULL OR jsonb_array_length(unit->'lights')=0 THEN RETURN jsonb_build_object('state','configuration_failure'); END IF;
    unit_n:=light_sum; unit_d:=2*jsonb_array_length(unit->'lights');
    sum_fraction:=s2_private.fraction_add(total_n,total_d,unit_n,unit_d);
    total_n:=(sum_fraction->>'earned_n')::numeric; total_d:=(sum_fraction->>'earned_d')::numeric; available:=available+1;
    cat:=unit->>'category'; category_sum:=categories->cat;
    IF category_sum IS NULL THEN RETURN jsonb_build_object('state','configuration_failure'); END IF;
    sum_fraction:=s2_private.fraction_add((category_sum->>'earned_n')::numeric,(category_sum->>'earned_d')::numeric,unit_n,unit_d);
    categories:=jsonb_set(categories,ARRAY[cat],sum_fraction||jsonb_build_object('available',(category_sum->>'available')::integer+1));
  END LOOP;
  IF available=0 THEN RETURN jsonb_build_object('state','no_scoreable_data'); END IF;
  versions:=jsonb_build_object('scoring_contract','stage2-local-question-unit-rational-v1','manifest',m->>'version','bank',m->>'bank_provenance','semantics',m->>'semantics_version','capture_semantics',p_bundle->'capture_semantics','applicability',m->>'applicability_version','categories',m->>'category_version','hards',m->>'hard_version');
  RETURN jsonb_build_object('state','success','earned_n',total_n,'earned_d',total_d,'available',available,
    'categories',categories,'category_order',category_order,'versions',versions,
    'input_revision_ids',coalesce(p_bundle->'revision_ids','{}'),
    'evidence_bundle',p_bundle);
END $$;

CREATE FUNCTION s2_private.calculate(p_viewer text,p_target text) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path=pg_catalog,s2_private,pg_temp AS $$
DECLARE va s2_private.input_revisions%ROWTYPE; vp s2_private.input_revisions%ROWTYPE; ta s2_private.input_revisions%ROWTYPE;
DECLARE manifest jsonb; manifest_version text; viewer_sex text; target_sex text; bundle jsonb; expected_fingerprint text;
BEGIN
  SELECT s.sex INTO viewer_sex FROM s2_private.subjects s WHERE subject_id=p_viewer;
  SELECT s.sex INTO target_sex FROM s2_private.subjects s WHERE subject_id=p_target;
  SELECT c.manifest_version INTO manifest_version FROM s2_private.configuration c WHERE id=1;
  SELECT m.payload,m.fingerprint INTO manifest,expected_fingerprint FROM s2_private.manifests m WHERE version=manifest_version;
  IF manifest IS NULL OR expected_fingerprint IS DISTINCT FROM encode(sha256(convert_to(manifest::text,'UTF8')),'hex') THEN RETURN jsonb_build_object('state','configuration_failure'); END IF;
  SELECT r.* INTO va FROM s2_private.input_heads h JOIN s2_private.input_revisions r USING(revision_id) WHERE h.subject_id=p_viewer AND h.kind='answers';
  SELECT r.* INTO vp FROM s2_private.input_heads h JOIN s2_private.input_revisions r USING(revision_id) WHERE h.subject_id=p_viewer AND h.kind='preferences';
  SELECT r.* INTO ta FROM s2_private.input_heads h JOIN s2_private.input_revisions r USING(revision_id) WHERE h.subject_id=p_target AND h.kind='answers';
  IF va.revision_id IS NULL OR vp.revision_id IS NULL THEN RETURN jsonb_build_object('state','owner_repair'); END IF;
  IF ta.revision_id IS NULL THEN RETURN jsonb_build_object('state','target_unavailable'); END IF;
  IF va.quality='legacy_repair' OR vp.quality='legacy_repair' THEN RETURN jsonb_build_object('state','owner_repair'); END IF;
  IF ta.quality='legacy_repair' THEN RETURN jsonb_build_object('state','target_unavailable'); END IF;
  IF va.manifest_version IS DISTINCT FROM manifest_version OR vp.manifest_version IS DISTINCT FROM manifest_version OR ta.manifest_version IS DISTINCT FROM manifest_version THEN RETURN jsonb_build_object('state','configuration_failure'); END IF;
  -- Revalidate captured raw input; neither the quality marker nor stored
  -- canonical JSON alone is accepted as proof that the inputs are correct.
  IF va.fingerprint IS DISTINCT FROM encode(sha256(convert_to(va.raw_payload::text,'UTF8')),'hex') OR
     vp.fingerprint IS DISTINCT FROM encode(sha256(convert_to(vp.raw_payload::text,'UTF8')),'hex') THEN RETURN jsonb_build_object('state','owner_repair'); END IF;
  IF ta.fingerprint IS DISTINCT FROM encode(sha256(convert_to(ta.raw_payload::text,'UTF8')),'hex') THEN RETURN jsonb_build_object('state','target_unavailable'); END IF;
  bundle:=jsonb_build_object('manifest',manifest,'viewer_sex',viewer_sex,'target_sex',target_sex,
    'viewer_answers',va.raw_payload,'viewer_preferences',vp.raw_payload,'target_answers',ta.raw_payload,
    'revision_ids',jsonb_build_object('viewer_answers',va.revision_id,'viewer_preferences',vp.revision_id,'target_answers',ta.revision_id),
    'capture_semantics',vp.semantics_version::jsonb,
    'fingerprints',jsonb_build_object('viewer_answers',va.fingerprint,'viewer_preferences',vp.fingerprint,'target_answers',ta.fingerprint,'manifest',expected_fingerprint));
  RETURN s2_private.calculate_bundle(p_viewer,p_target,bundle);
END $$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA s2_private FROM PUBLIC;
RESET ROLE;
