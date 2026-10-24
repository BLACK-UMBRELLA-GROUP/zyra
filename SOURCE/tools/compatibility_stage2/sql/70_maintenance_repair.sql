-- PRIVILEGED LOCAL FIXTURE/MAINTENANCE ONLY. Not production support tooling.
-- No ordinary client grants, test flags, magic users or real credit operation.
GRANT USAGE ON SCHEMA s2_fixture TO s2_owner, s2_maintenance;

CREATE FUNCTION s2_fixture.set_access(p_viewer text, p_target text,
  p_blocked boolean, p_safety_restricted boolean DEFAULT false)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
BEGIN
  PERFORM s2_private.require_serializable();
  PERFORM subject_id FROM s2_private.subjects WHERE subject_id IN (p_viewer, p_target)
    ORDER BY subject_id FOR UPDATE;
  -- A lock alone does not invalidate an older SERIALIZABLE snapshot. Writing
  -- the shared guard forces a stale waiter to retry before reading restrictions.
  UPDATE s2_private.subjects SET revision = revision + 1
    WHERE subject_id IN (p_viewer, p_target);
  INSERT INTO s2_private.pair_access(viewer, target, blocked, safety_restricted)
    VALUES(p_viewer, p_target, p_blocked, p_safety_restricted)
    ON CONFLICT (viewer, target) DO UPDATE SET blocked = excluded.blocked,
      safety_restricted = excluded.safety_restricted, revision = pair_access.revision + 1;
END;
$$;

CREATE FUNCTION s2_fixture.set_subject(p_subject text, p_status text, p_visible boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
BEGIN
  PERFORM s2_private.require_serializable();
  PERFORM subject_id FROM s2_private.subjects WHERE subject_id = p_subject FOR UPDATE;
  UPDATE s2_private.subjects SET status = p_status, visible = p_visible,
    revision = revision + 1 WHERE subject_id = p_subject;
END;
$$;

CREATE FUNCTION s2_fixture.set_plus_gate(p_enabled boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
BEGIN
  PERFORM s2_private.require_serializable();
  UPDATE s2_private.configuration SET plus_enabled = p_enabled, revision = revision + 1 WHERE id = 1;
END;
$$;

CREATE FUNCTION s2_fixture.grant_credit(p_actor text, p_amount integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
BEGIN
  PERFORM s2_private.require_serializable();
  IF p_amount <= 0 THEN RAISE EXCEPTION 'positive synthetic grant required'; END IF;
  PERFORM subject_id FROM s2_private.subjects WHERE subject_id = p_actor FOR UPDATE;
  INSERT INTO s2_private.wallets(actor, balance) VALUES(p_actor, 0) ON CONFLICT DO NOTHING;
  PERFORM actor FROM s2_private.wallets WHERE actor = p_actor FOR UPDATE;
  UPDATE s2_private.wallets SET balance = balance + p_amount WHERE actor = p_actor;
  INSERT INTO s2_private.ledger(actor, amount, kind) VALUES(p_actor, p_amount, 'grant');
END;
$$;

CREATE FUNCTION s2_fixture.refund_credit(p_actor text, p_operation bigint)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE debit integer;
BEGIN
  PERFORM s2_private.require_serializable();
  PERFORM subject_id FROM s2_private.subjects WHERE subject_id = p_actor FOR UPDATE;
  PERFORM actor FROM s2_private.wallets WHERE actor = p_actor FOR UPDATE;
  PERFORM operation_id FROM s2_private.operations
    WHERE operation_id = p_operation AND actor = p_actor FOR UPDATE;
  SELECT amount INTO debit FROM s2_private.ledger
    WHERE actor = p_actor AND operation_id = p_operation AND kind = 'debit';
  IF NOT FOUND THEN RETURN jsonb_build_object('state', 'unavailable'); END IF;
  IF EXISTS (SELECT 1 FROM s2_private.ledger WHERE actor = p_actor
    AND operation_id = p_operation AND kind = 'refund') THEN
    RETURN jsonb_build_object('state', 'success');
  END IF;
  UPDATE s2_private.wallets SET balance = balance - debit WHERE actor = p_actor;
  IF NOT FOUND THEN RETURN jsonb_build_object('state', 'unavailable'); END IF;
  INSERT INTO s2_private.ledger(actor, operation_id, amount, kind)
    VALUES(p_actor, p_operation, -debit, 'refund');
  RETURN jsonb_build_object('state', 'success');
END;
$$;

CREATE FUNCTION s2_fixture.set_journey(p_viewer text, p_target text,
  p_stage text, p_mutual boolean, p_permitted boolean, p_attempt text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
BEGIN
  PERFORM s2_private.require_serializable();
  PERFORM subject_id FROM s2_private.subjects WHERE subject_id IN (p_viewer, p_target)
    ORDER BY subject_id FOR UPDATE;
  UPDATE s2_private.subjects SET revision = revision + 1
    WHERE subject_id IN (p_viewer, p_target);
  INSERT INTO s2_private.journeys(viewer, target, stage, mutual_reveal, reveal_permitted, attempt_id)
    VALUES(p_viewer, p_target, p_stage, p_mutual, p_permitted, p_attempt)
    ON CONFLICT (viewer, target) DO UPDATE SET stage = excluded.stage,
      mutual_reveal = excluded.mutual_reveal, reveal_permitted = excluded.reveal_permitted,
      attempt_id = excluded.attempt_id;
END;
$$;

CREATE FUNCTION s2_fixture.set_guardian(p_target text, p_first_name text,
  p_relationship text, p_city text, p_main boolean, p_lookup_state text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
BEGIN
  PERFORM s2_private.require_serializable();
  PERFORM subject_id FROM s2_private.subjects WHERE subject_id = p_target FOR UPDATE;
  UPDATE s2_private.subjects SET revision = revision + 1 WHERE subject_id = p_target;
  INSERT INTO s2_private.guardians(target, first_name, relationship, city, is_main, lookup_state)
    VALUES(p_target, p_first_name, p_relationship, p_city, p_main, p_lookup_state)
    ON CONFLICT (target) DO UPDATE SET first_name = excluded.first_name,
      relationship = excluded.relationship, city = excluded.city,
      is_main = excluded.is_main, lookup_state = excluded.lookup_state;
END;
$$;

CREATE FUNCTION s2_fixture.purge_evidence(p_snapshot bigint)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE snap s2_private.snapshots%ROWTYPE;
BEGIN
  PERFORM s2_private.require_serializable();
  SELECT * INTO snap FROM s2_private.snapshots WHERE snapshot_id = p_snapshot;
  IF NOT FOUND THEN RETURN jsonb_build_object('state', 'unavailable'); END IF;
  PERFORM subject_id FROM s2_private.subjects WHERE subject_id IN (snap.viewer, snap.target)
    ORDER BY subject_id FOR UPDATE;
  PERFORM viewer FROM s2_private.pair_bindings
    WHERE viewer = snap.viewer AND target = snap.target FOR UPDATE;
  UPDATE s2_private.input_evidence SET bundle = NULL, purged = true WHERE snapshot_id = p_snapshot;
  RETURN jsonb_build_object('state', 'success');
END;
$$;

CREATE FUNCTION s2_fixture.repair_snapshot(p_viewer text, p_target text,
  p_reason text, p_authority text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, s2_private, pg_temp AS $$
DECLARE
  binding s2_private.pair_bindings%ROWTYPE;
  original s2_private.snapshots%ROWTYPE;
  retained s2_private.input_evidence%ROWTYPE;
  candidate jsonb;
  original_bundle jsonb;
  original_fingerprint text;
  replacement_versions jsonb;
  new_id bigint;
  audit_id bigint;
BEGIN
  PERFORM s2_private.require_serializable();
  IF p_reason IS NULL OR p_reason NOT IN ('corrupted_input', 'scoring_defect', 'broken_mapping', 'system_configuration_error')
    OR p_authority IS NULL OR length(p_authority) NOT BETWEEN 1 AND 240 THEN
    RETURN jsonb_build_object('state', 'forbidden');
  END IF;
  -- The maintenance role stands in for a separately authorised local review.
  -- A reason/authority string is audit metadata, not production approval proof.
  PERFORM subject_id FROM s2_private.subjects WHERE subject_id IN (p_viewer, p_target)
    ORDER BY subject_id FOR UPDATE;
  UPDATE s2_private.subjects SET revision = revision + 1
    WHERE subject_id IN (p_viewer, p_target);
  PERFORM id FROM s2_private.configuration WHERE id = 1 FOR UPDATE;
  SELECT * INTO binding FROM s2_private.pair_bindings
    WHERE viewer = p_viewer AND target = p_target FOR UPDATE;
  IF NOT FOUND OR binding.current_snapshot_id IS NULL THEN
    RETURN jsonb_build_object('state', 'unavailable');
  END IF;
  SELECT * INTO original FROM s2_private.snapshots WHERE snapshot_id = binding.current_snapshot_id;
  SELECT * INTO retained FROM s2_private.input_evidence
    WHERE snapshot_id = binding.current_snapshot_id FOR UPDATE;
  IF NOT FOUND OR retained.purged OR retained.bundle IS NULL THEN
    UPDATE s2_private.pair_bindings SET state = 'unavailable', revision = revision + 1
      WHERE viewer = p_viewer AND target = p_target;
    INSERT INTO s2_private.repair_audit(viewer, target, old_snapshot_id, reason, authority, evidence)
      VALUES(p_viewer, p_target, binding.current_snapshot_id, p_reason, p_authority,
        jsonb_build_object('state', 'original_evidence_unavailable'));
    RETURN jsonb_build_object('state', 'unavailable');
  END IF;
  original_bundle := retained.bundle -> 'payload';
  original_fingerprint := retained.bundle ->> 'fingerprint';
  IF original_bundle IS NULL OR original_fingerprint IS NULL
    OR original_fingerprint <> encode(sha256(convert_to(original_bundle::text, 'UTF8')), 'hex')
    OR original_fingerprint IS DISTINCT FROM original.versions ->> 'evidence_fingerprint' THEN
    UPDATE s2_private.pair_bindings SET state = 'unavailable', revision = revision + 1
      WHERE viewer = p_viewer AND target = p_target;
    INSERT INTO s2_private.repair_audit(viewer, target, old_snapshot_id, reason, authority, evidence)
      VALUES(p_viewer, p_target, binding.current_snapshot_id, p_reason, p_authority,
        jsonb_build_object('state', 'original_evidence_invalid'));
    RETURN jsonb_build_object('state', 'unavailable');
  END IF;

  -- Never calculate(viewer,target): that would silently substitute current heads.
  candidate := s2_private.calculate_bundle(p_viewer, p_target, original_bundle);
  IF candidate ->> 'state' <> 'success' THEN
    UPDATE s2_private.pair_bindings SET state = 'unavailable', revision = revision + 1
      WHERE viewer = p_viewer AND target = p_target;
    INSERT INTO s2_private.repair_audit(viewer, target, old_snapshot_id, reason, authority, evidence)
      VALUES(p_viewer, p_target, binding.current_snapshot_id, p_reason, p_authority,
        jsonb_build_object('state', 'original_input_revalidation_failed'));
    RETURN jsonb_build_object('state', 'unavailable');
  END IF;
  new_id := s2_private.commit_initial_snapshot(p_viewer, p_target, candidate);
  SELECT versions INTO replacement_versions FROM s2_private.snapshots WHERE snapshot_id = new_id;
  -- Suppression is allowed; a repair is not a second, richer Plus transcript.
  UPDATE s2_private.disclosure_bindings SET snapshot_id = new_id,
    projection = jsonb_build_object('state', 'unavailable')
    WHERE viewer = p_viewer AND target = p_target;
  INSERT INTO s2_private.repair_audit(viewer, target, old_snapshot_id, new_snapshot_id,
    reason, authority, evidence)
    VALUES(p_viewer, p_target, binding.current_snapshot_id, new_id, p_reason, p_authority,
      jsonb_build_object('state', 'replaced_from_original_inputs',
        'original_evidence_fingerprint', original_fingerprint,
        'original_scoring_contract', original.versions ->> 'scoring_contract',
        'original_scoring_code_fingerprint', original.versions ->> 'scoring_code_fingerprint',
        'replacement_scoring_contract', replacement_versions ->> 'scoring_contract',
        'replacement_scoring_code_fingerprint', replacement_versions ->> 'scoring_code_fingerprint'))
      RETURNING repair_audit.audit_id INTO audit_id;
  RETURN jsonb_build_object('state', 'success', 'audit_id', audit_id);
END;
$$;

ALTER FUNCTION s2_fixture.set_access(text, text, boolean, boolean) OWNER TO s2_owner;
ALTER FUNCTION s2_fixture.set_subject(text, text, boolean) OWNER TO s2_owner;
ALTER FUNCTION s2_fixture.set_plus_gate(boolean) OWNER TO s2_owner;
ALTER FUNCTION s2_fixture.grant_credit(text, integer) OWNER TO s2_owner;
ALTER FUNCTION s2_fixture.refund_credit(text, bigint) OWNER TO s2_owner;
ALTER FUNCTION s2_fixture.set_journey(text, text, text, boolean, boolean, text) OWNER TO s2_owner;
ALTER FUNCTION s2_fixture.set_guardian(text, text, text, text, boolean, text) OWNER TO s2_owner;
ALTER FUNCTION s2_fixture.purge_evidence(bigint) OWNER TO s2_owner;
ALTER FUNCTION s2_fixture.repair_snapshot(text, text, text, text) OWNER TO s2_owner;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA s2_fixture FROM PUBLIC;
GRANT EXECUTE ON FUNCTION s2_fixture.set_access(text, text, boolean, boolean),
  s2_fixture.set_subject(text, text, boolean), s2_fixture.set_plus_gate(boolean),
  s2_fixture.grant_credit(text, integer), s2_fixture.refund_credit(text, bigint),
  s2_fixture.set_journey(text, text, text, boolean, boolean, text),
  s2_fixture.set_guardian(text, text, text, text, boolean, text),
  s2_fixture.purge_evidence(bigint), s2_fixture.repair_snapshot(text, text, text, text)
  TO s2_maintenance;
