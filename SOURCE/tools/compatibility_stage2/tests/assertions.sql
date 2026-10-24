-- Admin fixture assertions only. Ordinary clients get no test-helper grants.
\set ON_ERROR_STOP on
CREATE FUNCTION s2_fixture.assert_true(p_condition boolean,p_label text) RETURNS void
LANGUAGE plpgsql SET search_path=pg_catalog,pg_temp AS $$
BEGIN
  IF p_condition IS DISTINCT FROM true THEN RAISE EXCEPTION 'assertion failed: %',p_label USING ERRCODE='P0001'; END IF;
END $$;
REVOKE ALL ON FUNCTION s2_fixture.assert_true(boolean,text) FROM PUBLIC,s2_authenticated,s2_anon;

CREATE FUNCTION s2_fixture.stats(p_viewer text,p_target text) RETURNS jsonb
LANGUAGE sql SET search_path=pg_catalog,s2_private,pg_temp AS $$
  SELECT jsonb_build_object(
    'snapshots',(SELECT count(*) FROM s2_private.snapshots WHERE viewer=p_viewer AND target=p_target),
    'bindings',(SELECT count(*) FROM s2_private.pair_bindings WHERE viewer=p_viewer AND target=p_target),
    'current_snapshot_id',(SELECT current_snapshot_id FROM s2_private.pair_bindings WHERE viewer=p_viewer AND target=p_target),
    'binding_state',(SELECT state FROM s2_private.pair_bindings WHERE viewer=p_viewer AND target=p_target),
    'entitlements',(SELECT count(*) FROM s2_private.entitlements WHERE viewer=p_viewer AND target=p_target),
    'debits',(SELECT count(*) FROM s2_private.ledger l JOIN s2_private.operations o USING(operation_id) WHERE l.kind='debit' AND o.actor=p_viewer AND o.target=p_target),
    'debit_total',(SELECT coalesce(sum(-l.amount),0) FROM s2_private.ledger l JOIN s2_private.operations o USING(operation_id) WHERE l.kind='debit' AND o.actor=p_viewer AND o.target=p_target),
    'balance',(SELECT balance FROM s2_private.wallets WHERE actor=p_viewer),
    'ledger_balance',(SELECT coalesce(sum(amount),0) FROM s2_private.ledger WHERE actor=p_viewer),
    'policy',(SELECT policy_version FROM s2_private.disclosure_bindings WHERE viewer=p_viewer AND target=p_target),
    'evidence_rows',(SELECT count(*) FROM s2_private.input_evidence e JOIN s2_private.snapshots s USING(snapshot_id) WHERE s.viewer=p_viewer AND s.target=p_target),
    'repair_rows',(SELECT count(*) FROM s2_private.repair_audit WHERE viewer=p_viewer AND target=p_target));
$$;
REVOKE ALL ON FUNCTION s2_fixture.stats(text,text) FROM PUBLIC,s2_authenticated,s2_anon;
