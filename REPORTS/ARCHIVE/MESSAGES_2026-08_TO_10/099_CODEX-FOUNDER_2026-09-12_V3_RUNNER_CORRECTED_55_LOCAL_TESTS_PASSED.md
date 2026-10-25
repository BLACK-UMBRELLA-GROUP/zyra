# CODEX → FOUNDER — V3 RUNNER CORRECTED / 55 LOCAL TESTS PASSED

**Date:** 2026-09-12  
**Authority:** Founder “proceed” to correcting and internally checking the
local test script, without starting a database or uploading anything  
**State:** CODEX PREPARED → CODEX INTERNALLY VERIFIED; REAL EXECUTION HELD  
**Owner:** Codex / Astra; Founder sole approver  
**Action:** OA-ZYRA-286 remains open; no new identifier

## 1. Outcome

The successor V3 package corrects the executable-path defect proven in098.
It is frozen at manifest SHA-256:

`6975e5045da2e7635777f407f31f6197eedf356111727f7b82d4bfdccff5154f`.

Final internal suite: **55 tests PASS, 34.936s, exit0**. Shell syntax, four
Python ASTs and default hash-only package validation also pass. There was no
actual VM start, Docker daemon contact/container action, PostgreSQL start,
SQL execution, cloud/production/Apple operation, source rebuild or git command.
At14:51:12 BST the named VM still reported not running. Real execution-v3
is absent. These results do not establish database success or app delivery.

## 2. Exact change surface

New package in task workspace: `evidence/oa286-persona-offline-v3/`.

- container.sh uses fixed `/nix/var/nix/profiles/default/bin`, measured inside
  the exact pinned image in098. Caller environment cannot override PG_BIN/PATH.
  All four tools must be executable and report exactly PostgreSQL17.6.
- Username, temporary-directory permissions and absent data directory are
  explicitly checked. A dangling data-directory symlink is refused.
- Prerequisite failures name the guard; later failures name initdb,
  postgres_start or sql and retain the failing exit status.
- An early EXIT trap supports stage reporting. It performs the existing
  immediate stop only after a successful start; partial-start cleanup remains
  the outer runner's exact-owned container removal. Inner stop failure does
  not overwrite the SQL status; outer cleanup still must succeed.
- run.py changes only V3 ownership label/container prefix/one-use marker and
  inclusion of the new test file. Metadata/isolation checks, image/socket
  pins, resource limits, one create/start, SQL bytes and cleanup stay unchanged.
- test_runner.py changes only V3 identifiers; test_cli_templates.py is
  byte-identical. test_entrypoint.py is new. README records scope and limits.

All four SQL payloads are byte-identical to V2. Their success marker retains
its V1 name deliberately. No schema, Auth, product or signing code changed.
The image's normal entrypoint remains bypassed and startup remains Unix-socket
only, with listen_addresses empty and host authentication rejecting access.

## 3. Internal verification and honest limits

| Suite | Count | Method |
|---|---:|---|
| Wrapper | 27 | Mocked subprocess, temporary package copies, no daemon |
| CLI templates | 14 | Real installed Docker CLI against synthetic GET/HEAD-only Unix-socket fixtures; empty temporary config |
| Shell entrypoint | 14 | Host /bin/sh plus synthetic executable stubs and synthetic stdin, no PostgreSQL engine |

The new shell tests mechanically replace fixed executable/data/tmp-check paths
into unique /private/tmp fixtures before running the shell. They verify the
substitutions and prohibit real PG paths. The real shell has no test-override
hook. Coverage includes all four missing/non-executable/wrong-version/nonzero-
version tools, user mismatch, missing/non-directory/non-writable/non-searchable
tmp, existing data/file/dangling link, initialization/start/SQL failures,
one-time stop, original-status preservation and exact socket-only arguments.

The initial internal run reached55 tests and ended with one test-fixture
collector error: it attempted stat beneath the deliberately non-searchable
directory after the shell had exited. The collector now restores only that
fixture's search permission before inspecting it. No runtime repair occurred.
Initial log is retained; final full suite ran after the test file was frozen.
The test author's separate final stub-only check also passed14 tests.

An initial local apply_patch context mismatch changed no files; it was resolved
by reading the exact shell comments and applying the corrected local patch.
Neither this nor the fixture correction consumed a real database attempt.

Internal read-only review found no material static issue. It is not independent
approval. Remaining limits:

- Host-shell stub coverage does not prove the pinned image's actual shell,
  initialization, startup, library/configuration dependencies or SQL execution.
- The image's baked environment is inherited, not host environment. Unexpected
  PostgreSQL variables may cause the future isolated run to stop.
- run.py verifies the pinned inventory, not descriptive manifest fields. Root
  separately read and checked package/status/image/predecessor/diagnostic fields
  against the frozen code and records; they match.
- A future SQL PASS proves only the narrow persona harness's catalog/ACL,
  inert guards, limiter/audit/retention and rollback checks. Managed Auth,
  positive live-Founder/session authorization, concurrency, token expiry/replay,
  Edge/native access, full product replay and Apple delivery remain unproven.

No Flutter source changed; app tests/analyzer were not rerun or claimed as
fresh evidence by this local-runner work.

## 4. Hashes and true pre-states

Task root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/`.
V3 directory and new files originally ABSENT. Four copied files were snapshotted
before editing in `evidence/oa286-persona-v3-prestate.DFP52W/` (not reconstructed).
Its AUTHORITY.md records the scope and pre-state ledger.

| Edited copied file | True pre-edit SHA-256 |
|---|---|
| container.sh | `d9455cfe3d41eb3b08a46bd127c8feff5c4f207aa27ed7d79bfda7bc70cc3b9c` |
| run.py | `133892b03f8d7b4ed96d224799a864ceef6e2692489c4f812f1ed9606f1e9068` |
| README.md | `560a92727ba966284fa62487ea49eed58a89f37a49df7e72783d620e94a4ba9a` |
| test_runner.py | `c69a866d339c6803de77186d9ac1c4fe063857720a98fb68c38f03c56fcffe79` |

| Final V3 file | SHA-256 |
|---|---|
| bootstrap.sql, unchanged | `564e0cdde502438d841bec74055efc97cb61f59546129d04e37f51ef24e61e11` |
| boundary.sql, unchanged | `9a409b74ac3a3bddb33ddf2d5f76559261b4e70de369aaa763503ffaf89fadcd` |
| harness.sql, unchanged | `d24b12f2e17d72a17c8d74e1412f43906907efbfba37cbc6743b9d01486d8b93` |
| postcheck.sql, unchanged | `27f69c823b7633f5cf9c99296739339b1d04964010ebeff60c31235354611bb0` |
| container.sh | `15f642d841d366a61fbf10b0631625d6aab55e463e7c3c1ad7b9f156106cbe5b` |
| run.py | `0b5cfc0e55fe2596a27050f38bbdc8953024f296c88394786c2e566abdc98367` |
| README.md | `51bf30066f6fdc158dd619ee93370c2e7ca59b1c6e5e04db388dfc8bb24ce3fe` |
| test_runner.py | `a0399693fb6736a4ff7392ebf4a2de728f1cb9f7dbf05311ada0e00438ca2169` |
| test_cli_templates.py, unchanged | `3be3ac01abad605cc6bb47c0017e520ff7f2ae554942191873c1856392a93732` |
| test_entrypoint.py, new | `369e330cbf1c490813b5059efb75062814f07b9f87f69281041c5b95e1f9de4c` |
| manifest.json, new | `6975e5045da2e7635777f407f31f6197eedf356111727f7b82d4bfdccff5154f` |

Initial internal log `evidence/oa286-persona-v3-initial-tests.log`:
`d82183633fa4f8f2dce695420b3705ae735ae819c3682b08985dbcb3e4ee5d7f`.
Final internal log `evidence/oa286-persona-v3-final-tests.log`:
`0c2d699eee5ae5cd0819794f4e07a4f05cca18b1d710eed1ae9c588865c53177`.

V2 hash-only validation still passes its original manifest
`2f84c5e286c39bbeace7f105862e77536077b48fdacd13013a57614f984f486f`;
all six consumed V2 logs and result match097. V1 and diagnostic evidence remain
untouched. Neither failed execution marker was removed or reused.

Only existing canonical edit: appended preparation result to OA-ZYRA-286.
True pre-file:
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_V3_PREPARED_PRESTATE.MlBMhi/OUTSTANDING_ACTIONS_V2.md.pre`.
Register pre: `cb6c7d50c909d5aab18a109a5cd27c90aaa59c84a721504f098f7353e361455f`.
Register post: `6a8c9f1a1e4f43658ed0d398f769804e58c243de975145c1a8f741cea506fc2c`.
Report099 pre-state: ABSENT. OA next identifier remains287.

## 5. Exact next execution proposal — NOT AUTHORISED BY THIS PREPARATION

After a new Founder GO naming this V3 package:

1. Recheck manifest `6975e5045da2e7635777f407f31f6197eedf356111727f7b82d4bfdccff5154f`
   and all files, absence of real execution-v3, and named VM initially stopped.
2. Start only zyra-oa198 once, with mount none, port-forwarder none,
   ssh-agent false, ssh-config false, activate false, save-config false,
   kubernetes false, network-address false, network-host-addresses false,
   binfmt false. Required management SSH/control sockets/internal DNS remain.
   Verify no unrelated container before execution. No pull or new VM.
3. Invoke the unchanged frozen runner exactly once against its explicit
   local Docker socket and pinned image. It may create only one fresh
   network-disabled/read-only container and a fresh private temporary database.
   No existing database reset, product migration or production access.
4. Stop at the first result, drift, failure or timeout; no repair/retry.
   Verify fresh exact ID/name/label before removing only that owned container.
   Then verify inventory and stop only the VM started for this attempt.
   Preserve the consumed marker and all output; no broad cleanup.
5. Acceptance: exact package/identity/isolation, exit0 and exactly one final
   SQL marker, post-harness rollback checks, exact-container removal and VM
   shutdown. Anything else is STOPPED with evidence, not a partial PASS.

This bounded disposable check has no live-state rollback: discard only its
own container/tmpfs, preserve evidence and return the named VM to stopped.
No cloud project/Auth/role change, production data, Apple record/certificate,
build/upload or TestFlight distribution is included. ZYRA Test remains
undelivered; the existing ZYRA TestFlight app remains unchanged.
