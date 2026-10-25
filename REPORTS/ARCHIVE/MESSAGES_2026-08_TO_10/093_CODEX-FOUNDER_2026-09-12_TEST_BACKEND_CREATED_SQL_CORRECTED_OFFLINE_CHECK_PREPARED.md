# CODEX → FOUNDER — EMPTY TEST BACKEND CREATED / SQL CORRECTED

**Date:** 2026-09-12  
**State:** PROJECT EXECUTED → POST-VERIFIED; LOCAL SQL INTERNALLY VERIFIED; OFFLINE EXECUTION PREPARED, AWAITING GO  
**Authority:** Founder: “so continue so both are avaliable”, following the exact empty-project proposal and zero-monthly-cost quote  
**Owner:** Astra / Codex; Founder sole approver  
**Action:** OA-ZYRA-286 remains open; no new OA or decision identifier

## 1. Outcome

The separate **ZYRA Test** backend now exists and was independently re-read
after creation. It is empty and healthy. Production ZYRA and its existing
internal TestFlight build 2 were not changed. ZYRA Test is **not yet on
TestFlight**: application schema, Auth/provider setup, source pins, security
runtime proof, Apple identity, signed build and upload remain unfinished.

Local preparation also caught seven invalid SQL conditional-expression calls
before any package reached a database. The narrow correction and regression
test pass. The full non-visual Flutter suite is **656 PASS / 0 FAIL** and the
full analyzer is clean. A minimal offline persona SQL proof package is prepared,
not executed; a separate exact approval question has been shown to the Founder.

## 2. Exact project creation and post-verification

| Field | Verified result |
|---|---|
| Name | `ZYRA Test` |
| Project/ref | `xqweloifosbwfgctzros` |
| Organisation | `ZYRA-APP-LAB's Org`, `pdekarsldtaqlqdthgwh` |
| Region | `eu-west-1`, EU West (Ireland) |
| Quote immediately before creation | `{"type":"project","recurrence":"monthly","amount":0}` |
| Creation calls | Exactly one; no retry |
| Separate get-project check | `ACTIVE_HEALTHY`; PostgreSQL `17.6.1.166`, engine 17 |
| API-reported created_at | `2026-09-12T11:10:32.999669Z` (service metadata, not an inferred execution-clock timestamp) |
| Public tables/views/sequences/foreign tables | 0 |
| Public functions | 0 |
| Auth users / sessions | 0 / 0 |
| Storage buckets / objects | 0 / 0 |
| Security advisors | `lints: []` on the empty project |

The pre-create inventory listed only Production. A fresh post-create inventory
lists both separate project references; Production remains `ACTIVE_HEALTHY`.
No production database query or write was performed. The empty-state query was
count-only on Test; it read no personal row content. No key, password, token or
secret was requested, copied or recorded. There was no plan upgrade or payment.
The creation GO is consumed and does not approve later schema/Auth/Apple work.

Empty-state query:

```sql
SELECT current_database() AS database_name,
       current_setting('server_version') AS server_version,
       (SELECT count(*) FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname='public' AND c.relkind IN ('r','p','v','m','f','S')) AS public_relations,
       (SELECT count(*) FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
        WHERE n.nspname='public') AS public_functions,
       (SELECT count(*) FROM auth.users) AS auth_users,
       (SELECT count(*) FROM auth.sessions) AS auth_sessions,
       (SELECT count(*) FROM storage.buckets) AS storage_buckets,
       (SELECT count(*) FROM storage.objects) AS storage_objects;
```

## 3. Staged SQL defect, correction and local verification

Internal preparation found `pg_catalog.coalesce(...)` in two still-unapplied
files: two calls in the persona rate limiter and five in the developer-RPC
overlay's diagnostic/authorization expressions. PostgreSQL treats COALESCE as
a conditional expression, not an ordinary schema-qualified function. Primary
reference: [PostgreSQL 17 conditional expressions](https://www.postgresql.org/docs/17/functions-conditional.html).
A read-only Test query returned `COALESCE(NULL::integer,1) = 1` and confirmed
there is no `pg_catalog` function named `coalesce` in `pg_proc`.

Changed only those seven `pg_catalog.` qualifiers in SQL. No table, grant,
search path, identity/role predicate, rate-limit value, response contract or
sentinel changed. The two packages remain outside active migrations, unassigned
and unapplied. This is a local defect correction, not a schema apply or new
security design ruling.

Added one regression to `zyra_founder_persona_staging_sql_test.dart` covering
both staged files and refusing catalog-qualified COALESCE/NULLIF/GREATEST/LEAST.
It also retains checks for the empty search path and native COALESCE syntax.

- Before SQL correction: the new regression FAILED on the existing persona
  source, as expected; no SQL executed.
- After correction: all four focused tests PASS; Dart format reports no change.
- Full analyzer: `flutter analyze --no-pub`, no issues, exit 0.
- Full non-visual suite: `flutter test --no-pub test/*_test.dart`, 656 PASS,
  0 FAIL, exit 0. One added test accounts for the prior 655 → 656 count.
- Environment interruptions are not hidden: analyzer/full-suite startup first
  encountered sandbox cache/telemetry permissions; another full-suite attempt
  could not bind its local loopback sockets and was cancelled. After narrowly
  granted cache/loopback access, the complete run above passed. These were not
  database executions and consumed no one-use SQL authority.
- Visual tests were not rerun for a staged SQL/test-only correction; the prior
  275-pass/60-known-mismatch snapshot remains historical. No pixels changed.
- Both SQL runtime harnesses remain unrun; no runtime pass is inferred from
  text tests or the read-only conditional-expression query.

## 4. Prepared next check — no reset or cloud connection

New task-local evidence package:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-persona-offline-v1/`.

Manifest SHA-256:
`9f3fc926dec059fd2035173ab235cb395365cb7832da02b0fc03a1ffc1ecfd9d`.
Runner SHA-256:
`5882b29cf790f67234ffa1878f6b1e5609fb37f6eebb90b537abe8b9ae579484`.

The manifest pins the runner, README, shell entrypoint, minimal bootstrap,
corrected boundary, unchanged full 441-line harness and final rollback check.
The boundary copy matches canonical SHA-256 `9a409b74ac3a3bddb33ddf2d5f76559261b4e70de369aaa763503ffaf89fadcd`;
the unchanged harness matches `d24b12f2e17d72a17c8d74e1412f43906907efbfba37cbc6743b9d01486d8b93`.
Shell syntax, Python AST, manifest verification and source-copy parity pass.
Root read the complete runner/bootstrap/harness and its boundaries. Preparation
and review are internal, not an external approval or an execution result.

Proposed execution starts only the existing named `zyra-oa198` Colima profile,
with host mounts, SSH-agent forwarding and port forwarding disabled and without
changing the default context. It must contain no unrelated running workload.
The runner uses its explicit local socket and only cached immutable image
`sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518`
(historical PostgreSQL 17.6.1.165). No image pull or runtime upgrade is allowed.
The managed Test project is 17.6.1.166; this is narrow SQL proof, not complete
managed-service equivalence.

Exactly one new container is permitted: network none, no published port, no
host mount, read-only root, tmpfs data, PostgreSQL user, dropped capabilities,
no-new-privileges. Fresh `initdb` never reuses or resets an existing database.
The SQL stream is minimal auth-shaped test doubles → exact staged boundary →
exact existing harness → rollback check. No Auth service or product migration
replay is included. Stop on first failure/drift; no SQL repair/retry. Cleanup
removes only the exact newly created, label-verified container, then the outer
operator stops the VM it started. The one-use execution directory is retained.

The VM was verified stopped, its socket absent. Cached image presence and
runtime binary paths cannot be verified until an approved start. No VM,
container or SQL test has been started. Earlier OA-ZYRA-198 reset authorities
remain consumed; this new proposal does not reuse them.

A pass would prove catalog/ACL shape, inert public guards, deterministic limiter
boundaries, aggregate audits, retention and rollback. It would not prove positive
Founder/session authorization, actual role-switched denial, concurrency,
managed Auth, token expiry/replay, Edge invocation, fixture IDV, the fifteen-RPC
overlay or Apple delivery. Those remain tracked under OA-ZYRA-286.

Prospective invocation, **only after the exact execution GO**:

```sh
python3 "/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-persona-offline-v1/run.py" --expected-manifest-sha256 9f3fc926dec059fd2035173ab235cb395365cb7832da02b0fc03a1ffc1ecfd9d --execute-once
```

## 5. True pre-state and complete canonical ledger

Every changed existing file was snapshotted before its edit under
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_STAGING_CREATE_PRESTATE.FScXS3/`.
No pre-file was reconstructed. Paths below are relative to ZYRA.

| File | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `b7049be77e547e248dbc4623c105be0887782c8cc360033a13e97ebb373cb0b0` | `f1ec22d4e618ef0fedeb509dc705085de70463c586545f76860bc6b044dc0af8` |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md` | `f3e13b0f70c75d3b549e41f721324a7934c0244c52f9ab9b59f2e6b4aa8bcc93` | `25a02a164e822f28f252c1162df71b741aa4a609af518fd64f02707c20f0acb2` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md` | `63a0948d7469391e6727608b0067b682d868def2bcd799eef489de536e1666b7` | `3754873103e65ce9c7ceb34588d77c4688ba5304e911f63180abaa6c153b81bd` |
| `SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V3.md` | `c6583a712a3d15b43b3cb777f1ee3ddfceb2b7df0a34caf83e3584b24a56e35c` | `845b096c956e7718544b1d12c9eb556a3494520c96aab363503a448a18d1bcaf` |
| `APP/Authentication/Summary.md` | `008a9aeeb30c74f657e51a9acfbf0962c6b940f33023e394d8de722f05d5d600` | `dcaf247798fba2db7c226277abcdb4e35e3198115f47db001c47c98f7380e1a4` |
| `APP/Authentication/Script/Script_V3.md` | `9176c1a29c843e38c844f2b7ecc511fb850e743e1e1c56e6a733adec7a9c88a3` | `096d2188690a605e9253afd2108951d0dbc9bb7f5d25bf9de1851afcfdd5d7d7` |
| `APP/Developer Mode/Summary.md` | `21f982fb5d31080d60066895b5158c123020d4860aafb434848842bd61f9fe14` | `c314f311be9b8e9c45ba45b43d0aa4da75729afcaa7be6e95545208e07c76f15` |
| `APP/Developer Mode/Script/Script_V4.md` | `a34e4b234607f8a8427548f86f88304d76bae66eb0985184bf22cae695be4c2d` | `cc419f4bbc0f50fd85ed6153ea8d4bb147fb63561ce4b10784dfea6f1793e5e7` |
| `SOURCE/supabase/staging/founder_persona/zyra_founder_persona_security_boundary_STAGED.sql` | `8501da59ce97e2277115764bcbdc518f04379f6f71269f0ece432a5c99908f02` | `9a409b74ac3a3bddb33ddf2d5f76559261b4e70de369aaa763503ffaf89fadcd` |
| `SOURCE/supabase/staging/dev_rpc_hardening/zyra_test_dev_rpc_security_overlay_STAGED.sql` | `a9a97cd70da732f98115ceb4f886c436f4faa2f5f7c5b1060f750284a1b58314` | `1a7d013c81184ce382f0fb107b0472410777d5c530470157c9b9b33fd7f9718f` |
| `SOURCE/test/zyra_founder_persona_staging_sql_test.dart` | `4b74af9625eb62d0788e2cce4b23129ab990ab6ada45878cd7722f568dadc353` | `d3f90a9f798b857d14344d648bac9528bb688864e84bdce15ffcfc46c8605bbb` |

Snapshots use each original basename plus `.pre`, except feature duplicates
prefixed `Authentication_` / `Developer_Mode_`. The new offline package and
this report have pre-state ABSENT. Message 092 is preserved as its earlier
pre-creation snapshot. No active migration, runtime app/Edge source, source
resource pin, signing file, approved image or git state was changed.

## 6. Handover boundary

The sole external mutation was the one empty-project creation. Read-only
post-verification is not authorization to populate it. Source corrections are
staged only. No account/role/credential/provider change, SQL migration apply,
database reset, image pull, Apple registration, archive, upload, external tester
or public release occurred. OA-ZYRA-286 remains open until actual secure delivery
and Founder acceptance, not merely preparation or documentation completion.
