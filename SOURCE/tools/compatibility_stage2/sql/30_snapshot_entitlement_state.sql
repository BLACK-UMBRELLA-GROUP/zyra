-- Candidate-only lifecycle and fake ledger. No real entitlement or currency.
\set ON_ERROR_STOP on
SET ROLE s2_owner;
CREATE TABLE s2_private.snapshots (
  snapshot_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  viewer text NOT NULL REFERENCES s2_private.subjects,
  target text NOT NULL REFERENCES s2_private.subjects,
  state text NOT NULL DEFAULT 'success' CHECK(state='success'),
  earned_n numeric NOT NULL CHECK(earned_n>=0 AND earned_n=trunc(earned_n)),
  earned_d numeric NOT NULL CHECK(earned_d>0 AND earned_d=trunc(earned_d)),
  available integer NOT NULL CHECK(available>0 AND earned_n<=available*earned_d),
  categories jsonb NOT NULL,
  versions jsonb NOT NULL,
  input_revision_ids jsonb NOT NULL,
  result jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  CHECK(viewer<>target), UNIQUE(snapshot_id,viewer,target)
);
CREATE TABLE s2_private.pair_bindings (
  viewer text NOT NULL REFERENCES s2_private.subjects,
  target text NOT NULL REFERENCES s2_private.subjects,
  current_snapshot_id bigint,
  state text NOT NULL DEFAULT 'empty' CHECK(state IN ('empty','current','unavailable')),
  legacy_state text NOT NULL DEFAULT 'none' CHECK(legacy_state IN ('none','pending','validated')),
  revision bigint NOT NULL DEFAULT 1,
  PRIMARY KEY(viewer,target), CHECK(viewer<>target),
  FOREIGN KEY(current_snapshot_id,viewer,target) REFERENCES s2_private.snapshots(snapshot_id,viewer,target),
  CHECK(state<>'current' OR current_snapshot_id IS NOT NULL)
);
CREATE TABLE s2_private.operations (
  operation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor text NOT NULL REFERENCES s2_private.subjects,
  idempotency_key text NOT NULL CHECK(length(idempotency_key) BETWEEN 1 AND 160),
  purpose text NOT NULL,
  target text NOT NULL REFERENCES s2_private.subjects,
  tier text CHECK(tier IN ('standard','plus')),
  request_hash text NOT NULL,
  state text NOT NULL DEFAULT 'pending' CHECK(state IN ('pending','committed','rejected')),
  outcome jsonb,
  snapshot_id bigint REFERENCES s2_private.snapshots,
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  UNIQUE(actor,idempotency_key)
);
CREATE TABLE s2_private.entitlements (
  viewer text NOT NULL REFERENCES s2_private.subjects,
  target text NOT NULL REFERENCES s2_private.subjects,
  tier text NOT NULL CHECK(tier IN ('standard','plus')),
  operation_id bigint REFERENCES s2_private.operations,
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  PRIMARY KEY(viewer,target,tier), CHECK(viewer<>target)
);
CREATE TABLE s2_private.wallets (
  actor text PRIMARY KEY REFERENCES s2_private.subjects,
  balance integer NOT NULL CHECK(balance>=0)
);
CREATE TABLE s2_private.ledger (
  entry_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor text NOT NULL REFERENCES s2_private.subjects,
  operation_id bigint REFERENCES s2_private.operations,
  amount integer NOT NULL CHECK(amount<>0),
  kind text NOT NULL CHECK(kind IN ('grant','debit','refund')),
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  CHECK((kind='debit' AND amount<0) OR (kind<>'debit' AND amount>0))
);
CREATE UNIQUE INDEX one_operation_debit ON s2_private.ledger(operation_id) WHERE kind='debit';
CREATE TABLE s2_private.disclosure_bindings (
  viewer text NOT NULL,
  target text NOT NULL,
  policy_version text NOT NULL,
  projection jsonb NOT NULL,
  snapshot_id bigint NOT NULL,
  PRIMARY KEY(viewer,target),
  FOREIGN KEY(snapshot_id,viewer,target) REFERENCES s2_private.snapshots(snapshot_id,viewer,target)
);
CREATE TABLE s2_private.input_evidence (
  snapshot_id bigint PRIMARY KEY REFERENCES s2_private.snapshots,
  bundle jsonb,
  purged boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp(),
  CHECK((purged AND bundle IS NULL) OR (NOT purged AND bundle IS NOT NULL))
);
CREATE TABLE s2_private.repair_audit (
  audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  viewer text NOT NULL,
  target text NOT NULL,
  old_snapshot_id bigint REFERENCES s2_private.snapshots,
  new_snapshot_id bigint REFERENCES s2_private.snapshots,
  authority text NOT NULL DEFAULT 'synthetic-maintenance-authority',
  reason text NOT NULL,
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT transaction_timestamp()
);
CREATE FUNCTION s2_private.deny_mutation() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog,s2_private,pg_temp AS $$
BEGIN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='immutable research record'; END $$;
CREATE TRIGGER immutable_snapshot BEFORE UPDATE ON s2_private.snapshots
FOR EACH ROW EXECUTE FUNCTION s2_private.deny_mutation();
CREATE TRIGGER append_only_ledger BEFORE UPDATE OR DELETE ON s2_private.ledger
FOR EACH ROW EXECUTE FUNCTION s2_private.deny_mutation();
CREATE TRIGGER append_only_repair_audit BEFORE UPDATE OR DELETE ON s2_private.repair_audit
FOR EACH ROW EXECUTE FUNCTION s2_private.deny_mutation();
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['snapshots','pair_bindings','operations','entitlements','wallets','ledger','disclosure_bindings','input_evidence','repair_audit'] LOOP
    EXECUTE format('ALTER TABLE s2_private.%I ENABLE ROW LEVEL SECURITY',t);
    EXECUTE format('ALTER TABLE s2_private.%I FORCE ROW LEVEL SECURITY',t);
    EXECUTE format('CREATE POLICY owner_only ON s2_private.%I TO s2_owner USING(true) WITH CHECK(true)',t);
  END LOOP;
END $$;
RESET ROLE;
