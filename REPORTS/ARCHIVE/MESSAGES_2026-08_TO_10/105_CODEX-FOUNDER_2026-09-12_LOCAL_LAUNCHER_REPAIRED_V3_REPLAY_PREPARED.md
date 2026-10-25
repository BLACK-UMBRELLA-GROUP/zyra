# 105 — CODEX → FOUNDER: local launcher repaired; V3 replay prepared

Date: 2026-09-12 · Owner: Codex · OA-ZYRA-286 · AD-AIOS-109

## 1. Founder summary

The launcher fault is diagnosed and repaired. The real corrected status check
passes and the test VM is stopped. All 94 local mock tests pass. No VM startup,
database replay, cloud change or Apple upload happened in this repair turn.

ZYRA Production build2 remains the existing private TestFlight app. ZYRA Test
is still not uploaded/available. This is a repaired prerequisite, not delivery.

## 2. Authority and measured cause

The Founder replied **CONTINUE** directly to the scoped request to diagnose and
repair the local launcher without starting a VM/database or uploading. That
authorised this repair, not a second full replay. The earlier V2 replay GO is
consumed and its marker/result must never be reused or rewritten.

Controlled read-only A/B used the pinned Colima0.10.3 `list --json`, identical
sanitised environment and diagnostic paths. Without HOME it returned exit1:
`error retrieving instances: exit status 2` at 17:05:44 BST. Adding only the
independently checked normal `HOME=/Users/shakeelahmad` returned exit0 and
`zyra-oa198` / `Stopped`. This establishes the missing-HOME cause in this
environment. The precise nested Lima error was not captured or invented.

After repair, the actual V3 `Commands.call` dispatcher was invoked once for the
same read-only command, with Colima/Lima executable hashes checked first.
Exit0 and `profile_state(..., stopped)` passed. Event timestamps:
1789229387.080215–1789229387.229619. The tested run.py and lifecycle.py hashes
are identical to those in the final successor manifest.

Full non-secret transcribed evidence:
`evidence/oa286-native-launcher-diagnostic.8Yq1Vo/READ_ONLY_DIAGNOSIS.md`,
SHA-256 `cf48bf110038fe9732e98f5c7867b293d9410d1b93af09207f7be2d3562ea2c4`.
Evidence paths in this report are relative to the workspace:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3`.

## 3. Exact bounded change

New separate packet: `evidence/oa286-full-replay-execution-proposal-v3/`.
Its files were absent before creation; consumed V2 is the preserved source
anchor, not an edited-in-place predecessor.

1. Verify original HOME equals the normal account home, with matching account
   UID and directory ownership, before the one-use execution marker.
2. Preserve that HOME only for the exact pinned Colima/Lima executables. No
   arbitrary ambient variables are inherited. Docker, Supabase and explicit
   SSH retain the old HOME-free environments; no key/agent handling changed.
3. For failed non-capture commands, retain stdout/stderr byte counts and SHA-256
   plus fixed known classifications on exact native status commands. Scan is
   bounded; new failure evidence is exclusive/private0600. No raw output,
   arguments, environment or arbitrary error strings are copied. Unknown
   errors remain unclassified. Evidence-write failure does not hide the
   original command error. Explicit capture-log stages are unchanged.
4. No-start cleanup now reports `no-vm-start-attempted-no-vm-stop-issued`.
   It cannot claim a measured shutdown when no start was attempted.
5. New project/resource names and `execution-v3` marker prevent reuse of V2.
   Tests/documentation and corresponding pins change only for this successor.

All 213 SQL inputs, snapshot SQL, image policy, official CLI source pins,
mount/network/forwarding constraints, first-error rule, guarded operations and
exact owned-resource cleanup envelope remain unchanged. No source SQL fix or
expansion was smuggled into the launcher repair.

## 4. Validation and limits

| Check | Actual result |
|---|---|
| Root pure tests: runner, activation, launcher, lifecycle, Docker guard, snapshot | 94 PASS, 0.310s; mocked, no VM/database/network |
| Root actual repaired native status dispatcher | PASS exit0; named VM Stopped |
| Root default `run.py`, no execute flag | LOCAL_FILES_VALID; 213 inputs; exact approval required; execution_ready false |
| Successor manifest check | 17/17 PASS |
| Consumed V2 manifest check | 16/16 PASS, historical result hash unchanged |
| Saved Colima profile after diagnostics | Unchanged, SHA-256 069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d |
| Flutter/full visual/analyzer | Not rerun; no app-source/UI changes; prior dated results remain prior evidence |
| Actual full replay, cached-image presence, SQL/harness/rollback/cleanup | NOT RUN; still require the new authorised runtime result |

Root test command/result and coverage are recorded in
`evidence/oa286-native-launcher-diagnostic.8Yq1Vo/LOCAL_TEST_RESULT.md`.
Subagent implementation and bounded review are internal Codex checks, never
independent sign-off, self-approval or Founder acceptance.
The final bounded internal review passed with no material blocker: all17
manifest entries, exact HOME scope, preservation of the V2 policy/SQL and
absence of `execution-v3` were checked. It noted that a failing OS account/home
lookup could emit a generic exception rather than a clean Stop; this still
refuses before the marker and was non-blocking on the verified host. No runtime
or delivery proof is inferred from that review.

## 5. Frozen package and true pre/post ledger

New execution manifest SHA-256:
`5d413b2bee67023d5777ac93f8ea7b6ac24c1295b7c622f956a59ef25dcda0de`.

All 17 new successor files have pre-state ABSENT; their exact post-hashes are
in `evidence/oa286-full-replay-execution-proposal-v3/EXECUTION_MANIFEST.sha256`.
Key bound entries:

| File | SHA-256 |
|---|---|
| run.py | d3a2bc2329d214647b3705634b118a84b5370ca426c51928ff64d0620b9ff42f |
| lifecycle.py | 73f130da433603ef3a7087c4306e6c3a019fd21febce21d706f2f9a3f1e410e1 |
| docker_guard.py | 491e13cbab92ac87cdd9bf46ea309229d98df92c00bbe11dd24750fdc1d268e6 |
| snapshot.sql, unchanged | 9e669e83eba0e69a1ad6cc096cbf26aa85ccd29f2b1a2758e721454d87ab03ce |

Preserved V2 manifest: `8ed5a2a851a8a5361cf052c6a523fcf410ef2005f37e1936c8fa337228838471`.
Preserved V2 result: `b88e826e5c18f521f48e86a4dc722eed328490d94c5dcea7e7fac089e4f6043a`.
Preserved 209-migration aggregate: `5bb9e76128b3f4bc9297cdefbf6feed63da9c226bf720de403478684c7f6901c`.

Canonical handover true pre-file was copied before edit to
`evidence/oa286-launcher-repair-prestate.IMLucK/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.pre.md`.
Source and copy matched SHA-256
`a536a230d2f973613ce84102df1063ac74bf52d6c51ef1d635bcd4d112d966a0`.
Post-file SHA-256:
`8530ff362edbe777ae1a1ebe4c5abe9473444b1b5d0d50ba169c52486353ccbf`.
Only current status and new §10.3 were added; §10.2 and104 remain historical.
This new105 report was absent before creation; its final hash is filed in the
workspace completion ledger, avoiding a self-referential hash.

Current handover/report record this checkpoint under existing OA-ZYRA-286.
The huge master OA file was not edited and no new OA was allocated.

## 6. Proposed next exact approval — NOT executed by this report

One local replay using only manifest
`5d413b2bee67023d5777ac93f8ea7b6ac24c1295b7c622f956a59ef25dcda0de`:

- Start only the existing stopped `zyra-oa198` VM once, with the fixed no-host-
  mount/no-automatic-forwarding/no-agent settings. The reviewed owned SSH
  tunnel binds only127.0.0.1:55432. No saved-profile rewrite.
- Use cached pinned images only, a fresh internal bridge and named database
  volume for `zyra-oa286-full-replay-final-v3-e914bc`. No existing database reset,
  host/source mount or cache download. This is not a blanket VM-egress-disable
  claim: the no-download guard and internal Docker network are the boundaries.
- Run the official pinned CLI fresh bootstrap, unchanged 209 migration history,
  unchanged persona and15-RPC overlay inputs210–211, then harness212/213 once
  with strict before/after rollback snapshot equality. Seeds disabled.
- Stop at first failure, retain the one-use marker/result, clean only proven
  owned resources and stop the named VM/tunnel once. No automatic repair/retry,
  forced cleanup, cloud/project/credential action, app build or Apple upload.

The full exact envelope and limitations are in the frozen README. New direct
Founder approval is required before `--execute --approve-manifest` for that
digest. A missing/mismatched digest or any drift refuses execution.

All remaining Test cloud schema/identity/role/fixture/Edge/pin/Apple delivery
gates stay open. The Founder's manual-only credential preference, including
the outstanding precautionary Google secret rotation, remains unchanged.

— END 105 —
