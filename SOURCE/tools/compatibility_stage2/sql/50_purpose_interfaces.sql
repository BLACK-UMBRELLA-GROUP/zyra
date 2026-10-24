-- LOCAL SYNTHETIC RESEARCH ONLY. Not a production migration or public API.
-- Subject identity is SESSION_USER mapped by privileged fixture setup.
-- No JWT verification, production permission or privacy claim is made here.

CREATE FUNCTION s2_private.require_serializable() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'Stage 2 mutations require an explicit SERIALIZABLE transaction'
      USING ERRCODE = '25001';
  END IF;
END;
$$;

CREATE FUNCTION s2_private.access_allowed(p_viewer text, p_target text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
  SELECT p_viewer IS NOT NULL AND p_target IS NOT NULL AND p_viewer <> p_target
    AND EXISTS (SELECT 1 FROM s2_private.subjects v
      WHERE v.subject_id = p_viewer AND v.status = 'active' AND NOT v.demo_only
        AND v.account_kind = 'seeker')
    AND EXISTS (SELECT 1 FROM s2_private.subjects t
      WHERE t.subject_id = p_target AND t.status = 'active' AND t.visible AND NOT t.demo_only
        AND t.account_kind = 'seeker')
    AND NOT EXISTS (SELECT 1 FROM s2_private.pair_access a
      WHERE ((a.viewer = p_viewer AND a.target = p_target)
        OR (a.viewer = p_target AND a.target = p_viewer))
        AND (a.blocked OR a.safety_restricted));
$$;

CREATE FUNCTION s2_private.lock_access(p_viewer text, p_target text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
BEGIN
  -- Every fixture restriction/input writer takes these guards in this order.
  -- At SERIALIZABLE a stale guarded row causes a whole-transaction retry.
  PERFORM s.subject_id FROM s2_private.subjects s
    WHERE s.subject_id IN (p_viewer, p_target)
    ORDER BY s.subject_id FOR UPDATE;
  RETURN s2_private.access_allowed(p_viewer, p_target);
END;
$$;

CREATE FUNCTION s2_private.journey_allowed(p_viewer text, p_target text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM s2_private.journeys j
    WHERE j.viewer = p_viewer AND j.target = p_target
      AND j.stage IN ('reveal', 'revealed') AND j.mutual_reveal
      AND j.reveal_permitted AND j.attempt_id IS NOT NULL);
$$;

CREATE FUNCTION s2_private.guardian_projection(p_target text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE g s2_private.guardians%ROWTYPE;
BEGIN
  SELECT * INTO g FROM s2_private.guardians WHERE target = p_target;
  IF NOT FOUND OR g.lookup_state = 'unavailable' THEN
    RETURN jsonb_build_object('state', 'unavailable');
  ELSIF g.lookup_state = 'unlinked' THEN
    RETURN jsonb_build_object('state', 'unlinked');
  END IF;
  RETURN jsonb_build_object('state', 'linked', 'first_name', g.first_name,
    'relationship', g.relationship, 'city', g.city, 'main', g.is_main);
END;
$$;

CREATE FUNCTION s2_private.synthetic_projection(p_result jsonb, p_allowed text[])
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE
  category text;
  output jsonb := '[]'::jsonb;
  useful integer := 0;
BEGIN
  -- Uniform symbolic bands test projection/transaction mechanics only.
  -- There are no real band names, percentage cutoffs or privacy thresholds.
  FOREACH category IN ARRAY ARRAY[
    'deen_practice', 'marriage_intentions', 'children_parenting',
    'family_in_laws', 'finances_provision', 'education_career',
    'home_roles', 'communication_conflict', 'personality_connection',
    'lifestyle_wellbeing', 'digital_boundaries', 'culture_language']
  LOOP
    IF category = ANY(coalesce(p_allowed, ARRAY[]::text[]))
       AND coalesce((p_result -> 'categories' -> category ->> 'available')::integer, 0) > 0 THEN
      useful := useful + 1;
      output := output || jsonb_build_array(jsonb_build_object(
        'category', category, 'band', 'synthetic_band'));
    ELSE
      output := output || jsonb_build_array(jsonb_build_object(
        'category', category, 'band', 'unavailable'));
    END IF;
  END LOOP;
  -- Useful count is private preflight metadata, never an ordinary projection.
  RETURN jsonb_build_object('projection', jsonb_build_object('categories', output),
    'useful_count', useful);
END;
$$;

CREATE FUNCTION s2_private.project_result(p_viewer text, p_target text, p_purpose text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE
  b s2_private.pair_bindings%ROWTYPE;
  snap s2_private.snapshots%ROWTYPE;
  disclosure s2_private.disclosure_bindings%ROWTYPE;
  percentage integer;
BEGIN
  IF NOT s2_private.access_allowed(p_viewer, p_target) THEN
    RETURN jsonb_build_object('state', 'forbidden');
  END IF;
  IF p_purpose = 'browse' THEN
    -- This contract prototype does not approve a production curation algorithm.
    RETURN jsonb_build_object('state', 'success', 'visible', true);
  ELSIF p_purpose = 'journey' THEN
    IF NOT s2_private.journey_allowed(p_viewer, p_target) THEN
      RETURN jsonb_build_object('state', 'forbidden');
    END IF;
  ELSIF p_purpose = 'standard' THEN
    IF NOT EXISTS (SELECT 1 FROM s2_private.entitlements
      WHERE viewer = p_viewer AND target = p_target AND tier IN ('standard', 'plus')) THEN
      RETURN jsonb_build_object('state', 'forbidden');
    END IF;
  ELSIF p_purpose = 'plus' THEN
    IF NOT EXISTS (SELECT 1 FROM s2_private.entitlements
      WHERE viewer = p_viewer AND target = p_target AND tier = 'plus') THEN
      RETURN jsonb_build_object('state', 'forbidden');
    END IF;
  ELSE
    RETURN jsonb_build_object('state', 'forbidden');
  END IF;

  SELECT * INTO b FROM s2_private.pair_bindings
    WHERE viewer = p_viewer AND target = p_target;
  IF NOT FOUND OR b.current_snapshot_id IS NULL THEN
    RETURN jsonb_build_object('state', 'recovery_required');
  END IF;
  IF b.state <> 'current' THEN
    RETURN jsonb_build_object('state', 'unavailable');
  END IF;
  SELECT * INTO snap FROM s2_private.snapshots
    WHERE snapshot_id = b.current_snapshot_id AND viewer = p_viewer AND target = p_target;
  IF NOT FOUND OR snap.state <> 'success' OR snap.available <= 0 OR snap.earned_d <= 0 THEN
    RETURN jsonb_build_object('state', 'unavailable');
  END IF;

  -- Exact nonnegative rational half-up rounding, without floating point.
  percentage := div(200 * snap.earned_n + snap.earned_d * snap.available,
    2 * snap.earned_d * snap.available)::integer;
  IF p_purpose <> 'plus' THEN
    RETURN jsonb_build_object('state', 'success', 'overall_percentage', percentage);
  END IF;
  SELECT * INTO disclosure FROM s2_private.disclosure_bindings
    WHERE viewer = p_viewer AND target = p_target;
  IF NOT FOUND OR disclosure.snapshot_id <> b.current_snapshot_id
     OR disclosure.projection ->> 'state' = 'unavailable' THEN
    RETURN jsonb_build_object('state', 'unavailable');
  END IF;
  RETURN jsonb_build_object('state', 'success', 'overall_percentage', percentage,
    'projection', disclosure.projection,
    'guardian', s2_private.guardian_projection(p_target));
END;
$$;

CREATE FUNCTION s2_api.read_result(p_target text, p_purpose text DEFAULT 'standard')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE actor text := s2_private.current_actor();
BEGIN
  IF NOT s2_private.lock_access(actor, p_target) THEN
    RETURN jsonb_build_object('state', 'forbidden');
  END IF;
  -- Reads do not create bindings, entitlements, operations, wallets or Journey flags.
  RETURN s2_private.project_result(actor, p_target, p_purpose);
END;
$$;

ALTER FUNCTION s2_private.require_serializable() OWNER TO s2_owner;
ALTER FUNCTION s2_private.access_allowed(text, text) OWNER TO s2_owner;
ALTER FUNCTION s2_private.lock_access(text, text) OWNER TO s2_owner;
ALTER FUNCTION s2_private.journey_allowed(text, text) OWNER TO s2_owner;
ALTER FUNCTION s2_private.guardian_projection(text) OWNER TO s2_owner;
ALTER FUNCTION s2_private.synthetic_projection(jsonb, text[]) OWNER TO s2_owner;
ALTER FUNCTION s2_private.project_result(text, text, text) OWNER TO s2_owner;
ALTER FUNCTION s2_api.read_result(text, text) OWNER TO s2_owner;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA s2_private FROM PUBLIC;
REVOKE ALL ON FUNCTION s2_api.read_result(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION s2_api.read_result(text, text) TO s2_authenticated;
