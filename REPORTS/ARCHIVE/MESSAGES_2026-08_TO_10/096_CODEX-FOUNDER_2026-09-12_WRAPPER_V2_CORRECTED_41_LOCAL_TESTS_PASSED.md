# CODEX → FOUNDER — WRAPPER V2 CORRECTED / 41 LOCAL TESTS PASS

**Date:** 2026-09-12  
**Authority:** Founder “proceed” to correcting and locally testing the wrapper,
preserving the original and without another database attempt  
**State:** CODEX PREPARED → CODEX INTERNALLY VERIFIED; RUNTIME GO HELD  
**Owner:** Codex / Astra; Founder sole approver  
**Action:** OA-ZYRA-286 remains open; no new identifier

## 1. Outcome

V2 corrects the metadata reader that stopped 095. All **41 local tests PASS**:
27 mocked-wrapper tests and 14 real Docker CLI template tests against synthetic
temporary Unix-socket HTTP fixtures. V1's actual strict missing-key error is
reproduced; V2 handles the omitted field without weakening identity or safety
checks. This is local tooling proof, not a PostgreSQL test result.

No VM started, existing Docker daemon contacted, container created, database
executed, Supabase/production/Apple action performed, or git command used.
Both real execution markers and the named VM's Docker socket remain absent.
The original V1 package and reports 094/095 are preserved.

## 2. Bounded correction

- Optional image `Volumes` uses `index .Config "Volumes"` instead of strict
  `.Config.Volumes`. Absent/null is accepted; false/zero/string/list values are
  rejected. Only the two previously approved data-volume paths and empty-object
  declaration values pass.
- Optional container `Binds` and `PortBindings` use the same omission-safe
  approach. Required identity/ownership/state/mount/network/safety fields have
  strict types. Missing booleans cannot be inferred as safe defaults.
- Selected container `Id` forces raw-JSON template evaluation and must equal
  the exact returned create ID before start, after execution and before cleanup.
  Cleanup still requires a fresh exact ID/name/ownership-label match.
- V2 has a distinct one-use directory, container-name prefix and label. Tests
  join the manifest. Unused wrapper import removed. No other runtime command,
  allowed image, endpoint, resource limit or stop/retry rule changed.
- All five SQL/bootstrap/shell payloads remain byte-identical to V1; even the
  SQL PASS marker intentionally remains V1. No application or staged SQL source
  changed. V2 is new; V1 is not rewritten or reconstructed.

Primary formatting references: [Docker templates](https://docs.docker.com/engine/cli/formatting/)
and [Go template index](https://pkg.go.dev/text/template). The actual installed
CLI's behavior, not documentation alone, was exercised by the fixture tests.

## 3. Verification

Command from task workspace:

```sh
python3 -B -m unittest discover -s evidence/oa286-persona-offline-v2 -p 'test_*.py' -v
```

Result: **41 tests, 2.243 seconds, OK, exit 0**. The first fixture-only attempt
was blocked by sandbox Unix-socket binding before any CLI subprocess. The full
run then used exact command-scoped permissions for these synthetic local tests;
no VM/runtime execution authority was exercised or bypassed.

Coverage includes omitted/null/empty/valid/unknown/malformed metadata; actual V1
error reproduction; required-field failure; image/container identity mismatch;
environment canaries not rendered; hash/symlink drift; no subprocess in default
mode; immutable SQL-stream parity; exact isolation options; success/failure
one-use refusal; failure-before-create/start; no retries; exact cleanup versus
foreign-owner refusal; cleanup failure; timeout/nonzero exit/missing or duplicate
PASS marker. Mocked state-machine tests cannot create a real process: subprocess
is replaced in-process. CLI fixtures serve only synthetic GET/HEAD responses,
reject writes, and use empty temporary configs with an exact fixture socket.

Also PASS: shell syntax; Python imports/AST; all five V1/V2 payload hash pairs;
V1 hash-only validation; V2 hash-only validation. Final read-only internal review
found no material finding. It is internal review, not external approval.

Flutter/analyzer/visual suites were not rerun: no app source changed. The prior
656-test/analyzer result in 093 remains historical, not a newly executed suite.
Real cached-image metadata, PostgreSQL binaries and SQL behavior remain unproven.
Both SQL harnesses remain UNRUN; all broader Auth/Edge/Apple gates remain open.

## 4. Final package and evidence

Package path:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-persona-offline-v2/`.

**V2 manifest SHA-256:**
`2f84c5e286c39bbeace7f105862e77536077b48fdacd13013a57614f984f486f`.

| File | SHA-256 |
|---|---|
| bootstrap.sql | `564e0cdde502438d841bec74055efc97cb61f59546129d04e37f51ef24e61e11` |
| boundary.sql | `9a409b74ac3a3bddb33ddf2d5f76559261b4e70de369aaa763503ffaf89fadcd` |
| harness.sql | `d24b12f2e17d72a17c8d74e1412f43906907efbfba37cbc6743b9d01486d8b93` |
| postcheck.sql | `27f69c823b7633f5cf9c99296739339b1d04964010ebeff60c31235354611bb0` |
| container.sh | `d9455cfe3d41eb3b08a46bd127c8feff5c4f207aa27ed7d79bfda7bc70cc3b9c` |
| run.py | `133892b03f8d7b4ed96d224799a864ceef6e2692489c4f812f1ed9606f1e9068` |
| README.md | `560a92727ba966284fa62487ea49eed58a89f37a49df7e72783d620e94a4ba9a` |
| test_runner.py | `c69a866d339c6803de77186d9ac1c4fe063857720a98fb68c38f03c56fcffe79` |
| test_cli_templates.py | `3be3ac01abad605cc6bb47c0017e520ff7f2ae554942191873c1856392a93732` |

Complete local-test output is adjacent at
`evidence/oa286-persona-offline-v2-local-tests.log`, SHA-256
`5a9d207e3d9fc31daac948f7e762d469479cae186c6253235b3f0cdcc812f934`.

The only existing canonical edit is an appended OA-ZYRA-286 update. Its true
pre-file was copied before edit to
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_WRAPPER_V2_PRESTATE.iyFek1/OUTSTANDING_ACTIONS_V2.md.pre`.

- Register pre: `da003d489a442b3cf7390c36a268b908b02e687a08181aeb6c9866d85ab9530b`.
- Register post: `0afa75e6344d06b913325c17c2dd9b1e99aece4f4ac9c360e690cc06ff244574`.
- V2 directory, test log and report 096 pre-state: ABSENT; new artifacts.
- Preserved V1 manifest: `9f3fc926dec059fd2035173ab235cb395365cb7832da02b0fc03a1ffc1ecfd9d`.

## 5. Next proposed exact action — NOT AUTHORISED by this report

One isolated PG17 check using the V2 manifest above: start only the stopped
`zyra-oa198` VM with adequate command-scoped permissions and the same no-host-
mount/application-forwarding/SSH-agent/binfmt/Kubernetes settings; verify no
unrelated containers; invoke the V2 runner once; remove only its fresh,
label/ID/name-verified container; stop the VM. No existing database reset,
image pull, cloud action, production access, Apple upload, repair or retry.
On any startup/preflight/SQL/cleanup drift or failure: stop and preserve evidence.
Ambiguous cleanup requires manual action, not a guessed deletion.

Prospective execution command, only after new exact Founder GO:

```sh
python3 -B "/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-persona-offline-v2/run.py" --expected-manifest-sha256 2f84c5e286c39bbeace7f105862e77536077b48fdacd13013a57614f984f486f --execute-once
```

The SQL proof remains narrow: no positive live-Founder/session branch, real Auth,
concurrency, native app, fifteen-RPC overlay, full schema replay or Apple proof
is implied. ZYRA Test is not yet delivered to TestFlight.
