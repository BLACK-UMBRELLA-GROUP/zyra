# 130 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 security revision and fresh replay passed; exact production apply gate remains  
**Decision / action:** DR-ZYRA-221 / DR-ZYRA-231 / OA-ZYRA-288 / OA-ZYRA-289  
**Status:** INTERNALLY VERIFIED; BOTH SEPTEMBER 17 MIGRATIONS STAGED; PRODUCTION UNCHANGED; PHONE INSTALL HELD

## 1. Outcome

The permanent ZYRA Code client is built and the revised server boundary now
passes a fresh seed-disabled PostgreSQL 17 replay. The one OA-ZYRA-289
transactional harness execution passed and rolled back cleanly. A subsequent
read-only catalog probe passed the owner, SECURITY DEFINER, empty search path,
ACL, private RLS, exact migration-history and rollback-cleanliness checks.

No production migration was applied and no phone build was installed. That is
intentional: DR-ZYRA-231 item 10 requires an exact-file/hash Founder GO, and an
install before the RPC boundary is live would knowingly ship a broken Add
Guardian surface.

## 2. Security revision made before apply

Independent review of the still-staged migration found four real release-edge
defects. Codex corrected them in place before any production mutation:

1. DR-ZYRA-221 current identity verification is now required across personal
   code mint/rotation, preview, request listing and every request mutation;
   preview and acceptance also recheck the counterpart.
2. Acceptance takes a canonical pair advisory lock and rechecks an active
   Seeker/Guardian link immediately before the upsert, so a stale reciprocal
   request cannot reactivate/update an existing link.
3. The invitation expiry sweep now derives its two-day warning from the actual
   deadline, not `created_at + 5 days`; a thirty-day request is no longer
   falsely warned at day five.
4. Decline and cancel require `request_expires_at` to remain in the future, so
   a logically expired request cannot be mutated.

The revised harness proves all four behaviors that can be exercised in its
transaction, including unverified mint denial, stale reciprocal acceptance,
the thirty-day warning boundary and expired decline/cancel denial.

## 3. Exact staged artifacts

| Artifact | True pre SHA-256 | Current SHA-256 | State |
|---|---|---|---|
| `20260917133709_guardian_journey_summary_for_all_active_guardians.sql` | unchanged reference | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` | staged only |
| `20260917144606_oa289_permanent_personal_codes_guardian_requests.sql` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` | `edeaf6086caf136ae579691235c46007abb234e1ee1f135629a8b23b5511565a` | security-revised; staged only |
| `zyra_oa289_personal_code_guardian_requests_suite.sql` | `7d429c4ad720eb6c8c22845d6203b55bfc8bb4f48bc6c10f103fd1acc760b73f` | `75af0a0971de35d1c6847bc2fa6034043eb82be7a14c43c56b5f92aa7b50b428` | passed once |
| 211-version replay union | prior union `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0` | `b965a56aa5976fdda321b5ed416763b257b4819582e1c6471b594be3fefe51c3` | changed only by revised OA-ZYRA-289 bytes |

## 4. Replay execution and honest infrastructure note

The first stack-start command stopped during local database connection setup
because the VM outbound firewall had been applied before Supabase finished
initialising its local services. It created no surviving container or volume,
ran no reset and ran no harness. Raw log SHA-256:
`0261e7e9b3320f1f551e432d1586b4531fab34119f743873d9979c791fc7f691`.

Codex removed only that over-early local firewall rule. The fresh, unlinked,
seed-disabled stack then initialised and applied the exact 211-file union once.
No `db reset` was run, avoiding a second migration application. The production
project was not linked or queried by this stack. The outbound firewall was
restored and production inaccessibility proved before the one harness run.

Results:

- 211/211 migration markers; latest local history version
  `20260917144606`;
- one harness execution: `OA-ZYRA-289 PASS`; final `ROLLBACK`;
- zero retained `oa289-%@zyra.test` users;
- all relevant public RPCs owned by `postgres`, SECURITY DEFINER, empty stored
  search path, and executable only by owner + authenticated + service_role;
- private helpers executable only by owner;
- all three private tables have RLS enabled and service_role-only table ACLs;
- isolated stack stopped without backup and Colima VM/socket removed.

## 5. Preserved evidence

Directory:
`SYSTEM/RESOURCES/REPORTS/OA-ZYRA-289_2026-09-17_FINAL_REPLAY/`

| File | SHA-256 |
|---|---|
| `replay-migration-markers.log` | `185ce59da3161ce4c865773ff08afa1f316419d547e826fe489aa632e615454c` |
| `harness.log` | `cbd8fa8299f52bf57141f1406f48ab1c572c8623d539dff277fa6ea52f7d8d1e` |
| `catalog.log` | `8ac357a5f389ba8200f283b2a4a8e6755b383354a0e7356cb150831273a0d0d4` |

The raw successful start log was not copied into the repository because its
Supabase local-stack summary prints disposable local development keys. Its
hash is `830ff2751eaabd8351f5f361cf23909de90bbf8edf0655abd8cc62944838f33c`.

## 6. Application verification

| Check | Result |
|---|---|
| Focused permanent-code / Guardian suites | PASS — 38/38 |
| `flutter analyze` | PASS — no issues |
| Signed iOS profile build | PASS — `Runner.app`, 35.1 MB |
| Full Flutter suite | EXECUTED — 1,589 pass, 1 skip, 100 known visual/developer-debt failures; zero OA-ZYRA-289 failures |
| Connected iPhone audit | one `app.zyraconnect.zyra` Developer App; installed bytes are older than current source |

The local build uses the same bundle ID as TestFlight, so installation replaces
the current app; it does not create a second ZYRA app.

## 7. Production preflight

Read-only connected-project checks identify the target as
`sxoaxonzjqkgajmlagyk` (`ZYRA-APP-LAB's Project`, EU West, PostgreSQL 17,
ACTIVE_HEALTHY). Live migration history still ends at `20260910195642`; neither
September 17 migration is recorded.

Compatibility consequence: applying OA-ZYRA-289 revokes the legacy direct
`wali_invites` insert used by the installed TestFlight build. Therefore the
safe sequence is apply both exact migrations in order, verify, then immediately
install the current signed profile build. ZYRA remains closed; no public App
Store or external TestFlight action is involved.

## 8. Exact remaining Founder gate

The single remaining production authority must name:

1. project `sxoaxonzjqkgajmlagyk`;
2. `20260917133709_guardian_journey_summary_for_all_active_guardians.sql`,
   SHA-256 `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c`;
3. `20260917144606_oa289_permanent_personal_codes_guardian_requests.sql`,
   SHA-256 `edeaf6086caf136ae579691235c46007abb234e1ee1f135629a8b23b5511565a`;
4. apply only those two in order, stop on drift/failure, run complete post-apply
   verification, then install/launch the existing signed profile build on the
   connected iPhone.

No git operation occurred.

## 9. Governance true pre/post ledger

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `OUTSTANDING_ACTIONS_V2.md` | `5f833e6d31c491c8e02662ba3c89b1bab27646dc78ee0aa1a36e316d19736593` | `2682dabe44dd2cec66fc969e56d6817456840391b2b41a51381c1b1b2a4c3669` |
| Personal-code handover V1 | `e312875901202acb8d0db22223049d026c733eb35a7d00b27e8e6231853aa246` | `8a944c11f1807412327e5c3ecb08796d4fcfb2e39d35937e771a698f2b3317de` |
| Documentation index V4 | `d2e7a27662623ca173ae000b02b707f84e8b49ca5f1ffe43d797cae03d950d37` | `11df44e5a0b4709a955b9bff3498068cb8eff1fd87247fdedbedfa0b287a0f9e` |

This new message and the three preserved evidence logs had no pre-state.

— END OF MESSAGE 130 —
