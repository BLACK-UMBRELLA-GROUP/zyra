# CODEX → FOUNDER — V3 PERSONA SQL PASS / CLEANUP VERIFIED

**Date:** 2026-09-12  
**Authority:** Founder “proceed i want both apps done by today pelase”,
accepting the exact one-use V3 proposal in099 §5  
**State:** EXECUTED → POST-VERIFIED; narrow persona SQL only  
**Owner:** Codex / Astra; Founder sole approver  
**Action:** OA-ZYRA-286 remains open

## 1. Outcome

One actual isolated V3 run passed. Manifest
`6975e5045da2e7635777f407f31f6197eedf356111727f7b82d4bfdccff5154f`
was verified before execution and remains unchanged. Real execution-v3 was
absent before the run and is now retained/consumed. No retry occurred.

The four measured PostgreSQL17.6 executables passed. Fresh initdb and server
startup succeeded; one psql process consumed the exact bootstrap, boundary,
full persona harness and postcheck. All statements completed, harness rollback
completed, and the read-only postcheck proved no rows remained in auth.users,
auth.sessions or the three private rate/audit/delivery tables. Exactly one
`OA286_PERSONA_OFFLINE_V1_PASS` marker appeared. Process/container exit0.

The retained V1 marker is intentional because the four SQL files are unchanged.
This is actual PostgreSQL evidence, not the preceding synthetic unit-test result.

## 2. Isolation and teardown

- VM zyra-oa198: stopped before execution (14:57:15 BST).
- One start14:58:02–14:58:12 with mount none, application-port forwarding
  none, SSH-agent/config off, activation/save-config off, no Kubernetes/binfmt.
  Required management SSH/control sockets/internal DNS remain; VM is not
  claimed networkless.
- Separate pre-run container inventory empty.
- Pinned image:
  `sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518`.
- One newly created container:
  `zyra-oa286-persona-v3-55c4cd166aa1`;
  ID `6006bd581926057b5ddce3eab989035022b8928054ccfcb97c741413a0d1baf4`.
- Exact ID/name/label/image, postgres user, network none, no binds/ports,
  read-only root, unprivileged and tmpfs-only/no non-tmpfs mounts verified.
- Fresh exact ownership inspection before force-removing only that container;
  returned removal ID matched. Separate post-run inventory empty.
- One VM stop14:58:55–14:58:57, exit0. At14:59:40 status was not running;
  Docker socket and host-agent PID absent.

The disposable database/tmpfs was discarded with its container. Output and
attempt marker are retained; no existing database or unrelated container was
removed/reset. No cloud, production, Apple, image pull, source rebuild or git
action occurred. Saved profile/generated Lima/networks configuration hashes
remain unchanged; this does not claim VM runtime disks/logs were byte-unchanged.

## 3. Evidence ledger

Task workspace:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/`.
Run evidence: `evidence/oa286-persona-offline-v3/execution-v3/`.
Outer pre-copies/start/stop: `evidence/oa286-persona-v3-execution-prestate.82j5et/`.
Authority file: `evidence/oa286-persona-v3-execution-authority.md`, SHA-256
`a25b95664798981803d72f0816c1574f94a4097609a93cec982044d19f4150c7`.

| Log | Result / SHA-256 |
|---|---|
| 01 image | `fe521571d271d506314826043fdb9fe432fe777bfe598275555651213ad4107b` |
| 02 create / 07 remove ID | `c60cae1791b85dfbe42b3bdbbf7f7f55c4657956113f8f1434f8d405e465f3ba` |
| 03 created isolation | `00cdfdbb188ed25441fc7e0449ea0302634ab49cb21676d3a30d2786b1835d2c` |
| 04 full runtime output | `6fa808ba3586d7b7236ae234280aec8689cf52646ecda94624787b17deccea2a` |
| 05 exited / 06 cleanup ownership | `74d55a5e6fd8c94456e542b7c89e433ac95993a1a68973f55462199e32972065` |
| result.json | PASS / `ff32bcbc89e039eb3cc468782d09cd1833ddc14aa6e00d212c51aa24234eef3c` |
| start-output.log | `f3cb13383dc6fcbbe3e4d6db9e2346e3bfa8d0fc8447f2820a3bef0dd30be68c` |
| stop-output.log | `d0ca4b30e039fb010c54a6fbbb603c5d0c4672eb22f01717ee0c23e642d2b7b1` |

Config pre=post hashes: saved Colima
`069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d`;
generated Lima
`39d7e7055d6a94df00ccbd70f2baa77eab8a55bc9effe56f36dbfa2764ba7309`;
networks
`7963c5d3a2e20c0edb713d2d16693c449f95e8a590bf90ba742af6d8d96fe7ad`.

## 4. Records and current-state reconciliation

True pre-files were captured at edit time under
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_V3_PASS_PRESTATE.Fx7rf6/`.
Appended OA result and reconciled two current documents' now-stale persona
SQL-unrun statements. Historical091/093 snapshots remain identified as dated
evidence. No active migration, staged SQL or application source changed.

| Canonical file | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| OUTSTANDING_ACTIONS_V2.md | `6a8c9f1a1e4f43658ed0d398f769804e58c243de975145c1a8f741cea506fc2c` | `1d9baee24f8678ebbcafb07c0c03b70d71f6c52843f220263f73eee1b98ea0da` |
| ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md | `25a02a164e822f28f252c1162df71b741aa4a609af518fd64f02707c20f0acb2` | `4d1b7fbb6bbf6597c935f3095aab9945a86e408b3b6c06ed0a1abd1b56177900` |
| ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md | `3754873103e65ce9c7ceb34588d77c4688ba5304e911f63180abaa6c153b81bd` | `e22b51a97225001541c3c37921fcece6567b346c5a148460f850575b0145d135` |

This report and new execution evidence pre-state: ABSENT. No old attempt
was rewritten or reused. Preparation/internal verification/Founder GO/actual
execution/post-verification remain distinct; no self-approval or OA closure.

## 5. What remains before ZYRA Test delivery

This result proves the minimal persona SQL harness, not complete managed
Supabase or product operation. It does not prove positive live-Founder/session
authorization, concurrent limits, managed Auth, token expiry/replay, HTTP/Edge
or native integration, or the fifteen legacy developer RPCs on full schema.

The current full schema inventory still requires a separately authorised fresh
replay of207 active migrations plus the two reviewed replay-only bridges,
followed by the staged developer-RPC overlay and transactional proof. Previous
209-version replay evidence086 is reusable evidence, not reusable authority.

Safe local preparation of that complete packet and the exact Test provisioning
plan continues under the Founder implementation instruction. Test schema/Auth,
Google provider/redirect clients, exact Founder/persona/auxiliary fixture IDs,
reviewed synthetic IDV and registry values, public-resource/Edge/SQL pins,
live security verification, Apple Test identity/record, signed artifact and
upload remain separately gated. DR-ZYRA-229 design rulings are already settled;
do not ask the Founder to decide them again.

Existing ZYRA1.0.0 build2 is already private TestFlight. ZYRA Test is not yet
delivered. The same-day request is urgency, not permission to bypass exact
live/Apple gates or weaken the acceptance criteria.
