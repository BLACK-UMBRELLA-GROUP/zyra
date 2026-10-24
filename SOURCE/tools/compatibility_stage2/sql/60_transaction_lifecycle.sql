-- LOCAL SYNTHETIC RESEARCH ONLY. No store, real balance, production spending,
-- product pricing, upgrade rule, or production activation is authorised here.

CREATE FUNCTION s2_private.operation_receipt(p_operation bigint)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
  SELECT jsonb_build_object('operation_id', o.operation_id, 'state', o.state,
    'debit_entry_id', (SELECT entry_id FROM s2_private.ledger l
      WHERE l.operation_id = o.operation_id AND l.kind = 'debit'))
  FROM s2_private.operations o WHERE o.operation_id = p_operation;
$$;

CREATE FUNCTION s2_private.reject_operation(p_operation bigint, p_state text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE response jsonb := jsonb_build_object('state', p_state);
BEGIN
  UPDATE s2_private.operations SET state = 'rejected', outcome = response
    WHERE operation_id = p_operation AND state = 'pending';
  RETURN response;
END;
$$;

CREATE FUNCTION s2_private.public_calculation_failure(p_state text)
RETURNS text LANGUAGE sql IMMUTABLE
SET search_path = pg_catalog, s2_private, pg_temp AS $$
  SELECT CASE p_state
    WHEN 'owner_repair' THEN 'repair_required'
    WHEN 'configuration_failure' THEN 'system_failure'
    ELSE 'unavailable' END;
$$;

-- Research contract identity, not a refresh trigger. Capture the definitions of
-- the trusted calculator and every transitive private validation/arithmetic
-- helper from the same transaction snapshot as the committed calculation.
CREATE FUNCTION s2_private.scoring_provenance()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE
  helper_names text[] := ARRAY['calculate_bundle', 'calculate', 'validate_manifest',
    'validate_answers', 'validate_preferences', 'light_map', 'field_map',
    'options', 'semantics', 'exact_keys', 'canonical_json', 'gcd_numeric',
    'fraction_add', 'object_length', 'invalid'];
  helper_count integer;
  distinct_count integer;
  definition_bundle jsonb;
BEGIN
  SELECT count(*), count(DISTINCT p.proname),
    jsonb_agg(jsonb_build_array(
      format('%I.%I(%s)', n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)),
      pg_get_functiondef(p.oid))
      ORDER BY format('%I.%I(%s)', n.nspname, p.proname,
        pg_get_function_identity_arguments(p.oid)) COLLATE "C")
    INTO helper_count, distinct_count, definition_bundle
    FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 's2_private' AND p.prokind = 'f' AND p.proname = ANY(helper_names);
  IF helper_count <> cardinality(helper_names) OR distinct_count <> cardinality(helper_names) THEN
    RAISE EXCEPTION 'candidate scoring definitions are incomplete or ambiguous' USING ERRCODE = '55000';
  END IF;
  RETURN jsonb_build_object('scoring_contract', 'stage2-local-question-unit-rational-v1',
    'scoring_code_fingerprint', encode(sha256(convert_to(definition_bundle::text, 'UTF8')), 'hex'));
END;
$$;

CREATE FUNCTION s2_private.commit_initial_snapshot(p_viewer text, p_target text, p_candidate jsonb)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE new_id bigint;
DECLARE bundle jsonb := p_candidate -> 'evidence_bundle';
DECLARE fingerprint text;
DECLARE trusted_versions jsonb;
BEGIN
  IF p_candidate ->> 'state' <> 'success' OR bundle IS NULL THEN
    RAISE EXCEPTION 'cannot commit unvalidated candidate' USING ERRCODE = '55000';
  END IF;
  fingerprint := encode(sha256(convert_to(bundle::text, 'UTF8')), 'hex');
  -- Server-owned pins override any candidate-supplied provenance fields.
  trusted_versions := (p_candidate -> 'versions') || s2_private.scoring_provenance() ||
    jsonb_build_object('evidence_fingerprint', fingerprint);
  INSERT INTO s2_private.snapshots(viewer, target, earned_n, earned_d,
    available, categories, versions, input_revision_ids, result)
  VALUES(p_viewer, p_target, (p_candidate ->> 'earned_n')::numeric,
    (p_candidate ->> 'earned_d')::numeric, (p_candidate ->> 'available')::integer,
    p_candidate -> 'categories', trusted_versions,
    p_candidate -> 'input_revision_ids', (p_candidate - 'evidence_bundle') ||
      jsonb_build_object('versions', trusted_versions))
  RETURNING snapshot_id INTO new_id;
  INSERT INTO s2_private.input_evidence(snapshot_id, bundle)
    VALUES(new_id, jsonb_build_object('payload', bundle, 'fingerprint', fingerprint));
  UPDATE s2_private.pair_bindings SET current_snapshot_id = new_id,
    state = 'current', legacy_state = 'validated', revision = revision + 1
    WHERE viewer = p_viewer AND target = p_target;
  RETURN new_id;
END;
$$;

CREATE FUNCTION s2_private.operate(p_target text, p_purpose text, p_tier text, p_key text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE
  v_actor text := s2_private.current_actor();
  op s2_private.operations%ROWTYPE;
  binding s2_private.pair_bindings%ROWTYPE;
  config s2_private.configuration%ROWTYPE;
  candidate jsonb;
  disclosure jsonb;
  response jsonb;
  fingerprint text := encode(sha256(convert_to(
    jsonb_build_array(p_purpose, p_target, p_tier)::text, 'UTF8')), 'hex');
  existing_tier boolean := false;
  paid boolean := false;
  price integer := 0;
  wallet_balance integer;
  snapshot bigint;
BEGIN
  PERFORM s2_private.require_serializable();
  IF v_actor IS NULL OR p_key IS NULL OR length(p_key) NOT BETWEEN 1 AND 160
    OR p_purpose NOT IN ('purchase', 'legacy', 'journey')
    OR (p_purpose = 'purchase' AND coalesce(p_tier, '') NOT IN ('standard', 'plus'))
    OR (p_purpose <> 'purchase' AND p_tier IS NOT NULL) THEN
    RETURN jsonb_build_object('state', 'forbidden');
  END IF;

  -- Subject guards precede every wallet, operation, binding and input lock.
  -- A retry never returns the sensitive body stored in an old response.
  IF NOT s2_private.lock_access(v_actor, p_target) THEN
    SELECT * INTO op FROM s2_private.operations
      WHERE operations.actor = v_actor AND idempotency_key = p_key;
    IF FOUND AND op.state = 'committed' AND op.target = p_target
      AND op.purpose = p_purpose AND op.tier IS NOT DISTINCT FROM p_tier THEN
      RETURN jsonb_build_object('state', 'forbidden', 'receipt',
        s2_private.operation_receipt(op.operation_id));
    END IF;
    RETURN jsonb_build_object('state', 'forbidden');
  END IF;
  SELECT * INTO config FROM s2_private.configuration WHERE id = 1 FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('state', 'system_failure'); END IF;

  SELECT EXISTS (SELECT 1 FROM s2_private.entitlements
    WHERE viewer = v_actor AND target = p_target AND
      (tier = p_tier OR (p_tier = 'standard' AND tier = 'plus')))
    INTO existing_tier;
  paid := p_purpose = 'purchase' AND NOT existing_tier;
  IF paid THEN
    SELECT balance INTO wallet_balance FROM s2_private.wallets
      WHERE wallets.actor = v_actor FOR UPDATE;
    price := CASE p_tier WHEN 'plus' THEN config.plus_price ELSE config.standard_price END;
  END IF;

  -- The actor/key reservation cannot be forged by client-supplied viewer IDs.
  SELECT * INTO op FROM s2_private.operations
    WHERE operations.actor = v_actor AND idempotency_key = p_key FOR UPDATE;
  IF FOUND THEN
    IF op.target <> p_target OR op.purpose <> p_purpose
      OR op.tier IS DISTINCT FROM p_tier OR op.request_hash <> fingerprint THEN
      RETURN jsonb_build_object('state', 'conflict');
    END IF;
    IF op.state = 'committed' THEN
      response := s2_private.project_result(v_actor, p_target,
        CASE p_purpose WHEN 'purchase' THEN p_tier WHEN 'journey' THEN 'journey'
          ELSE CASE WHEN EXISTS (SELECT 1 FROM s2_private.entitlements
            WHERE viewer = v_actor AND target = p_target AND tier = 'plus')
            THEN 'plus' ELSE 'standard' END END);
      RETURN response || jsonb_build_object('receipt', s2_private.operation_receipt(op.operation_id));
    ELSIF op.state = 'rejected' THEN
      -- A necessary repair may be attempted with a new operation key, without
      -- spending again. The outcome of this specific rejected attempt is stable.
      RETURN coalesce(op.outcome, jsonb_build_object('state', 'system_failure'));
    ELSE
      RETURN jsonb_build_object('state', 'recovery_required');
    END IF;
  END IF;
  INSERT INTO s2_private.operations(actor, idempotency_key, purpose, target, tier, request_hash)
    VALUES(v_actor, p_key, p_purpose, p_target, p_tier, fingerprint) RETURNING * INTO op;

  INSERT INTO s2_private.pair_bindings(viewer, target)
    VALUES(v_actor, p_target) ON CONFLICT DO NOTHING;
  SELECT * INTO binding FROM s2_private.pair_bindings
    WHERE viewer = v_actor AND target = p_target FOR UPDATE;
  PERFORM tier FROM s2_private.entitlements
    WHERE viewer = v_actor AND target = p_target ORDER BY tier FOR UPDATE;

  IF p_purpose = 'journey' AND NOT s2_private.journey_allowed(v_actor, p_target) THEN
    RETURN s2_private.reject_operation(op.operation_id, 'forbidden');
  END IF;
  IF p_purpose = 'legacy' AND NOT EXISTS (SELECT 1 FROM s2_private.entitlements
    WHERE viewer = v_actor AND target = p_target) THEN
    RETURN s2_private.reject_operation(op.operation_id, 'forbidden');
  END IF;
  IF paid AND (EXISTS (SELECT 1 FROM s2_private.operations previous
    WHERE previous.actor = v_actor AND previous.target = p_target
      AND previous.purpose = 'purchase' AND previous.state = 'committed'
      AND (previous.tier = p_tier OR (p_tier = 'standard' AND previous.tier = 'plus')))
    OR (p_tier = 'plus' AND EXISTS (SELECT 1 FROM s2_private.disclosure_bindings
      WHERE viewer = v_actor AND target = p_target))) THEN
    -- Missing ownership beside a successful prior purchase/projection is a
    -- recovery fault, not permission to buy the permanent entitlement again.
    RETURN s2_private.reject_operation(op.operation_id, 'recovery_required');
  END IF;
  IF paid AND p_tier = 'plus' AND NOT config.plus_enabled THEN
    RETURN s2_private.reject_operation(op.operation_id, 'plus_disabled');
  END IF;
  IF paid AND (wallet_balance IS NULL OR wallet_balance < price) THEN
    RETURN s2_private.reject_operation(op.operation_id, 'insufficient_credit');
  END IF;
  IF binding.state = 'unavailable' THEN
    RETURN s2_private.reject_operation(op.operation_id, 'unavailable');
  END IF;
  IF binding.current_snapshot_id IS NULL AND binding.legacy_state = 'validated' THEN
    -- Loss/purge of an already validated binding is not permission to refresh.
    RETURN s2_private.reject_operation(op.operation_id, 'unavailable');
  END IF;
  IF existing_tier AND p_purpose = 'purchase' AND binding.current_snapshot_id IS NULL THEN
    RETURN s2_private.reject_operation(op.operation_id, 'recovery_required');
  END IF;

  snapshot := binding.current_snapshot_id;
  IF snapshot IS NULL THEN
    PERFORM subject_id FROM s2_private.input_heads
      WHERE subject_id IN (v_actor, p_target) ORDER BY subject_id, kind FOR UPDATE;
    candidate := s2_private.calculate(v_actor, p_target);
    IF candidate ->> 'state' <> 'success' THEN
      RETURN s2_private.reject_operation(op.operation_id,
        s2_private.public_calculation_failure(candidate ->> 'state'));
    END IF;
  ELSE
    SELECT result INTO candidate FROM s2_private.snapshots
      WHERE snapshot_id = snapshot AND viewer = v_actor AND target = p_target;
    IF NOT FOUND THEN
      RETURN s2_private.reject_operation(op.operation_id, 'unavailable');
    END IF;
  END IF;

  IF (p_purpose = 'purchase' AND p_tier = 'plus') OR
    (p_purpose = 'legacy' AND EXISTS (SELECT 1 FROM s2_private.entitlements
      WHERE viewer = v_actor AND target = p_target AND tier = 'plus')) THEN
    SELECT projection INTO disclosure FROM s2_private.disclosure_bindings
      WHERE viewer = v_actor AND target = p_target;
    IF NOT FOUND THEN
      disclosure := s2_private.synthetic_projection(candidate, config.allowed_categories);
      IF paid AND (disclosure ->> 'useful_count')::integer < config.min_categories THEN
        RETURN s2_private.reject_operation(op.operation_id, 'unavailable');
      END IF;
    ELSE
      disclosure := NULL; -- Existing pinned policy/projection is never replaced.
    END IF;
  END IF;

  -- All commit predicates are checked while the shared guards remain held.
  IF NOT s2_private.access_allowed(v_actor, p_target) THEN
    RETURN s2_private.reject_operation(op.operation_id, 'forbidden');
  END IF;
  IF snapshot IS NULL THEN
    snapshot := s2_private.commit_initial_snapshot(v_actor, p_target, candidate);
  END IF;
  IF disclosure IS NOT NULL THEN
    INSERT INTO s2_private.disclosure_bindings(viewer, target, policy_version, projection, snapshot_id)
      VALUES(v_actor, p_target, config.policy_version, disclosure -> 'projection', snapshot);
  END IF;
  IF p_purpose = 'purchase' AND NOT existing_tier THEN
    INSERT INTO s2_private.entitlements(viewer, target, tier, operation_id)
      VALUES(v_actor, p_target, p_tier, op.operation_id);
  END IF;
  IF paid THEN
    UPDATE s2_private.wallets SET balance = balance - price
      WHERE wallets.actor = v_actor AND balance >= price;
    IF NOT FOUND THEN RAISE EXCEPTION 'guarded wallet unavailable' USING ERRCODE = '40001'; END IF;
    INSERT INTO s2_private.ledger(actor, operation_id, amount, kind)
      VALUES(v_actor, op.operation_id, -price, 'debit');
  END IF;
  UPDATE s2_private.operations SET state = 'committed', snapshot_id = snapshot,
    outcome = jsonb_build_object('state', 'committed', 'charged', paid)
    WHERE operation_id = op.operation_id;

  response := s2_private.project_result(v_actor, p_target,
    CASE p_purpose WHEN 'purchase' THEN p_tier WHEN 'journey' THEN 'journey'
      ELSE CASE WHEN EXISTS (SELECT 1 FROM s2_private.entitlements
        WHERE viewer = v_actor AND target = p_target AND tier = 'plus')
        THEN 'plus' ELSE 'standard' END END);
  RETURN response || jsonb_build_object('receipt', s2_private.operation_receipt(op.operation_id));
END;
$$;

CREATE FUNCTION s2_api.purchase(p_target text, p_tier text, p_key text)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
  SELECT s2_private.operate(p_target, 'purchase', p_tier, p_key);
$$;

CREATE FUNCTION s2_api.legacy_transition(p_target text, p_key text)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
  SELECT s2_private.operate(p_target, 'legacy', NULL, p_key);
$$;

CREATE FUNCTION s2_api.reveal_journey(p_target text, p_key text)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
  SELECT s2_private.operate(p_target, 'journey', NULL, p_key);
$$;

ALTER FUNCTION s2_private.operation_receipt(bigint) OWNER TO s2_owner;
ALTER FUNCTION s2_private.reject_operation(bigint, text) OWNER TO s2_owner;
ALTER FUNCTION s2_private.public_calculation_failure(text) OWNER TO s2_owner;
ALTER FUNCTION s2_private.scoring_provenance() OWNER TO s2_owner;
ALTER FUNCTION s2_private.commit_initial_snapshot(text, text, jsonb) OWNER TO s2_owner;
ALTER FUNCTION s2_private.operate(text, text, text, text) OWNER TO s2_owner;
ALTER FUNCTION s2_api.purchase(text, text, text) OWNER TO s2_owner;
ALTER FUNCTION s2_api.legacy_transition(text, text) OWNER TO s2_owner;
ALTER FUNCTION s2_api.reveal_journey(text, text) OWNER TO s2_owner;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA s2_private FROM PUBLIC;
REVOKE ALL ON FUNCTION s2_api.purchase(text, text, text),
  s2_api.legacy_transition(text, text), s2_api.reveal_journey(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION s2_api.purchase(text, text, text),
  s2_api.legacy_transition(text, text), s2_api.reveal_journey(text, text) TO s2_authenticated;
