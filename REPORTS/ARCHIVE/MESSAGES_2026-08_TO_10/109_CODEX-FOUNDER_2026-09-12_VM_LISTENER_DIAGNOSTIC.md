# 109 — CODEX → FOUNDER: VM-only diagnostic prepared; shutdown clarification

2026-09-12 · OA-ZYRA-286 · PREPARATION ONLY / NOT EXECUTED

## 1. Outcome

No new VM start occurred. The diagnostic is prepared and its11 pure mocked
tests pass. A source-verified shutdown behavior conflicts with the explicit
no-force boundary in108§5, so runtime is held. No database/SQL, SSH connection,
cloud change, company credential access or Apple operation occurred.
ZYRA Test is not yet on TestFlight; this is not delivery or self-approval.

## 2. Authority and unchanged scope

Founder `rUN AGAIN` directly accepted the immediately preceding request for
one VM-only diagnostic in108§5 and local launcher repair. It did not authorise
reuse of consumed V4 or another full replay. Its original no-force scope was
recorded without retrospective amendment in workspace:
`evidence/oa286-vm-listener-diagnostic-approval-20260912.md`
SHA-256 `c3456a40d350b75cb9d85e58508aeb9719a9a541a8c5f3b76775066cfc38dc4c`.

The Founder-operations skill's exact-action/stop-on-new-risk rule caused this
runtime pause. Root remains sole runtime operator; subagents only prepared
or reviewed local source. Internal review is not external approval.

## 3. Concrete diagnosis lead and new conflict

Pinned Lima2.2.0 source shows that named user-v2 networks use a detached/shared
`limactl usernet` daemon. The VZ vsock fallback asks that daemon to expose the
VM SSH port. It need not be a descendant of the VM host agent. The saved
configuration names user-v2; the old log reports that fallback. Therefore
V4's ancestry-only guard is structurally too narrow for this configuration,
but the exact PID that held the prior endpoint was not retained and is NOT
claimed proven. Source: [VZ driver](https://github.com/lima-vm/lima/blob/de0816ea4bdc5267b428ab21025889b8dd785526/pkg/driver/vz/vm_darwin.go),
[usernet startup](https://github.com/lima-vm/lima/blob/de0816ea4bdc5267b428ab21025889b8dd785526/pkg/networks/usernet/recoincile.go).

Two existing termination paths contradict a literal zero-force promise:

1. Normal Colima stop invokes normal Lima stop. Following successful graceful
   VM shutdown, network reconciliation may stop the unused user-v2 daemon.
   That helper receives SIGINT and then SIGKILL if still alive after five
   seconds. No `--force` flag is required. The separate VM/hostagent graceful
   wait returns an error on timeout; it does not invoke StopForcibly.
   [Colima Stop](https://github.com/abiosoft/colima/blob/v0.10.3/environment/vm/lima/lima.go#L190-L221),
   [Lima stop command](https://github.com/lima-vm/lima/blob/de0816ea4bdc5267b428ab21025889b8dd785526/cmd/limactl/stop.go#L25-L49),
   [network reconciliation](https://github.com/lima-vm/lima/blob/de0816ea4bdc5267b428ab21025889b8dd785526/pkg/networks/reconcile/reconcile.go),
   [helper termination](https://github.com/lima-vm/lima/blob/de0816ea4bdc5267b428ab21025889b8dd785526/pkg/networks/usernet/recoincile.go#L128-L168),
   [graceful VM stop](https://github.com/lima-vm/lima/blob/de0816ea4bdc5267b428ab21025889b8dd785526/pkg/instance/stop.go#L23-L99).
2. The immutable V4 `run.py` Commands wrapper starts each owned command in a
   new process group. On timeout, interruption, or an OS exception while the
   child remains running, it SIGKILLs and reaps that exact group before outer
   cleanup. The diagnostic inherits this behavior: START180s, STOP120s,
   ordinary observation command default30s. This is not permission to kill
   arbitrary processes or forcibly stop the VM itself.

No supported no-reconcile/keep-network/no-force option was found in the pinned
normal stop path. A replacement cleanup protocol would be a separate design,
not an invisible change to the accepted scope. Neither fallback was exercised
in this turn because no diagnostic runtime was started.

## 4. Frozen diagnostic and local results

Workspace base:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3`

All four files under `evidence/oa286-vm-listener-diagnostic-v1/` were new at
creation; no former pre-file exists. Its PRESTATE.md records the initial mock
fixture correction, which occurred without any native subprocess execution.

| Target | SHA-256 |
|---|---|
| MANIFEST.sha256 | `1af2dcb2d3b5ebe13851dc23ddfe8640366cf55ced3cb2e4e45fc685d8e9d9e5` |
| diagnose.py | `7f1675b5daf4915ab2e855060465abf01f249256409b9ddc10e7cf6e649a663e` |
| test_diagnostic.py | `72dd4f709d3e6478b829572de74c10a930952b558c492cdac152cdf293b55a38` |
| README.md | `dc0c2a2171572c929c9a4e8cc7e65250fb8d35ff978f13a15a05e7a88d54176e` |
| PRESTATE.md | `0f6319a41d127443fc4b81036780eb682accffe233895d14df30cc09fdc537e5` |

Root ran file-only checks:11 mocked tests PASS in0.035s;4/4 manifest payloads
OK; default diagnostic returns FILES_VALID_NO_VM_STARTED. Native launch is
blocked in the mock suite. Actual `diagnostic-run` is absent. No result.json
exists for a real diagnostic, and no runtime PASS is claimed.

Internal peer review separately verified the same manifest and 11 pure tests
(0.029s), finding no additional containment/classification/cleanup blocker.
Its outcome is preparation PASS with the same explicit authority HOLD, not
Founder approval or independent external sign-off.

The diagnostic imports only checked immutable V4 bytes and validates its
complete17-file manifest `ec1c39f5732f958131323d04cd38aac70bf344674a48625f470b126c72efe82c`.
V4 and all consumed markers/results are unchanged. Its scoped observations
cover exact endpoint count/PID/UID/PGID/parent chains, usernet PID and configured
flags/paths/subnet/semantic leases, component-only endpoint summaries and
pre-stop forwarding classifications. Raw command strings/leases/host addresses
are not saved. Observation does not admit a new trusted owner or prove network
exposure from a forwarding announcement. The exact management endpoint must
disappear after stop; a shared daemon need not disappear merely because this
VM stopped. No Docker/SQL/replay or explicit SSH tunnel is in the allowlist.

## 5. Single requested clarification

Approve one VM-only diagnostic using the exact manifest in§4, with the same
unchanged profile/executable pins and isolation START flags, one start and
one normal stop, **including both**:

- Lima's normal unused user-v2 helper SIGKILL fallback after five seconds;
- the inherited wrapper's kill/reap of only its own command process group
  on timeout/interruption/OS error while that child remains running.

No explicit force-stop command, arbitrary/shared-process kill by Codex, retry,
database reset/replay, cloud operation, credential use or Apple upload is
included. Preserve all consumed evidence. Stop at the first runtime result.
The existing local-repair authority remains: prepare a new tested launcher
after interpreting actual diagnostic evidence, without rerunning a database.

The script's `--accept-vendor-helper-kill` flag is only a technical latch. Its
name does not convey approval for both behaviors; this full§5 clarification
must be accepted before root passes it. No package edit is necessary simply
to supply the approved manifest or acknowledgement. Without acceptance, HOLD.

## 6. True pre-state and records

The current developer handover's true pre-file was copied before editing to
workspace `evidence/oa286-vm-diagnostic-prestate.HDVLTl/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.pre.md`.
Its SHA-256 and immediately-before-edit source SHA-256 both equal
`2bf87646d7ba870869506ae8c083d10a8372ddfef664715bc99809a116023a06`.
Only its status and new§10.7 changed. This109 target was confirmed absent
before creation. Post hashes are recorded in that directory's COMPLETION_LEDGER.md
after filing, avoiding a self-referential report hash. The master OA register
was not edited; OA-ZYRA-286 remains open. No git, migration, approved pixels,
app source or Apple artifact was touched.
