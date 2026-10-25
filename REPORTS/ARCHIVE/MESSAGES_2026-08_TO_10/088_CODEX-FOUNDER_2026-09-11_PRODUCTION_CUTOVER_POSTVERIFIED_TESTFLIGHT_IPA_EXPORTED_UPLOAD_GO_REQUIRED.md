# 088 — CODEX → FOUNDER — Production Cutover Post-Verified / TestFlight IPA Exported / Upload GO Required

**Date:** 2026-09-11
**From:** Codex, Operating Partner under AD-AIOS-109
**To:** Founder (Shakeel)
**Status:** EXECUTED / POST-VERIFIED / IPA LOCALLY VERIFIED / APPLE UPLOAD NOT AUTHORISED
**Scope:** OA-ZYRA-283; DR-ZYRA-227 temporary OA-ZYRA-156 hold; Founder-only internal TestFlight

---

## 1. Outcome

The exact production cutover authorised by the Founder completed successfully
on Supabase project `sxoaxonzjqkgajmlagyk` (ZYRA-APP-LAB's Project, EU West).
Both approved migrations were applied atomically, byte-identically and in the
approved order. Every production post-apply check passed. ZYRA remained
closed.

A fresh post-cutover ZYRA `1.0.0 (2)` archive and internal-only IPA were then
created and verified locally. App Store Connect still reports `No Builds` and
no internal-testing group. No Apple upload occurred. The production Apply GO
is consumed; the Apple Upload GO remains a separate unconsumed gate.

## 2. Exact authority consumed

The Founder authorised one production cutover naming:

1. `SOURCE/supabase/migrations/20260910184252_oa283_journey_compatibility_rpc_boundary.sql`
   — SHA-256
   `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d`.
2. `SOURCE/supabase/migrations/20260910195642_oa156_request_new_journey_testflight_hold.sql`
   — SHA-256
   `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545`.

The authority allowed no other migration or Apple upload and required a hard
stop on drift or failed verification, with no retry or repair without new
exact authority. No other production migration was applied and no Apple build
was transmitted.

## 3. Final preflight — passed

Immediately before execution, production was re-read and matched the approved
pre-state:

- exact active project, EU West health and PostgreSQL `17.6`
  (`server_version_num=170006`);
- both target migration versions absent;
- existing Plus function body, owner and ACL exact;
- both new OA-ZYRA-283 RPCs absent;
- `journey_compatibility` RLS, policies and grants exact;
- three compatibility rows and zero attempt-binding mismatches;
- all four Request New Journey function bodies, owners and ACLs exact;
- zero journey requests, zero request notifications and zero multi-attempt
  matches;
- `journey_requests` RLS/write boundary exact; and
- every harness fixture premise exact, including actors, roles, active attempt,
  compatibility binding, onboarding rows and absence of an active Guardian.

The migration files were freshly re-hashed before use. The OA-ZYRA-283 file
was 14,845 bytes (MD5 `5c4d3202b9db02b9070e6efb74ade047`); the hold file
was 7,823 bytes (MD5 `e70f60940936657f7288a10b7005c57d`).

## 4. Atomic ordered apply — passed

Both exact migration bodies and both exact migration-history rows executed
inside one PostgreSQL transaction. Database-side byte-length and MD5 guards
verified the received bodies before execution. The transaction committed only
after both bodies and their history rows succeeded.

History identity after commit:

| Version | Name | Statements | SHA-256 of recorded statement |
|---|---|---:|---|
| `20260910184252` | `oa283_journey_compatibility_rpc_boundary` | 1 | `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d` |
| `20260910195642` | `oa156_request_new_journey_testflight_hold` | 1 | `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545` |

No migration repair, CLI push/pull, replay bridge or unrelated production
write was used.

## 5. Transactional harnesses and concurrency — passed

- OA-ZYRA-283 exact rollback-only live harness passed with no errors.
- OA-ZYRA-156 hold exact rollback-only live harness passed with no errors.
- A real two-session reveal probe used separate production backends (PIDs
  `1313321` and `1313322`) with approximately 11.858 seconds of overlap.
- The final mutual state had both reveal flags true and a joint timestamp.
- Repeating the A-side call was idempotent: the exact row digest remained
  `fc2af11f1e722a4af482ac8b0afa00b3`.
- The exact original fixture row was restored; restored-row MD5 was
  `6ab6dc02dc37601e4d9d3efaefdd73a9`.
- After restoration: compatibility row count `3`, journey requests `0`,
  request notifications `0`, multi-attempt matches `0`.

The concurrency probe was run once and was not retried.

## 6. Complete final production verification — passed

Final read-only verification completed at `2026-09-11 22:00:58 UTC`:

- exactly one history row and one statement exist for each approved version;
- database-side SHA-256 of both recorded statements matches the approved
  files;
- `journey_compatibility`: RLS enabled, FORCE RLS off, zero policies,
  PUBLIC/anon/authenticated have no table or column privileges, and
  `service_role` retains its intended administrative access;
- all three governed Compatibility RPCs have owner `postgres`,
  `SECURITY DEFINER`, empty `search_path`, exact volatility and exact ACL;
- all four Request New Journey RPCs retain their exact bodies and owner /
  definer posture; PUBLIC, anon and authenticated execution is denied while
  `service_role` remains;
- expiry/restart out-of-scope ACLs are unchanged;
- the `journey_requests` boundary is unchanged;
- data-integrity and zero-state checks pass;
- the restored concurrency fixture matches its original digest;
- Seeker A application-health state is correct (`mine_revealed=true`,
  `counterpart_revealed=false`, `my_score=NULL`);
- null caller fails with SQLSTATE `42501` / `not_signed_in`; and
- non-party caller fails with SQLSTATE `42501` / `not_a_party`.

Final measured counts: migration-history rows `206`, compatibility rows `3`,
journey requests `0`, request notifications `0`.

## 7. Advisor comparison — no unexpected delta

Security advisors after apply:

- RLS enabled with no policy: `12` INFO — expected `+1` for the intentional
  RPC-only compatibility table;
- security-definer view: `1` ERROR — pre-existing audit bucket;
- authenticated executable definer functions: `87` WARN — expected net `-2`
  (`+2` governed OA-ZYRA-283 calls, `-4` held request calls);
- leaked-password protection: `1` WARN — pre-existing.

Performance advisor counts were unchanged: unindexed foreign keys `11`, no
primary key `4`, unused indexes `20`, multiple permissive policies `5`.

## 8. Local client/release gates — passed

- focused release/migration tests: `17/17` passed;
- `flutter analyze --no-pub`: no issues;
- `python3 tools/zyra_check.py`: 186 files, 0 findings;
- `python3 -m unittest tools/test_zyra_check.py`: 1 passed;
- governed release-file hashes remained exact; and
- the retired build-1 IPA remains unchanged at SHA-256
  `4685a31b2e2159d07777ffba8c729b2d371a6d96256c57e7eccb2a8abe074815`
  and remains forbidden for upload.

One redundant combined shell invocation could not let Flutter write its cache
inside the restricted shell. The same focused release test had already passed
in the dedicated 17/17 run; this was an execution-environment limitation, not
a source or test failure, and no repair or source change followed.

## 9. Fresh signed archive and IPA — passed locally

Release root:

`/private/tmp/zyra-testflight-internal-1.0.0-build2-20260911-postcutover-63381feb-0ac36fd4`

The archive succeeded and passed independent system-trust inspection. The
first restricted-shell signature check returned `CSSMERR_TP_NOT_TRUSTED`
because that shell could not read the host Keychain trust chain; the host
reported two valid Apple Development identities, and an independent deep /
strict system-trust check passed without changing any signing state.

Export succeeded using the governed internal-only options. Xcode logged a
non-fatal store-configuration warning for account `(null)` saying no provider
was associated; it nevertheless exported and cloud-signed the IPA. This is
recorded for the upload boundary rather than silently discarded.

Verified IPA:

- path: `/private/tmp/zyra-testflight-internal-1.0.0-build2-20260911-postcutover-63381feb-0ac36fd4/export/ZYRA.ipa`;
- size: `24,223,924` bytes;
- SHA-256:
  `1e17a1c3475db1bcb01e59415768d94480538bb601aedcdc8fdd706ea1a7b673`;
- ZIP integrity: passed;
- display name: `ZYRA`;
- bundle: `app.zyraconnect.zyra`;
- version/build: `1.0.0 (2)`;
- minimum iOS: `13.0`;
- non-exempt encryption declaration: `false`;
- architecture: arm64;
- deep/strict signature: passed;
- signing authority: `Apple Distribution: Shakeel Ahmad (9Y7Z8F36SJ)`;
- Team: `9Y7Z8F36SJ`;
- entitlements: exact application/team identifiers,
  `get-task-allow=false`, `beta-reports-active=true`, Sign in with Apple
  `Default`;
- Store provisioning profile:
  `iOS Team Store Provisioning Profile: app.zyraconnect.zyra`, UUID
  `07c3e51d-0bc9-41a9-8b54-ce5be5c94a19`, expires
  `2027-09-10T16:38:26Z`; and
- DistributionSummary: build `2`, version `1.0.0`, Cloud Managed Apple
  Distribution, exact Team and entitlements.

The exported `ExportOptions.plist` is byte-identical to the governed file at
SHA-256 `665805d3130b65c6b5344ff360d15501aa85b27ad4827d3f53ad3ce2bc003cc9`.

## 10. App Store Connect read-only truth

Authenticated App Store Connect was re-read after export:

- app record: `ZYRA Connect`;
- Apple ID: `6810741513`;
- bundle carried by the verified IPA: `app.zyraconnect.zyra`;
- TestFlight: `No Builds`;
- internal-testing groups: none.

No Apple record, tester group, metadata or build was changed.

## 11. Current gate

Production is post-verified and ZYRA remains closed. The exact IPA is locally
ready, but TestFlight is not yet live because the current Founder authority
explicitly prohibited Apple upload.

The next authority, if the Founder chooses to issue it, must bind the exact IPA
path and SHA-256, Apple ID `6810741513`, Team `9Y7Z8F36SJ`, bundle
`app.zyraconnect.zyra`, version/build `1.0.0 (2)`, internal-only Founder
distribution, and `ITSAppUsesNonExemptEncryption=false`. It must forbid
external testers and public release and stop on source/artifact/signing/portal,
agreement, authentication or build-number drift.

## 12. Durable-file ledger

True pre-state snapshots were copied at edit time under:

`/private/tmp/zyra-testflight-internal-1.0.0-build2-20260911-postcutover-63381feb-0ac36fd4/governance-prestate`

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `4b142f78618288bd2a274a86780800758361681bd67e81fe2aa180c0fa3228cd` | `b2657f436d2f3251b98d7111fa9f7361833ab388ce11054ade023b76ec723d20` |
| `SYSTEM/DOCUMENTS/ZYRA_JOURNEY_COMPATIBILITY_BOUNDARY_HANDOVER_CURRENT_VERSION_V1.md` | `43e46eeb2df207a9eaba47a6ba148e3c92f93290d3436ef34f175f09413ca89a` | `443641dbf84dd68c261c181bc51a8252247b85810e6296969ae0d03dbfb6c8c9` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V1.md` | `c76795d163c758443327b36d3dd3234958189d28a38fd9e2a9a10a26551c8e1c` | `898c5b8645e755507a784962638f17d4a58ce16b20074e9f01d5662c295339cf` |
| `CLAUDE.md` | `72dbd1dca138fe7895870136ae102109e583251de70f4fe08dc646860125c9f1` | `5182941c14dfc0ceef6e463b5848512f118c303330e51eb6d8eaa9445322aa69` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V3.md` | `ba14f4dd00e8d05c7c60b8517c2635aecd4d5be5d1bb383f14b33314b76f0f80` | `e9d6b11a533c7db2fd442463b70db5ca97378b022231547cc4ffec5575140fc2` |

The message file was absent before this filing. No source, migration or
approved visual baseline was edited. No git command was run.

---

**End state:** PRODUCTION CUTOVER EXECUTED AT EXACT HASHES / ATOMIC ORDER
PRESERVED / COMPLETE POST-APPLY VERIFICATION PASSED / ZYRA CLOSED / FRESH
INTERNAL-ONLY IPA LOCALLY VERIFIED / APP STORE CONNECT NO BUILDS / NO APPLE
UPLOAD / SEPARATE EXACT UPLOAD GO REQUIRED.
