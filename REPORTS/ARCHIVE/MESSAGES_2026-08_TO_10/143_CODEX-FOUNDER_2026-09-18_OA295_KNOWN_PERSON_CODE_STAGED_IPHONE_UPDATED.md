# 143 — CODEX → FOUNDER

**Date:** 2026-09-18  
**Subject:** OA-ZYRA-295 known-person ZYRA Code route built and installed  
**State:** CLIENT BUILT · DEVICE INSTALLED · MIGRATION STAGED ONLY  
**Production / Git / TestFlight / App Store:** untouched

## 1. Founder request implemented

- Browse's visible three-dot action bar now includes **ZYRA Code**.
- The route accepts a scan or typed permanent Seeker code and shows only the
  first name, age and city needed to confirm the intended person.
- **Consider** records ordinary interest. Possessing a code never creates an
  instant Match: the other Seeker must also Consider the caller.
- The route does not reuse or widen Guardian-link code APIs.
- Founder preview contains a local opposite-gender fixture so this interaction
  can be reviewed without calling or mutating the live service.

## 2. Safety boundary

The staged server functions require a signed-in, identity-verified Seeker and
recheck the target's IDV, visibility and `zyra_can_match` result. Unknown,
self, Guardian-role, same-gender, blocked, incomplete and otherwise ineligible
codes all fail to the same neutral empty result. The shared personal-code
attempt budget remains 10/hour and 30/day. No UUID, surname, photo, contact
detail, verification claim, score or private answer is returned.

## 3. Client delivery and verification

The signed Founder profile build was built, installed as
`app.zyraconnect.zyra` on the Founder iPhone and launched successfully.

- Focused Flutter suite: **30/30 PASS**.
- `flutter analyze`: **PASS**, no issues.
- Build: iOS profile build **PASS**.
- Install and device launch: **PASS**.

## 4. Staged migration boundary

Migration:

`20260918145126_oa295_known_person_code_matching.sql`

SHA-256:

`30c12a15b83b9e07e4183140162e09086322d623a40960758a83bea712e80c5b`

**It has not been applied.** Production history was read-only checked and
still ends at applied version `20260918094504`; OA-ZYRA-294 and OA-ZYRA-295
remain staged. Because OA-ZYRA-295 sorts after OA-ZYRA-294, OA-ZYRA-294 must be
resolved before any ordered migration apply. OA-ZYRA-295 next requires an
isolated PostgreSQL 17 replay, direct-call/reciprocity/security verification
and a separate Founder GO naming the exact file and hash.

If a usage-limited membership remains at launch, OA-ZYRA-293's server-side
quota must also close before this direct mutation RPC can go live. The client
is not permitted to be the quota authority.

## 5. File ledger

| File | True pre-state | Post SHA-256 |
|---|---|---|
| `lib/models/zyra_known_person_code.dart` | absent | `9188e56dbd270046a2f7748d11e78fd822183db6bd657039e788601ea523ab18` |
| `lib/screens/browse/find_by_zyra_code_screen.dart` | absent | `0478b0cac1615b5387e553f36a79830654a7f0204bfdda3c1369e1e0278ab22b` |
| `test/known_person_code_matching_test.dart` | absent | `718a11560816c9540ad6b7866aec5394c38d06498de8d1a26350acdc599591ee` |
| staged migration | absent | `30c12a15b83b9e07e4183140162e09086322d623a40960758a83bea712e80c5b` |
| `lib/screens/home/home_shell.dart` | `88193bef6a78ae89cda845f0ee724add23b03a125aa4a4bd327d13193b75fa97` | `195dc0e2f665c8264ba4e35a15c5c679f033a0d1c793d7f3cfda8e2a8c21bbeb` |
| `lib/dev/zyra_dev_personal_code_fixtures.dart` | `6d48b3aa6de42b66d6211277f4fef7a3996b73b0d4b1b179e02e48e9c2e5bb66` | `c95ff6395796630b2de38e819e6a1d5bc68a7abd494215758359b058878fc69d` |
| `lib/services/zyra_discovery_service.dart` | pre-edit bytes were not snapshotted; never substitute a reconstruction | `440f547171bc1d05dc7eabd8439c8bc4b84d068c29700a5d1ca15cdd9423faeb` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `ebe72907ed75217f3e0f45a36e3b614c1183eb735519c9f6d603b2a005b95e93` | `00dd434f4efe90f0946f409edca0ff082e8bc2fb99c4853ccb19dcc11d58cbbb` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `6002941b9544206b3518d9255f4d9243f38bff2bdf7452f79a70ee37dbbb97ac` | `8bddfb12de8658b5201175bd43b2a388d71e728a5661f8db347ad9f4bfabd391` |
| `APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V4.md` | `c902076e47202f5f2aca018c62576f1e55bac8a076bdef12fa6eae1ad297a932` | `582f75f91e040f114294384d6957e8bd03817977ddc110be39f0428b70c3c1cb` |

The missing discovery-service pre-hash is recorded as an evidence defect,
not silently reconstructed. The post file, behavior and test evidence are
valid; future edits must snapshot every existing source file before editing.

## 6. Gate status

- Client construction and Founder-preview installation: **complete**.
- Founder visual acceptance: **pending**.
- Production RPC apply: **held**.
- Self-approval: **none**.

