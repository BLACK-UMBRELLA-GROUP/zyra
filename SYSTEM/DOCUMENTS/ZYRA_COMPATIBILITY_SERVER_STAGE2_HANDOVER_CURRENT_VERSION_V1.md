# ZYRA — Compatibility Server Stage 2 Handover

**Version:** V1  
**Date:** 2026-09-29 (London; execution started 2026-09-28)  
**Status:** LOCAL SQL/SECURITY/TRANSACTION TESTS MEASURED; LATER INTEGRATION/PRIVACY/RETENTION GATES OPEN  
**Owner:** Codex; Founder is the sole approver  
**Authority:** AD-AIOS-111; DR-ZYRA-250; direct Stage 2 execution GO below  
**Trace:** OA-ZYRA-193/192/226/227/230/283/284/285; no action closure

## 1. Outcome and exact authority

The Founder corrected a planning-only interpretation with **“no proceed with
execution”** after the Stage 2 architecture review and outline. That direct
instruction authorises the isolated synthetic local server candidate—not a
production migration, app change, real purchase or activation. ChatGPT's review
is support evidence, not an approval or a mandatory gate.

The Founder separately answered the exact official runtime-download request
with **“do whats next”** on 2026-09-28. A new dedicated local VM and pinned
PostgreSQL 17.11 container were acquired; no existing profile was adopted.
The unrelated `zyra-oa198` profile remains stopped and untouched.

Twenty candidate files implement the unwired server prototype and test tools.
Three successful full runs, including a fresh database replay with strengthened
negative assertions, each record **112 passed, one privacy measurement and eleven
pending cases**, with no failed named tests. The final run is
`COMPATIBILITY_UNLOCK_STAGE2_RUN_20260928T230835Z.json`; passing counts are per
run, not added together. **21 separate static checks pass**, including
four Ruby syntax checks and the scoped Dart analyzer. All 45 protected
runtime/Stage 1 source hashes match. The exporter supplies 105 answer definitions,
72 preference controls and twelve categories.

This proves only the measured isolated candidate. Stage 2's broader obligations
are not all complete: real capture/JWT/app integration, complete retention,
disclosure research and later Founder decisions remain open. Internal builder
and subagent reviews are not Founder acceptance or independent external approval.

## 2. Changed-file envelope

All twenty implementation files are new, unwired and contained in
`SOURCE/tools/compatibility_stage2/`. Exact hashes are in run/static evidence.

| Area | Files |
|---|---|
| Boundary/runner/export | `README.md`, `sandbox_manifest.json`, `run_stage2.rb`, `acquire_runtime.rb`, `export_stage1.dart` |
| Candidate SQL, in load order | `sql/00_local_roles.sql`, `10_synthetic_dependencies.sql`, `20_semantic_inputs.sql`, `30_snapshot_entitlement_state.sql`, `40_private_calculator.sql`, `50_purpose_interfaces.sql`, `60_transaction_lifecycle.sql`, `70_maintenance_repair.sql` |
| Privileged synthetic setup | `fixtures/cases.json`, `fixtures/test_setup.sql` |
| Test inventory and harness | `tests/test_inventory.json`, `tests/concurrency_cases.json`, `tests/assertions.sql`, `tests/harness.rb`, `tests/runner_checks.rb` |

No existing runtime SOURCE, Stage 1 file, migration, dependency, app/native
configuration, route, UI, payment integration or device artifact changed.
No `.env`, production credential, real member data, private-key tree, remote
Supabase project or Git operation was used. No real credits were spent.
Documentation reconciliation updates the wider draft plan and Profile Unlocks
References; this handover and the execution evidence are new. The documentation
index is mechanically regenerated. Stage 1 point-in-time evidence is preserved.

## 3. Candidate architecture — measured local scope

Separate immutable semantic input revisions and immutable calculation records
from a stable directional viewer/target binding. Version changes, tier changes
and ordinary input edits cannot select another ordinary result. Permanent
entitlement is separate from current disclosure permission.

The private tables model subjects/access guards, server configuration,
synthetic Journey/Guardian dependencies, manifest/input revisions and heads,
snapshots/current pair bindings, entitlements, operations, wallets/append-only
ledger, pinned disclosure bindings, restricted evidence and repair audit.

Validation handles raw entry/selection duplicates, duplicate JSON object keys
before JSONB decoding, unknown/missing options and lights, exclusive None,
conditional questions, q24/q26/q39 targeting, Hard Requirements and category
mapping. Legacy provenance is not inferred from a date or boolean marker.
Captured control/Chapter2 semantics are retained separately from the effective
calculation semantics. Legacy repair-quality inputs fail closed.

The complete exported manifest is pinned to canonical SHA-256
`1fac439a6556922b06ee9810fe8daec076c86cf03a38cc8f961460dd7c02e862`.
Host/PostgreSQL canonical serializer agreement and the both-direction/mixed
Stage 1 rational oracle pass. The finite Chapter2 vocabulary is a
synthetic registry, not approved production custom-sect policy.

The calculator uses exact numeric rational contributions and one available
unit per scoring question. Category raw sums reconcile internally with the
overall; categories are not equally averaged. Chapter2 weight 1 and governed
skip conditions pass fourteen hand-derived full-bank contribution-delta cases.
Owner repair, generic target unavailable and configuration failure are distinct
internal states; ordinary responses do not expose target-answer diagnostics.

## 4. Purpose, access and transaction model

- Identity derives from local `SESSION_USER` mapped to synthetic principals;
  there is no client viewer/version argument. This is not JWT/gateway proof.
- Guardian accounts, demo principals, blocked/safety-restricted pairs and
  deleted/suspended/invisible subjects cannot use compatibility interfaces.
- Standard returns only the viewer's saved overall. Plus uses the same binding
  and one pinned symbolic projection; current Guardian information is separate.
- Browse currently models visibility/access with no numeric payload or paid
  snapshot. Production Browse curation/exclusion is not implemented here.
- Journey uses simplified synthetic stage/attempt/mutual-authority fixtures,
  does not change Journey flags on reads and is not full live Journey parity.
- Private scorer, tables and evidence have no ordinary client grants. Forced
  RLS, non-superuser function ownership, fixed search paths and explicit grants
  pass effective catalog/denial tests in this database only. The measured grant
  matrix has 90 cells and zero ordinary private-access grants.

Mutations require SERIALIZABLE. The authored lock order is sorted subject
guards → configuration → wallet when paid → actor/key operation → pair binding
→ fixed-tier entitlements → relevant input heads. Guard writers must participate
in this protocol. Revocation/Journey/Guardian/repair writers update guard
revisions to force stale SERIALIZABLE waiters to retry.

A private candidate is not disclosed or saved as a paid result until preflight
passes. Snapshot/binding, entitlement, one fake debit and operation outcome
commit together. Wallet balance is locked, not computed by an unlocked ledger
SUM. Keys bind actor/purpose/target/tier/request hash. Lost-response retries
check current access and do not return an old sensitive response body.
Missing ownership beside a prior paid operation returns recovery-required,
not another charge. Synthetic gate-off/usefulness failures cannot debit.

The harness retries complete operations on 40001/40P01, using the same key,
for at most four attempts (initial plus three retries). A later real transport
must buffer result bodies until successful commit and discard aborted output;
psql harness behaviour does not prove a production API transport does so.

Committed snapshots contain a server-selected scoring contract and SHA-256 of
the fifteen transitive calculator/validator/arithmetic definitions, alongside
input/manifest provenance. A separate ordinary-viewer commit smoke verifies
snapshot/result pins match the server. Repair audit retains original and
replacement pins; ordinary reads never compare code changes to trigger refresh.
In-flight privileged DDL swaps are outside the fixture writer protocol; frozen
code and exact artifact hashes are required throughout candidate execution.

The server Plus gate defaults off. Symbolic `synthetic_band`, allowed-category
sets, fake prices and usefulness count are privileged test parameters only—not
band names, thresholds, upgrade/refund policy or minimum useful Plus decisions.

## 5. Legacy, repair and retention limits

The candidate preserves entitlements through a bounded free initial transition,
allows necessary repair attempts before the first validated result, and never
publishes provisional scores. Once validated, ordinary reads/edits/upgrades do
not refresh. Recovery never silently invents a score or repeats a debit.

Privileged defect repair uses captured original evidence only, validates its
fingerprint, records an audit and replaces the current binding without charge.
Missing/invalid original evidence marks unavailable/review; current heads are
never substituted. Replacement suppresses Plus projection rather than creating
a richer second transcript. This models a protocol, not proof of a particular
defect correction or authority to repair production data.

**Retention/deletion is incomplete.** Evidence-bundle purge does not erase raw
semantic revision history, all replaced aggregate payloads or references from
operations/audit. No exact retention period, lawful evidence-retention basis,
account-erasure workflow, tombstone period or cumulative-policy migration is
selected. Those mechanics must be resolved before production storage/apply.
Checksums are provenance checks, not cryptographic sealed storage or encryption.

## 6. Measured evidence and pending tests

Point-in-time historical evidence is preserved:

- `SYSTEM/RESOURCES/REVIEWS/COMPATIBILITY_UNLOCK_STAGE2_STATIC_20260928T223652782986Z.json`
- `SYSTEM/RESOURCES/REVIEWS/COMPATIBILITY_UNLOCK_STAGE2_EXECUTION_EVIDENCE_2026-09-28.md`
- `SYSTEM/RESOURCES/REVIEWS/COMPATIBILITY_UNLOCK_STAGE2_DOCUMENTATION_SEAL_2026-09-28.json` records documentation hashes and preserved static-evidence identity.

Executed continuation evidence:

- `COMPATIBILITY_UNLOCK_STAGE2_ACQUISITION_20260928T224328933597Z.json` (initial acquisition; later hardening is separate evidence, not retroactively claimed).
- `COMPATIBILITY_UNLOCK_STAGE2_RUN_20260928T225544Z.json` (failed run: 40 passed, 73 failed, eleven pending; preserved).
- `COMPATIBILITY_UNLOCK_STAGE2_RUN_20260928T230045Z.json` (corrected run: 112 passed, one measured, eleven pending).
- `COMPATIBILITY_UNLOCK_STAGE2_RUN_20260928T230336Z.json` (fresh replay: 112 passed, one measured, eleven pending).
- `COMPATIBILITY_UNLOCK_STAGE2_RUN_20260928T230835Z.json` (final strengthened replay: 112 passed, one measured, eleven pending; IN04/IN06 five negative subcases each, exact PR10 unavailable state, case-specific TX03/04/05 retries).
- `COMPATIBILITY_UNLOCK_STAGE2_STATIC_20260928T230645494649Z.json` (final 21 static checks, same twenty candidate hashes as final run).
- `COMPATIBILITY_UNLOCK_STAGE2_COMMANDS_scoring_commit_provenance_verified_20260928T230141497969Z.json` (actual viewer commit and matching private server pins; synthetic fixture reset).
- `COMPATIBILITY_UNLOCK_STAGE2_RUNTIME_EXECUTION_2026-09-29.md` records final replay, strengthened assertions, cleanup and final evidence identities.
- `COMPATIBILITY_UNLOCK_STAGE2_COMMANDS_teardown_20260928T230858355377Z.json` and `COMPATIBILITY_UNLOCK_STAGE2_COMMANDS_final_cleanup_verified_20260928T230918370494Z.json` verify exact synthetic removal and only the new VM stopped.

All files above are under SYSTEM/RESOURCES/REVIEWS. Timestamped COMMANDS files
preserve setup failures, isolation corrections, runtime inspections and exact
teardowns; no failed artifact is overwritten.

The 21 executed checks cover protected hashes, clean child environment,
subprocess capture/bounded termination, mocked exact-runtime drift refusals,
path traversal rejection, JSON/ID integrity, exporter coverage, host manifest
pin, four Ruby syntax checks and scoped exporter analyzer. Runtime inspection
mocks are explicitly not live isolation/grant/concurrency evidence.

The database harness contains ordinary-role reads/purchases and denied direct
calls, preflight/rollback injection, independent-session races and controlled
revocation/gate ordering, frozen-result/recovery/legacy tests, original-input
repair and a bounded Standard-only inference probe have executed. ISO01–05
are root's actual VM/container/child-environment/source inspections, not mocks.
IN07's unsupported-capability branch uses an uninstalled synthetic manifest
clone against the private validator: the current canonical bank has no
hard_supported=false control. IN08 proves exact-manifest tamper rejection, not
independent execution of every category-mapping validation branch.

OBS01 is **measured**, not privacy-passed. Two valid administrator-reset worlds
for q33 return 99% versus 100%. An attacker who knows every other contributing
answer, unchanged applicability/denominator and the two possible q33 answers can
identify the differing prayer answer from the first Standard percentage. This
is a structural counterexample under strong stated prior knowledge, not attack
prevalence, a repeated-query test or approved residual risk. No scoring rule,
rounding, denominator, noise or rescaling was changed to hide it.

Eleven deferred IDs remain: REV05 (the candidate has no Bio/profile write path;
requires later integration), OBS02–11 (complete/incremental observable-transcript
privacy research). Pending is not passing. Complete physical retention/deletion,
production capture/JWT/ACL/ledger and real Journey/Guardian integration remain
additional broader gates, not certified by the named local suite.

Evidence limitations: guard-first revocation denies purchase; purchase-guard-first
schedules may commit before restriction, then subsequent reads/retries deny
payloads. No retroactive cancellation/remote erasure is promised. TX12 tests
three opposing-direction schedules, not every workload. TX13's 40P01 is a
deliberately cyclic privileged fixture, not an ordinary API deadlock. Earlier
runs' TX03/04/05 retry arrays are cumulative across cases; the final strengthened
harness records per-case slices. Do not interpret historical cumulative arrays
as per-case retry counts. REC04's
equal-score repair proves changed binding/source handling, not alone exclusion
of an equal cached score. LIFE04 tests deletion-status suppression, not erasure.

## 7. Findings → existing action trace

| Finding / unfinished obligation | Existing owner |
|---|---|
| Manifest SQL parity, Chapter2 validation/arithmetic, real capture provenance and semantic repair | OA193/226; regression OA228/229/DR211 |
| Lock-only revocation race caught/fixed; local SQL replay and current-access retry measured; production writer participation and transport commit buffering still unproved | OA285/193/192 |
| Permanent entitlement recovery and fake-wallet atomic/concurrent debit proof | OA192/193/285 |
| Simplified Journey/Guardian fixtures are not live parity; client account-switch/cache behaviour remains untouched | OA283/284/285 |
| Bundle purge is not complete retention/deletion; original-input lawful capture/storage remains undecided | OA193/285 |
| Full Standard-only and incremental Plus transcript inference, usefulness, bands/suppression and distribution measurement | OA285/230/227/193 |
| Candidate parser/operator/test-fixture defects caught, corrected and replayed; sandbox DNS forwarding/disk restart defaults hardened | OA193/285 Stage 2 proof and isolation obligations; not production incidents |
| Bounded first-Standard prayer-answer inference counterexample; full residual-risk research and Founder acceptance still open | OA285/230/227/193 |
| Final replay, synthetic cleanup and later integration/privacy/retention gaps | OA193/285 |
| Production apply/spending/activation and app/device delivery excluded | OA193/285/257/286; separate exact Founder GO |

Written disposition: these findings belong to the existing redesign/proof
actions; no duplicate OA or fabricated production incident is created. No
engineering action is closed. Historical Stage 1 results, policy decisions and
live release evidence remain unchanged. This local handover records execution
progress without self-approval or promoting the candidate into a migration.

## 8. Continuation, rollback and acceptance

Next: Founder reviews the measured candidate and privacy counterexample, then
reviews a bounded Stage 3 integration/research brief before any separate GO.
Do not activate Plus or alter Standard silently. Stop on name/ownership/image/database drift, credentials
or real identifiers, network/host mounts, protected-source drift, leaked private
payloads, arithmetic disagreement, repeat spending or concurrency failures.
Preserve failed runs and do not continue to Stage 3/app wiring automatically.

Conditional runner modes are `baseline`, `setup`, `inspect`, `test`, `teardown`;
none downloads a runtime. Setup refuses existing names. Teardown validates the
exact labelled synthetic container/volume before removal. The VM profile is a
separate exact verified cleanup; no global prune or unrelated profile removal.
The final execution report records exact labelled container/volume removal and
stopping only the newly created VM. Candidate files/evidence and the stopped
task VM/public image cache remain available for replay; no source rollback,
Git, global prune or unrelated profile deletion occurs. Deleted synthetic
database state is reproducible from retained fixtures, not retained as real data.

Band names/thresholds, suppression, minimum useful Plus disclosure, custom values,
exact retention/deletion, risk acceptance, production migrations and activation
remain separate Founder decisions. Stage 2 acceptance and later execution GO
are not inferred from authoring/static checks.
