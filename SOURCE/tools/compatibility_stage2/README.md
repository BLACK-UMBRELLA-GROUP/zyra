---
id: DOC-ZYRA-0128
type: GUIDE
status: CURRENT
feature: CODE AND TOOLS
purpose: Compatibility Stage 2 — isolated synthetic server candidate
links: []
owner: ZYRA chat
---

# Compatibility Stage 2 — isolated synthetic server candidate

Founder execution authority: direct **“no proceed with execution”**, 2026-09-28,
following the Stage 2 outline. This authorises this local candidate only, not
production, Flutter integration, real data/credentials, real spending or Plus
activation. The Founder separately authorised the specifically requested
official PostgreSQL/VM downloads with **“do whats next”** on 2026-09-28.

## Boundaries

New research files live only under this directory. Existing app, metadata,
Stage 1 files, dependencies and historical migrations are not changed. The
runner verifies the 45 Stage 1/runtime source hash anchors before/after tests.
No `.env`, credential directory, remote project, Supabase stack or main DB is
loaded. Ordinary synthetic database logins—not administrator calls—exercise
the purchase interfaces. PostgreSQL session identity is only a local trusted
principal simulation; JWT signature/gateway equivalence is not claimed.

Runtime target: dedicated `zyra-compat-stage2` Colima profile, explicit Unix
socket, `zyra-compat-stage2-db` container and `zyra_compat_stage2_research` DB.
Container network is `none`, no host port or host directory is published,
PostgreSQL listens only on its internal Unix socket. A pinned official image
must already be present: the runner does not pull/install/start a VM.

Installed Colima 0.10.3/Lima 2.2.0 did not honour the intended isolation solely
from `--port-forwarder none`: its generated ignore rule missed loopback guest
DNS listeners. The exact new instance was stopped, its task-only Lima rule
reviewed and corrected to `guestIP: 0.0.0.0`, `guestIPMustBeZero: false`,
`guestPortRange: [1,65535]`, `proto: any`, `ignore: true`. The task-only disk
restart provisioner was made non-formatting and label-checked. No global Lima
configuration, firewall or unrelated profile was modified. `setup`/`test` now
inspect the owned hostagent process, configuration and actual network sockets;
they refuse wildcard listeners and missing all-interface ignore rules.

`acquire_runtime.rb` is the separately authorised acquisition entry point,
not part of setup. It refuses existing profiles and stops its newly requested
instance on failed isolation. Fresh generation on these installed versions
needs the same task-only configuration review; do not bypass the guard.
Restart the reviewed existing task instance only with the exact Lima instance
name and `LIMA_HOME=/Users/shakeelahmad/.colima/_lima`; `colima start` may
regenerate the inadequate configuration. No project `.env` is sourced.

## Model

Immutable validated input revisions and immutable calculation records are
separate from one stable directional current binding, permanent tier
entitlements, current access guards, pinned disclosure policy and financial
operation receipts. Whole transactions use SERIALIZABLE with deterministic
locks and bounded retries. Retried financial outcomes never bypass fresh
access or return retired private payloads. Private failed candidates do not
become client-visible saved results or indefinite evidence archives.

All category bands/usefulness predicates, fake credit prices, finite sect
vocabularies and lifecycle fixtures are explicitly synthetic research
configuration. They do not choose product thresholds, production prices,
retention periods or identity/deletion policy. The default Plus gate is off;
only privileged fixture setup may enable it. Presentation demo data has no
real purchase path.

Technical repair is a separate privileged, audited, free operation using
captured original evidence. Missing evidence returns unavailable/review; no
fresh-input substitution or user refresh. Retention tests exercise limited
mechanics without approving retention periods or indefinite payload history.
Evidence-bundle purge does not erase retained raw semantic revisions or
replaced snapshot aggregates; audit/operation references also constrain
deletion. Complete retention/deletion mechanics are an unfinished gate.

## Entry points

After separate runtime acquisition/isolation checks, use the exact absolute
runner path with `baseline`, `setup`, `inspect`, `test`, `teardown`. Each mode
guards the fixed target; `setup` refuses name collisions. Teardown deletes
only the run-labelled synthetic container and volume. VM teardown is a
separate verified root operation, not a global Docker prune.

`export_stage1.dart` reads existing pure Stage 1 metadata/fixtures and emits
synthetic inputs/manifest; no app state or real identities are read.
`tests/harness.rb` records independently executed named tests, failures and
explicit pending gates. Concurrency uses independent client sessions and
privileged fixture instrumentation, never client-supplied bypass flags.

`ruby tests/runner_checks.rb --evidence` runs only database-free runner guards,
Ruby syntax, the exporter/analyzer and protected-source hash checks. It writes
point-in-time static evidence. Mocked inspection refusals are not effective
database grants or runtime isolation proof. The database inventory contains
124 named cases: 108 SQL/harness handlers, five root actual-runtime inspections
and eleven explicit later integration/privacy gates. Authored counts are not
passing counts; consult timestamped run evidence for observed outcomes.

The later transport must withhold any calculation body until successful
transaction commit, discard output on serialization failure, retry the whole
operation (same idempotency key), and recheck access on recovery. Local psql
harness buffering models this; a real JWT/API gateway is not proved here.

## Evidence and authority

Run JSON evidence is generated in the ZYRA reviews directory with timestamped
non-overwriting names. SQL/catalog/race evidence proves only this candidate.
Production grants, capture/JWT/ledger integration, full privacy/distribution
research, disclosure/retention decisions, migrations and rollout are later
separate gates. Findings use OA-ZYRA-193/192/226/227/230/283/284/285; no action
is closed by local tests. Current policy is DR-ZYRA-250 under AD-AIOS-111.

No test count, code-complete or handover-complete claim is made until the run
is measured and the as-built handover is filed. Internal verification is not
Founder acceptance.
