# 104 — Local replay V2 stopped before VM start

TO: Founder
FROM: Codex — Operations / Governance / Delivery
DATE: 2026-09-12
OWNER: OA-ZYRA-286
STATE: ATTEMPT CONSUMED / FIRST-COMMAND STOP / NO DATABASE OR APP DELIVERY

## 1. Outcome

The approved one-use local attempt stopped at `colima list --json`, exit 1,
before any VM-start command. No Docker, Supabase CLI, PostgreSQL, migration,
harness, database, tunnel or cloud action was reached. No Apple or credential
operation occurred. ZYRA Test is still not delivered; the existing Production
app was not changed.

This is a local test-launcher failure, not evidence that the app or its SQL
failed. The launcher discarded the failed command's output, so the precise
cause is not established. No repair, retry or successor implementation followed.
The consumed package and its one-use marker must not be reused.

## 2. Exact authority and preflight

The Founder replied `cONTINUE` directly to the final request to approve report
103's one-use local database check. Codex explicitly confirmed that scoped
interpretation before acting. This was GO for that exact package only, not a
new programme-wide approval or reuse of earlier runtime authority.

Report103 remains byte-identical at SHA-256:
`7f34ca152124ec1870e8c142379eb427e482d0df11d7492739a2613c363036b3`.
Final V2 execution manifest:
`8ed5a2a851a8a5361cf052c6a523fcf410ef2005f37e1936c8fa337228838471`.
Root's pre-activation approval record:
`evidence/oa286-full-replay-approval-20260912-v2.md`, SHA-256
`404e553a8c05a36d95d0971493a27e2dca82e2cd0f356a2c75656c32fee51e53`.

Fresh file-only preflight verified all 16 manifest entries, report103's hash,
213 SQL inputs and pinned binary/config/source files. The real execution-v2
directory was absent. A second internal Codex file-only check confirmed these
facts; that check supplied no approval. The 85 mocked tests in103 are prior
preparation evidence, not a fresh SQL result or a new suite run here.

## 3. Single invocation and first result

Workspace:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3`

Working directory: `evidence/oa286-full-replay-execution-proposal-v2/`.
Executed exactly once with command-scoped local runtime permissions:

```text
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 run.py --execute --approve-manifest 8ed5a2a851a8a5361cf052c6a523fcf410ef2005f37e1936c8fa337228838471
```

Runner exit: 1. Output: `STOP: command failed at stage 1`.
Only recorded command: the pinned Colima binary's `list --json`.
Start: 2026-09-12 15:59:23.831 UTC / 16:59:23.831 BST.
End: 2026-09-12 15:59:23.931 UTC / 16:59:23.931 BST.
Recorded command exit: 1. No second runtime command was issued.

Immutable result location:
`evidence/oa286-full-replay-execution-proposal-v2/execution-v2/result.json`.
Result SHA-256:
`b88e826e5c18f521f48e86a4dc722eed328490d94c5dcea7e7fac089e4f6043a`.

Result contains STOPPED, first_error `command failed at stage 1`, no cleanup
errors, no replay stages, no image observations and exactly one command event.
The exact approved manifest is recorded. No database PASS is claimed.

## 4. What exists, cleanup and limits

The runner exclusively created the durable execution-v2 directory and
prepared its local payload files before its first command. These remain:
209 migration copies, one config copy, two executable guard copies and the
result. They are evidence, not a database or an applied migration set.

The copied 209-file aggregate was rechecked as
`5bb9e76128b3f4bc9297cdefbf6feed63da9c226bf720de403478684c7f6901c`;
file count is 209. Both wrapper copies equal their approved source at
`8703be02d01aab4c1f12f6f97d0eb532a6688bed4f5040b07aebed922e3d0a20`.
Config copy equals its approved source at
`69a905c6aa9f38ec5d78c71b7840f782491c66d8563b482e10f8c518a1853702`.
All 16 original manifest entries reverified unchanged after the stop.

Frozen control flow places the failed list before `started_attempted=True`
and before `colima start`. Replay.run was never entered. Replay cleanup was
an unowned no-op; lifecycle cleanup skipped VM/tunnel stop commands. Therefore
`owned-lifecycle-stopped-once` in the result only means the cleanup method
finished once. It is NOT proof of a VM start/stop or a post-stop inventory.
A second internal file-only control-flow check confirmed this distinction.

Read-only filesystem checks after the stop found the named Docker,
containerd and SSH sockets and ha.pid absent. The saved zyra-oa198 profile
remains SHA-256
`069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d`.
A separate read-only `/bin/ps` check was denied by the normal sandbox; it was
not escalated or retried. These observations do not establish a complete
ambient VM/daemon inventory. No VM start or resource creation was issued by
this attempt, and no material resource was deleted. All prepared evidence
and historical records are retained.

## 5. Findings and next bounded work — not executed

Both findings belong to existing OA-ZYRA-286; no new identifier or closure.

1. Confirmed diagnostic defect: Commands.call pipes stdout/stderr for the
   initial list, but on its nonzero exit the exception path does not retain
   them. There is no command001 log and the exact error cannot be recovered
   from this result. A future correction needs bounded, non-secret failure
   diagnostics before raising the first error.
2. Unconfirmed startup prerequisite: the sanitized command environment omits
   HOME. Colima/Lima may still require it despite explicit COLIMA_HOME and
   LIMA_HOME. This is a plausible cause only, not the observed exit message.
   Do not claim the environment fix is proven or silently rerun the command.

Recommended next scope, requiring Founder direction: read-only diagnosis of
the launcher prerequisite, then a separately versioned local correction and
non-database validation. Preserve the consumed V2 and all SQL bytes. Keep
ambient credentials/routing excluded; any necessary original HOME is for its
normal native-tool purpose only, not a pointer to company secrets. Do not
start a VM/database or create cloud/Apple resources under that preparation
scope. A later actual replay requires a newly verified exact package and GO.

## 6. Living handover, pre-state and validation

The current Developer Control handover was fully read before editing. Only
its top status and new §10.2 changed, recording this stop and linking104.
True pre-file was copied at edit time to:
`evidence/oa286-local-stop-prestate.vEZ2q0/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.pre.md`.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md | 6d1231944cea2970141fc69324e00d25d158a8e8a0fbc75a137bc3f20765125c | a536a230d2f973613ce84102df1063ac74bf52d6c51ef1d635bcd4d112d966a0 |

Full diff and changed sections were reread. Other Google/manual-security,
source/SQL and live-delivery statements remain unchanged. The master OA
register was read in scope but not edited; this execution event and its two
findings are traced under its existing OA-286 in this report and the living
handover. No OA count or NEXT IDENTIFIER was changed.

No Flutter/analyzer/build suite was rerun for this execution/report-only step.
No frozen runner or SQL was edited. No report103 evidence was rewritten.
The only new governed file is this104, whose true pre-state was ABSENT.
The existing App Store runbook's remaining gates, manual-only credential
preference and Production boundaries remain binding. Test app, full replay,
cloud setup, real Founder/persona proof and device acceptance remain open.

This report supersedes103 only as the runtime/consumption status of its V2
approval target. It does not claim Founder acceptance or a successful check.
