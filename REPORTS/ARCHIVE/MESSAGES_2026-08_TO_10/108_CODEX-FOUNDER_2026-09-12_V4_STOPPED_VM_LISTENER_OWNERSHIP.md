# 108 — V4 stopped at VM listener-ownership check; shutdown verified

TO: Founder (Shakeel)  
FROM: Codex  
DATE: 2026-09-12  
TRACKING: OA-ZYRA-286 · DR-ZYRA-228/229 · AD-AIOS-109  
STATUS: Exact one-use local attempt EXECUTED / STOPPED; cleanup POST-VERIFIED

## 1. Plain outcome

- The corrected pre-start checks passed and the local test VM started.
- Its SSH-listener ownership check then failed. The runner stopped before
  creating any database or starting SQL, and shut the VM down cleanly.
- Existing ZYRA TestFlight and both cloud projects were untouched. ZYRA Test
  is still not uploaded. This is a local workflow failure, not an Apple rejection.
- Do not reuse V4, weaken the security check, or claim its mock/preflight PASS
  proved the full runtime. The required ownership evidence was not retained.

## 2. Authority and exact execution

Founder reply **JUST DO IT UTIL 2 APPS ARE ON MY PHONE PLEASE** directly answered
the exact report107§5 V4 proposal. That constituted GO; it was not asked twice.
The same message keeps the two-app outcome in scope but does not override the
presented stop-on-first-failure/no-repair/no-retry boundary.

Sole root operator invoked ONCE:
`PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 run.py --execute --approve-manifest ec1c39f5732f958131323d04cd38aac70bf344674a48625f470b126c72efe82c`

Directory:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-full-replay-execution-proposal-v4/`

Before invocation, exact manifest and all17 entries passed; default file-only
validation checked213 SQL inputs; execution-v4 was absent. Command-scoped
runtime permission was granted. No source/payload edit occurred.

The durable execution-v4 now exists and remains permanently consumed.
Actual outer command exit1: `VM SSH listener lacks verified host-agent ancestry`.
No retry, repair, force action or further live runtime diagnostic followed.

## 3. What passed, what failed, what remains unknown

| Stage | Actual result |
|---|---|
| Commands1–3, pinned status + TCP/UDP | exit0; complete stopped preflight passed |
| Command4, exact Colima start | exit0;1789231165.16008–1789231179.128383 |
| Command5, running status | exit0; running profile parsed |
| Saved/generated/SSH configuration guards | Passed before the subsequent calls |
| Commands6–7, TCP/UDP | exit0; both parsed |
| Commands8–10, host-agent UID, command and process ancestry | exit0; identity/tree predicates passed |
| Management-listener owner predicate | FAILED; no replay stage reached |
| Command11, exact graceful Colima stop | exit0;1789231179.268265–1789231181.322923 |
| Commands12–14 and file guards | stopped state, listener/socket/PID absence and profile hash verified |

The final predicate requires exactly one newly observed PID on the expected
management endpoint, belonging to the verified host-agent descendant set.
Its failure alone cannot distinguish no owner, multiple owners, or an owner
outside that set. Successful lsof/ps output stayed in memory and was discarded;
the derived owner-set counts were not captured. Do not invent the missing fact.

Retained startup log004.log reports vsock SSH unavailable and a usernet
forwarder, with local port58611. This is a diagnostic lead, not proof of who
owned the socket. The same log records DNS port53 forwarding observations and
a failed wildcard bind. Neither a forwarding announcement nor a failed bind
proves successful exposure. result.forwarding_log_observations is empty only
because _logs_guard had not been reached; it is NOT evidence of no events.

Result: status STOPPED; stages []; lifecycle stages stopped-prefix and
owned-lifecycle-stopped-once; cleanup_errors []; observed_image_ids {}.
No explicit SSH tunnel, Docker CLI, Supabase CLI, database, migration, SQL or
harness command occurred. Colima's own approved startup/stop did operate its
VM/daemon. There was no new project-owned database resource to delete.

Independent file-only postcheck found the named Docker/containerd/SSH sockets
and host-agent PID absent, saved profile hash unchanged. This did not restart
the VM or make a post-failure database query. Logs, marker and result remain.

## 4. Evidence and true pre/post files

Paths below are relative to the workspace evidence directory used in §2.

| Item | SHA-256 |
|---|---|
| V4 EXECUTION_MANIFEST.sha256, all17 still match | ec1c39f5732f958131323d04cd38aac70bf344674a48625f470b126c72efe82c |
| V4 execution-v4/result.json | 246e3dc970fb26a63ff9508c71a7de417f7bc0fa9d80c4e028a7a7fd4be4d391 |
| V4 execution-v4/004.log, startup | 857b5261b8766b661e25a22c62ab2a3d7fb11e8614cb5a283cc8c655b650066a |
| V4 execution-v4/011.log, shutdown | e22983762626f154aa05a7fd23e4b5f9ba4e645532a02b63a168d3f344e0b7ba |
| oa286-full-replay-approval-20260912-v4.md | bc1a70221d75e2a84decf61d11a801f89807117e6d36f3606dba54f72f637c3f |
| Saved /Users/shakeelahmad/.colima/zyra-oa198/colima.yaml | 069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d |

No app source, SQL or frozen runner file changed. Prior105 tests and measured
preflight remain their original scoped results, not a new full-suite PASS.
The Supabase changelog markdown endpoint was unavailable; HTML fallback read,
with no relevant change to this pinned local execution's parameters.

Canonical current handover was fully read and copied at edit time to
`oa286-v4-runtime-prestate.kV7JZF/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.pre.md`.
True pre c62e441e6cbb7a820f8ef45cd6543edcbb24fa86843c461320ab86f7cf369925;
post2bf87646d7ba870869506ae8c083d10a8372ddfef664715bc99809a116023a06.
Only header/§10.6 changed. This108 file was absent before creation; its post
hash is recorded in that prestate directory's completion ledger. Previous
reports/attempts are unchanged. No new OA; master OA unchanged, still open.

## 5. Smallest next action — diagnostic proposal only

A new bounded VM-only diagnostic should capture the missing evidence before
shutdown, instead of another database replay. It needs a separate Founder GO:

- Exactly the existing stopped zyra-oa198 profile, unchanged pinned
  Colima/Lima/SSH/profile identities and V4's fixed isolation start flags.
- One start and one graceful stop, no force fallback or retry. No database,
  Docker/CLI replay, SQL, image fetch, cloud, credential or Apple action.
- While running, read only the named generated configurations, host-agent
  identity, actual TCP/UDP owner sets and the relevant process ancestry.
  Distinguish absent/multiple/outside-tree owner failures; check any usernet
  process against the exact named instance, rather than allowing a generic
  process name. Preserve bounded non-secret diagnostics before stopping.
- Account for the recorded forwarding events and actual listeners separately.
  Do not call failed binds exposure or empty result arrays proof of isolation.
- Verify stopped/socket/PID/listener absence and unchanged saved profile.
  Preserve V4; any later correction must be separately versioned and tested.

The remaining Test deployment is also not just an upload: prepared staged SQL,
Edge code and client scaffolding still need a concrete identity-specific Test
apply/provisioning packet, actual Founder/persona UUIDs and protected claims,
reviewed fixtures, exact pins and live denial tests. Existing local components
are inventoried; no dummy locked app or production-backend shortcut is proposed.
Apple identity/signing/upload follow the existing runbook gates afterward.
The approved terminal objective remains both apps installed and usable, not
merely two store records. No completion or delivery date is claimed here.
