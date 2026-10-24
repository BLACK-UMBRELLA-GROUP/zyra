# 137 — CODEX → FOUNDER — OA-ZYRA-290 Additional-Guardian Access Staged

**Date:** 2026-09-18  
**Programme:** OA-ZYRA-290 / DR-ZYRA-232  
**State:** CLIENT BUILT · MIGRATION STAGED ONLY · PRODUCTION UNCHANGED

## 1. Outcome

The Seeker Guardian page no longer describes an Additional Guardian as having
a limited Journey summary. Each active Journey now has a server-confirmed
include/exclude switch for that Seeker's Additional Guardian. Main Guardian is
always included and cannot be switched off.

The detail page uses the previously empty space for truthful role information:

- the exact active Journey access switch;
- **CAN VIEW** — overview/progress, timeline/conversation and restricted
  counterpart details;
- **MAIN GUARDIAN LEADS** — Family Review, Guardian Gate, pause/continue and
  other protected decisions.

Guardian-side roster/workspace reads now accept rich current context for an
Additional Guardian only when the server has authorised that exact active
attempt. Outside an active assignment, the DR-ZYRA-230 four-field summary
remains the ceiling.

## 2. Security boundary

- caller identity is derived from `auth.uid()`;
- a Seeker can mutate only their own active Additional-Guardian link and own
  active Journey;
- Main assignment mutation is rejected;
- access is exact-attempt, audited and immediately revocable;
- no profile-wide visibility, Browse visibility, message sending, Family
  Review, Guardian Gate or protected decision authority was granted;
- future/unknown attempt states fail closed;
- failed writes retain and label the last server-confirmed UI state.

## 3. Staged server change

Only this migration is staged:

`SOURCE/supabase/migrations/20260918075737_oa290_additional_guardian_journey_access.sql`

SHA-256:
`347e32e901b266cd4a6e7fa98fd077e51b4963f2b5e3c6620f1645577847a282`

Live read-only probes confirm migration `20260918075737`, table
`public.journey_guardian_assignments`, and RPC
`public.zyra_guardian_journey_access(uuid,uuid,boolean)` are all absent.
Nothing was applied.

## 4. Verification

- focused affected suite: **55/55 PASS**;
- `flutter analyze`: **PASS — no issues**;
- full repository suite: **1,603 pass, 1 skipped, 116 fail**; broad suite remains
  non-green from known routing/visual/replay debt and expected stale approved
  pixels. No approved baseline was regenerated;
- no migration apply, Apple upload, TestFlight operation or git action.

## 5. True pre-state evidence captured at edit time

| File | Pre SHA-256 |
|---|---|
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `4fddfd298c80dd78b2883620635b06c63ff6efdc168cc638ad4e53b54c705ce2` |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | `f154aa50015955caa2d4c4121a30cca9822f6afef72aaace2c80cad7cdee62ed` |
| `SOURCE/lib/services/zyra_wali_link_service.dart` | `f3634d5a7341ef9c60fafc55c83e08cef79fbd75fd606eda56be06ef7f57dba3` |
| `SOURCE/test/seeker_wali_tab_truth_test.dart` | `7c5d855b854aae37646cecd1d85a089acca75cda03218a3605c330c806cc4235` |
| `SOURCE/test/guardian_one_page_designs_test.dart` | `88f3a4204ba63a9ac97a182f69c01d29bc495925aa1d51613ab5b8f591d97187` |

The later blast-radius reconciliation touched supporting Guardian/client/test
and governance files. Their post-state is recorded below; no unrecorded
pre-hash is invented.

## 6. Post-state ledger

| File | Post SHA-256 |
|---|---|
| migration | `347e32e901b266cd4a6e7fa98fd077e51b4963f2b5e3c6620f1645577847a282` |
| `zyra_wali_link_service.dart` | `23695c240732f8f55a558e922227e42affa2f904f292e3c609d5fd77861c59b2` |
| `seeker_guardian_designs.dart` | `d96e9346db74ce9e2e1875baf8da984c0cd492a2be2b632d7cd3d085a9dbcf54` |
| `seeker_wali_tab.dart` | `e9f30b91a741a554c7ee94b174d1a8755798120665a344293a68580bf3b4d0eb` |
| `zyra_wali_journey_service.dart` | `8f7644b4e892ac1cdfb5e53f3e7cd96861644a4f4f0c6148f4abff8627cb448f` |
| `zyra_guardian_seeker_roster_resolver.dart` | `98d36bcc2548b753ddb7c6e95fa27def6828895c940b0ecfb1deb1a036ff3f39` |
| `wali_seekers_screen.dart` | `0a12157fd05f68d41d5b7d3f90fcdd7b22fb09fce530b8a3ff934e3c8838fa44` |
| `wali_seeker_workspace_screen.dart` | `12fa3071cdc1195dea4caf2db067f2483ff0e068f01f8f9cc26222027591857e` |
| `connections_screen.dart` | `ccd3dc97e4b8435a8c78ee4edb2eb49802fca0a4a0efe443f0d5d8a2d8d047af` |
| `guardian_detail_screen.dart` | `49a7d31ce3b573f4c92c8ebfd48e9c416b87240c66453b23d1b681e9400a5e7d` |
| `wali_dashboard_preview.dart` | `f227451a1bf5abfe003860a7e615af8140a3fa399420b113ba6fb51082748ad6` |
| `wali_dev_scenario_panel.dart` | `11c83d21e8c57e9ca4b82e1a247f60d90ccd4bd29f3eb89887258ae137130f14` |
| migration test | `3fcccf11d6c0e3ad8d92c27f673f0086e3f421b2f6d4d217293920c9ffeee7e7` |
| link-service test | `49ea68114b03c95f02776b2a99e1d1c212bc22a3503ce1a2ba60ba76c76ad39d` |
| Seeker Guardian truth test | `cdceb0d8d5908037f9a20f768bef0b3b2ee90cee6237764d85001da66abcc4a2` |
| Guardian page test | `dea6490869226d02b856c7fe2ad19b038f7f0093ce5d76597fb1013a33a4d57b` |
| resolver test | `a787e431bc733a257a288eaea0caa9e79349ffdfab0343b4e9cfcfa9410c19fb` |
| workspace test | `6ab75d626f70f19e68727700435f1f1aae1b70001a9400d6cdb3496f0796b36e` |
| roster truth test | `e8bb81f487af23cb2c95548d48d7aa598938eeebadde766bbd4035e4403de379` |
| design-control test | `e80a29918147068afee31cfb278d71441d2d951af79ecb64d7b6634841fece28` |
| Decisions Register | `8dbfe4db0ca4dbc82065bc3e8bde0f01fe954641fad9aaa97f1b067fb2a3928a` |
| Outstanding Actions | `02ab937fd33328e14d895febcd0f83fe0a84912bac3db4f116df40f0902f3fe3` |
| Guardian source of truth | `7b62356b9033f79c8828ee19e1e42b2f063fdc871611fc2acbf8915f4f8c6a5c` |

## 7. Remaining gate

The client cannot safely use this live-account feature until the exact staged
migration is separately authorised, applied, directly security-probed and
then installed for Founder review.
