# CODEX → FOUNDER — OA-ZYRA-286 DENO VERIFICATION AND LIVE PREFLIGHT

**Date:** 2026-09-12  
**Status:** LOCAL VERIFICATION EXTENDED / LIVE GATES HELD  
**Authority:** Founder continuation instruction; DR-ZYRA-228 local implementation scope  
**Owner:** Astra / Codex; Founder remains sole approver  
**Owning action:** OA-ZYRA-286 — remains open; no new OA or ruling

## 1. Outcome

The previously unrun Deno checks now have real execution evidence. The first
runs exposed two local typing defects; both are corrected. All 11 pure policy
tests pass, with type-checking enabled. The Edge entrypoint type-checks against
the unchanged pinned Supabase SDK. This is internal verification, not external
review, approval, deployment, or end-to-end Auth proof.

Message 090 is preserved as its earlier snapshot. Its Deno-unavailable/unrun
statements are superseded by this report; its live gates remain held.

## 2. Exact source corrections

1. `SOURCE/supabase/functions/zyra-founder-persona-session/policy_test.ts`:
   change one positive assertion from `?.allowed` to `?.allowed === true`.
   The original was `boolean | undefined`, rejected by `assert(boolean)`.
   An absent parsed result still fails the assertion; no test is removed.
2. `SOURCE/supabase/functions/zyra-founder-persona-session/index.ts`:
   import the SDK's `SupabaseClient` type and use it for the two helper
   parameters previously declared `ReturnType<typeof createClient>`.
   The uninstantiated generic inferred an unusable schema and caused 16
   TS2345 diagnostics. The SDK's default client type matches the actual
   unparameterized `createClient` calls. No cast or suppression was added.

No runtime authorization predicate, HTTP response, RPC payload, SQL, Dart/UI,
resource pin or signing setting changed. A second Codex agent reviewed the
helper correction against cached SDK 2.112.2 source; that is internal review,
not independent external approval.

## 3. Runtime and verification

Deno 2.9.6, TypeScript 6.0.3, aarch64-apple-darwin was downloaded temporarily
from the official `denoland/deno` GitHub release. Archive SHA-256 matched its
published asset digest:
`213a2f304f04d3c9cb5220669afad138f60a5aab1fe80962abdeb8f35807a472`.
It is not installed on PATH or into a system package manager. Runtime/cache:
`/private/tmp/zyra-oa286-deno.3qb6gY/` (temporary, not durable infrastructure).

Working directory: `SOURCE/supabase/functions/zyra-founder-persona-session`.
Commands used `DENO_DIR=/private/tmp/zyra-oa286-deno.3qb6gY/cache` and
`DENO_NO_UPDATE_CHECK=1`:

```sh
deno test --no-config --no-lock --no-npm --no-remote --cached-only --no-prompt --deny-net --deny-env --deny-write --deny-run --deny-ffi --deny-sys --deny-import policy_test.ts
deno check --config deno.json --no-lock --node-modules-dir=none index.ts
```

- First policy run: type-check FAIL, TS2345 at line 359; no tests ran.
- Corrected policy run: 11 PASS / 0 FAIL, type-check enabled.
- First entrypoint check: FAIL, 16 related TS2345 diagnostics.
- Corrected entrypoint check: PASS / exit 0, using `--cached-only` after the
  pinned SDK and transitive dependencies had been downloaded to temporary cache.
- Final policy rerun after the entrypoint correction: 11 PASS / 0 FAIL.
- No `--no-check`, permission broadening, assertion removal or SDK update.

The tests run with no runtime network/environment/write/subprocess permissions;
the Deno test runner itself writes its JUnit output to a named temporary path.
They do not execute the HTTP handler or contact a database/Auth service.
The full Flutter suite, analyzer and visual suite were not rerun: their
message-090 measurements remain historical, not fresh claims. Only TypeScript
typing/test code changed. Both staged SQL harnesses remain UNRUN, not failed.

Durable final JUnit: `SYSTEM/RESOURCES/TEMPORARY/
OA-ZYRA-286_2026-09-12_DENO_PRESTATE.2YovVg/policy-final-junit.xml`, SHA-256
`54a6c864a7d1fe1ff4cd46aa5f0f4e937ead29b5522cf9936331ca18994aee31`.

## 4. True pre-state and final ledger

Before each edit, the actual file was byte-copied and its SHA-256 checked at:
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_DENO_PRESTATE.2YovVg/`.
Snapshots use the original basenames plus `.pre` so they cannot be mistaken for
active source/current documents; bytes are preserved and none were reconstructed.

| File (relative to ZYRA) | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/supabase/functions/zyra-founder-persona-session/policy_test.ts` | `f3a5df3e57eda3641e743b1281eb2802bfce357b4d57dc6875cb6e5832c372ba` | `cdd40955d476e30162d188e71a44b74523b94fbc7eb851495d6e89a7e353c084` |
| `SOURCE/supabase/functions/zyra-founder-persona-session/index.ts` | `5f552948e83bc692d2ab0d7bfbf118dd741e03a43bd14dd1f325c00191241e04` | `b440c0b04fb9d3754f050d0208023bfd974898e37dcb69c7f6fd5dd8c72aa98f` |
| `SOURCE/supabase/functions/zyra-founder-persona-session/README.md` | `b3e355cee3e13c49a771cdff29a59edb86f9fde969114aa63d81503b5530555e` | `1f60d7fdad3850f8617e45c5334104135e27e8ff532dffc2ca69726a27e6699f` |
| `SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md` | `dad505fa498e7cd99302efeaeb4146d0a8b2cb2301303f24aa44669aac51f6d8` | `b223bb5e70ac54ca186fdd5e9c2626f15103ec3b02dbf29d4ed5ab40337d1140` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md` | `b3372386125c533ac2cfd2e2db8cc4d90282519b85725a6ae3dcd5e4a18f434e` | `3651b7895f0425bb074484dbf870a4884119a678bfb433576629f35c0f2ab5d1` |

The unchanged policy hash remains
`9a9c480ff7411d455465ef86fc52f34dcc8a181184003597055e61ee37ec05f9`;
the unchanged dependency config is
`adf9df9da776a91804688fa85b87abdc049201a4ab65d32a1919e1625cb0b909`.
This message is a new report (pre-state ABSENT).

## 5. Read-only external preflight

- Supabase lists one organisation, `ZYRA-APP-LAB's Org`
  (`pdekarsldtaqlqdthgwh`), and only the existing production project
  `sxoaxonzjqkgajmlagyk` in EU West, status `ACTIVE_HEALTHY`.
  No separate staging project exists in the accessible project inventory.
- App Store Connect's authenticated Apps page shows only `ZYRA Connect`,
  Apple ID `6810741513`. No Test record is listed. The New App menu was opened
  and dismissed; no create form was submitted or record changed. This is not
  a bundle-ID availability/reservation claim or a fresh build-2 TestFlight check.
- Supabase's current changelog/docs were consulted. New-project Data API
  exposure/grant behavior must be explicitly verified during the later replay;
  old project defaults cannot be assumed. No project/provider setting changed.

## 6. Remaining scope and authority

The Founder has been asked to confirm the recommended one-use test-account
Auth exchange and documented session-check limitation, plus the organisation
for proposed staging preparation. No answer is assumed from preselected UI
choices. Cost must be shown and confirmed before project creation.

OA-ZYRA-286 remains LOCAL FOUNDATION COMPLETE / LIVE GATES HELD. Its existing
unfinished staging, fixture, Auth, SQL/Edge, OAuth and Apple delivery work is
unchanged; this report records completion of a local verification subtask, not
an OA closure or a new authority gate. No outside reviewer is automatically
required. No production data was queried or changed, no SQL/reset/replay ran,
no service was started, no account/role/provider changed, no signing/archive/
upload occurred, no approved pixels changed, and no git command ran.
