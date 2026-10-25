---
id: DOC-ZYRA-0196
type: HANDOVER
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA Personal Code and Guardian Request Handover
links: []
owner: ZYRA chat
---

# ZYRA Personal Code and Guardian Request Handover

## Current Scan-copy round —22 October2026 / LahQ4a

Remove the word “permanent” from both Scan introductions only. Account-role
code lifetime, rotation, QR/scanning, parser, camera permissions, request/link
semantics and the existing backend contract are unchanged. This is copy, not
a code expiry, new lookup authority or a repeated migration/cutover.

Verification/delivery result —22 October2026: AluNSb passes45 distinct suites/
1,027 actual distinct app cases, zero failures/skips;46 recipe/seven visual
cases are separate and400 earlier working cases not added. Scope22 paths
(8 libraries/14 tests)/4,866 inputs; clean analysis, zero-change format, No-Git
proof and exact Source/14 helpers pass. QUALIFICATION_RESULT owns plan/seal.
Separate26 index tests pass with known ResourceWarnings retained; independent
read-only native-chain audit passes, not Founder acceptance.
Fourteen fresh seal-bound real-font component PNGs include eight root-inspected
views, not every state/AA or physical acceptance. Prior LahQ4a/e43qfk failures
and wrong-cwd first inspection remain immutable; corrected absolute inspection
passes. Test-only Send/context repairs retain unsent-draft guards; eight product
libraries unchanged. HOST_PROFILE.rNcnlg/Runner.app has177 files, artifact
dc7522174132b4844ed2e65ad1980fa8ae1087cd4709545cbd3a21290bd0401b;
build/compiler/existing identity pass. INSTALL13:33:59.841, LAUNCH13:34:42.578,
POST13:35:28.675 UTC verify sameApp/sameProcess/identity, container
FC0F4DBB-D9B5-4C9F-B2A2-D4CED30019FE/PID34943, same main1.0.0(5). Runbook/
DELIVERY_NATIVE_FACTS own the current-Dart/fresh-objective_c retained PROFILE
host chain/index checks, not full Xcode/native repair; v5aCmj is dated history.
No code-lifetime/API/permission/account/backend change, app-data reset/cache
deletion/migration/purchase/upload/signing repair, physical/VoiceOver acceptance
or OA closure; existing gates and UNSENT filing remain.

## Current local delivery — 19 October 2026

Native delivery is complete for `OA305_LOCKSCREEN_HANDOFF_2026_10_18.76vv6v` /
`HOST_PROFILE.1jO5Io`: fresh `LOCK_2`, install, launch and native POST all pass.
The same updated app/container and PID 22899 were verified at 10:47:57 UTC.
This supersedes earlier local-build pending/lock-hold statements and the
`4oS3WH/bjV1Jf` installed baseline below; those remain historical evidence.
It is not a new TestFlight/public upload or live-service activation.

The checked Source has 4,828 inputs/78 changed paths, with 1,861 distinct
passing cases across 85 suites and 51 root-inspected frames.
Photo-import repair and Option 1/2 retirement are included; current purple
ZYRA remains. Option 1's archive is outside active Source.
Photo selection remains local-only and requires fresh crop confirmation.
Real chosen-photo/HEIC checks and Founder physical acceptance remain pending.
Compact 200%-text Guardian readability stays OPEN under OA151/304; normal
header checks do not close that existing whole-page scaling limitation.

`DELIVERED_AS_BUILT.json` and the dated delivery appendix in the One-App
Internal Delivery Runbook own the measured native chain. Separate Codex-agent
reviews in earlier sections are internal checks, not external approval.
Shared registers remain paused; no new OA closure, ADMIN message, Google
sign-in test, backend/provider change or live photo upload is implied.


**Version:** V1  
**Status:** CURRENT_VERSION — LIVE; POST-APPLY VERIFIED; PROFILE BUILD INSTALLED AND LAUNCHED; FOUNDER VISUAL ACCEPTANCE PENDING  
**Date:** 2026-09-17; client amendment 2026-09-18  
**Owner:** Codex under AD-AIOS-109; Founder is sole approval authority  
**Decision:** DR-ZYRA-231  
**Action:** OA-ZYRA-289

## 1. Founder outcome

Option 1 is the implemented direction:

- one permanent code for the account's current role;
- Copy, on-device QR and native Share;
- Scan or Enter another person's code;
- first-name-and-role preview only;
- an addressed request, never an automatic link;
- code-owner Accept/Decline and requester Cancel;
- only Accept writes `wali_links`.

The current profile model still stores one role. The new table is keyed by
`(owner_id, role_context)` so future governed dual-role support can use two
codes, but this implementation does not invent or enable dual role.

## 2. Security contract

The displayed format is `ZYRA-XXXX-XXXX-XXXX-XXXX-XXXX`, produced from 80
random bits. Codes are discovery handles, not secrets or login factors.
Preview is authenticated and limited to ten attempts per hour and thirty per
day per caller. Invalid, self, blocked, same-role, romantically ineligible and
already-linked lookups all return the same neutral empty result.

DR-ZYRA-221 is enforced at the server boundary: code mint/rotation, preview,
request listing and every request mutation require a currently verified
caller. Preview and acceptance also recheck the counterpart's current verified
state. Acceptance serialises by canonical Seeker/Guardian pair and rechecks an
active link immediately before the upsert.

Rotation retires the old code. Rotation and account deletion write only its
SHA-256 digest to a no-owner non-reuse ledger. The preview contains no photo,
verification badge or verification result.

The Guardian owns the relationship statement in both directions. Existing
seven-day bearer invites remain valid during transition but the new client no
longer mints them. An old-code fallback appears only after a permanent-code
lookup fails; it is not a primary page action.

## 3. Live database artifact

`SOURCE/supabase/migrations/20260917144606_oa289_permanent_personal_codes_guardian_requests.sql`

SHA-256: `edeaf6086caf136ae579691235c46007abb234e1ee1f135629a8b23b5511565a`

State: **APPLIED AND POST-APPLY VERIFIED**. The Founder authorised one exact
production cutover on project `sxoaxonzjqkgajmlagyk`. The migration was
recorded once as version `20260917144606`, name
`oa289_permanent_personal_codes_guardian_requests`, statements MD5
`47b0ff0a179af818caebe9a47f9c1cec`. Its immediately preceding authorised
dependency was recorded once as version `20260917133709`, name
`guardian_journey_summary_for_all_active_guardians`, statements MD5
`a691f9f5d520fc87d53f29ec8e640fbf`. No other migration was applied.

Live verification confirmed:

- `pgcrypto` remains installed in schema `extensions`;
- the evolved `wali_invites` columns, constraints, indexes and triggers match
  the frozen migration;
- all public RPCs are owned by `postgres`, SECURITY DEFINER, have empty
  `search_path`, and expose only the intended authenticated/service-role ACL;
- private helpers remain owner-only; private tables have RLS enabled with no
  client policies and the intended service-role boundary;
- direct `wali_invites` inserts are denied to PUBLIC, anon and authenticated;
- both exact migration-history rows exist once and `20260917144606` is the
  latest live migration.

The live check also exposed the legacy
`wali_invites_relationship_only_from_wali` constraint. The staged migration
replaces it with a source-aware check because a Guardian may enter a Seeker's
code and therefore be the request recipient rather than the code owner.
Direct authenticated inserts are revoked, new requests use the same 30-day
deadline through both legacy and personal-request readers, and legacy invite
summaries explicitly exclude personal-code requests.

The final staged revision also replaces the old `created_at + 5 days` expiry
warning heuristic with an actual-deadline check, so a thirty-day personal
request cannot receive a false “expires in two days” warning after five days.
Decline and cancel require the request to remain logically unexpired.

## 4. Client and native changes

- New shared `ZyraCodeScreen` is used by Seeker Add Guardian, Guardian Add
  Seeker and older profile/Journey link routes.
- New typed service models preserve available-empty vs unavailable truth.
- QR generation and scanning are on-device; Share uses the OS sheet.
- Camera purpose declarations exist for iOS and Android.
- Exact package pins: `qr_flutter 4.1.0`, `mobile_scanner 7.4.2`,
  `share_plus 13.3.0`.

After the server boundary passed post-apply verification, the existing signed
profile build was installed on the Founder's iPhone, replacing the prior build
under the same bundle identifier. Device inventory showed exactly one
`app.zyraconnect.zyra`, version `1.0.0` build `2`, and the app launched
successfully.

### 4.1 Founder-preview demo codes

The four local Founder-preview personas now render deterministic demo-only
codes on the shared `ZyraCodeScreen`. This path is entered only when both the
Founder capability and the preview isolation latch are active. The values use
the `ZYRA-DEMO-*` namespace, deliberately fail the live
`ZYRA-XXXX-XXXX-XXXX-XXXX-XXXX` parser, and are never sent to or stored in
Supabase. The live service, schema, RLS, IDV gate and real-member flow are
unchanged. Code rotation is hidden for these fixed fixtures, sharing labels
them as preview-only, and the screen states that they are not accepted by the
live service.

An ordinary build has `ZYRA_INTERNAL_FOUNDER_ACCESS` default OFF. Therefore
the demo path is unavailable in an App Store/public build unless the governed
Founder-only compile capability is explicitly supplied and the refreshed
pinned Founder claim also passes. The preview client continues to deny all
non-auth Supabase traffic while the local preview latch is active.

### 4.2 Full-height personal-code composition

Following three Founder device reviews, the default shared page fills the
usable height with its actual surfaces rather than empty spacing. The code card
is the main expanded feature area; Copy/QR/Share are taller; and Scan/Enter
each expand as large lower actions around compact fixed gaps. The code and
supporting text scale modestly inside the feature card. QR display, pending
requests, errors and short viewports automatically use the scroll-safe compact
composition. This is presentation-only; the live and Founder-preview security
boundaries in §2 and §4.1 are unchanged.

### 4.3 Code-action haptics and camera-permission return

Founder device review found two client issues on 2026-09-18. Copy and Share
did not match the existing QR action's selection haptic. Both now use the same
member-configured `ZyraInteractionStyle.emitSelectionHaptic` path as QR, so the
Personalisation haptic level—including Off—remains authoritative.

The first iOS camera permission prompt also exposed a route-lifecycle defect in
the internal Founder build. Returning from Apple's permission sheet generated a
resume event. The resume authorization refresh correctly invalidated the old
Founder proof while refreshing, but the global developer overlay interpreted
that temporary in-flight state as permanent authority loss and replaced the
whole navigator stack with Home. It now retracts protected controls during the
refresh while preserving the current route, and redirects only if the completed
refresh genuinely fails. Camera permission wording and scanner behaviour are
unchanged; this was an app-side navigation bug, not an Apple permission bug.

### 4.4 Inline code entry and local copy confirmation

Founder device review on 2026-09-18 removed the transient bottom Copy
snackbar. Copy now confirms inside the existing action itself: the icon changes
to a check and the label changes from **Copy** to **Copied**. This section's
original two-second visual reset was subsequently replaced by the persistent
page-session confirmation in §4.6. Clipboard behaviour and the shared
member-configured selection haptic are unchanged.

The oversized gap between the transparent page header and the personal-code
card was reduced. **Enter code** no longer pushes a second page. Its existing
action card now expands and collapses in place with an animated disclosure,
retaining the same code preview, relationship choice, legacy-code fallback and
request submission rules. A successfully scanned code returns to this same
page and opens the same inline panel with the scanned value. The whole
composition remains scroll-safe while expanded.

This amendment is client presentation and navigation only. It does not change
the permanent-code format, live service calls, request lifecycle, verification
gate, database, RLS or migration state.

The signed profile build containing this amendment was installed on the
connected Founder iPhone. Device inventory retained the single
`app.zyraconnect.zyra` installation at version `1.0.0`, build `2`, and the
Runner process was present after launch. Flutter's profiling WebSocket reset
after the successful install/launch; that host-tool connection loss did not
remove or stop the installed app.

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | Timed in-button Copy confirmation, reduced top spacing and expanding inline code entry | `f28e5331d26e3843178203a56dec51ff27adc78b789602db131c088db6104d07` |
| `SOURCE/test/zyra_dev_personal_code_fixtures_test.dart` | No-snackbar, gold Copied state, reset and haptic regression | `8a3818b8ec62d84954c9bd22cc0d5e2bf722edd4f0d393a94f837a6d5e2c87f6` |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | Same-route inline Enter-code expand/collapse regression | `40548092772a9ada4818f775603673fb70062892ae35818f70dd8362d026b673` |

### 4.5 Shared action feedback and code-confirmation preview

Founder review on 2026-09-18 extended the same interaction across both
directions of the shared surface: Seeker adding Guardian and Guardian adding
Seeker. Share now receives the same temporary gold selected treatment as Copy
after it is pressed. Its native share-sheet behaviour and shared haptic remain
unchanged.

Opening **Enter code** now closes an open QR state first. The screen scrolls to
the inline primary action both when the keyboard/layout settles and when code
validation changes the panel height, preventing the Apple keyboard from
covering **Check code** or the later confirmation action. **Check code** is now
a compact gold pill rather than another full-width navigation row.

A successful lookup replaces the input with an identity-confirmation card,
showing the returned first name, role and a circular initial avatar, followed
by **Confirm & send request** and **Use a different code**. The live RPC's
privacy-minimised contract intentionally still returns no profile photo or
verification claim, so this amendment does not expose a stored profile image.
Wrong codes remain in the entry state with the existing unavailable message;
real successful confirmations continue through the governed request RPC.

Founder Page options now expose role-correct local test codes. On the Seeker
Guardian page, **Valid Guardian** copies `ZYRA-DEMO-GUARDIAN-IBRAHIM`; on the
Guardian Seekers page, **Valid Seeker** copies `ZYRA-DEMO-SEEKER-ADAM`. Both
also expose the wrong test value `ZYRA-0000-0000-0000-0000-0000`. These
options exist only behind Founder preview authority, copy the selected value
for pasting, resolve locally, and never reach or mutate Supabase. Confirming a
valid demo code shows a local **Request sent** result only.

The signed profile build containing this amendment was installed wirelessly
on the Founder iPhone. Device inventory retained the single
`app.zyraconnect.zyra` version `1.0.0`, build `2`; the app was then launched
directly by bundle identifier and its current Runner process was confirmed.

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | Shared gold Share state, QR collapse, keyboard-safe reveal, pill action and identity confirmation | `5f7bc8e9db4e7986979fa5cabbafc6d490fdb59ff0e6d57239cb96d1c55a238c` |
| `SOURCE/lib/dev/zyra_dev_personal_code_fixtures.dart` | Role-correct valid and wrong local entry fixtures | `093c492d7bef72f7d0dcd09bb15f6a35e6ea8e9f36beb509efb93cb4bc1a38c2` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | Seeker Guardian-page code test options | `8ae9d4da3e9d2c5a302c3c845ff33c0ce4f45e36e055cd5f0859eee546978654` |
| `SOURCE/lib/dev/wali_dev_scenario_panel.dart` | Guardian Seekers-page code test options | `0ac4c940d16d8d2ff77f4d694f1848b2fc531cbe121eea8b19e424fd696b76be` |
| `SOURCE/test/zyra_dev_personal_code_fixtures_test.dart` | Both-role action, validation, confirmation and local-send regressions | `30513316d2a4acdad139856107004b981f9c32912e9553318605522125d6eec1` |
| `SOURCE/test/zyra_seeker_page_options_test.dart` | Seeker Page-options fixture catalog regression | `1376b51e6244f8b0271ed6e970accaae4c31a0638879818082f84852efff8b80` |
| `SOURCE/test/zyra_guardian_page_options_test.dart` | Guardian Page-options fixture catalog regression | `9d10b700c8a1d10ce07358812ad26494b3e7b5578f28ed43163cdc05c5e4c6b2` |

### 4.6 Persistent Copy confirmation and repeat feedback

Founder review on 2026-09-18 approved a page-session confirmation instead of
returning **Copied** to **Copy** after a timer. The first tap still writes the
current personal code to the clipboard, emits the member-configured selection
haptic, changes the icon to a check and applies the gold **Copied** state. That
state now remains visible for as long as the member stays on the page.

The confirmed action remains tappable. Every later tap writes the code again,
emits the haptic again and replays a short check-scale and brighter-gold pulse,
so members can deliberately recopy without an ambiguous static response. The
confirmation resets only when the page is disposed or the underlying personal
code value changes, including successful rotation. Share retains its separate
temporary selected treatment. This is a shared Add Guardian / Add Seeker
client interaction and changes no clipboard payload, service, database, RPC,
RLS, verification or request rule.

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | Persistent Copied state, repeat-copy haptic and replayable check/gold pulse | `dca7412791ec8824f5290ac84cabf2de4bfccf8eb0ac7c896c3ea2ab4f4ce215` |
| `SOURCE/test/zyra_dev_personal_code_fixtures_test.dart` | Persistent state and second-tap animation/haptic regression | `cc4ac7cdb13dc8a75e03a5f6110b233ae8303a89c44e90159c8b3719ef4580eb` |

The signed profile build containing this amendment was installed wirelessly
on the Founder iPhone and relaunched independently after the Flutter host was
detached. Inventory retained the single `app.zyraconnect.zyra` installation at
version `1.0.0`, build `2`, and the Runner process was present after launch.
Apple's TestFlight binary was not changed.

## 5. Verification

| Check | Result |
|---|---|
| `flutter analyze` | PASS — no issues |
| 2026-09-18 inline code-entry regression suite | PASS — 17/17 |
| 2026-09-18 shared code-confirmation and Page-options suite | PASS — 50/50 |
| 2026-09-18 persistent Copy confirmation four-suite set | PASS — 52/52 |
| 2026-09-18 code-action and resume-route regression suite | PASS — 20/20 |
| Focused service/Guardian/code tests | PASS — 38/38 |
| iOS profile build, no codesign | PASS — `Runner.app`, 35.0 MB |
| Full Flutter suite | EXECUTED, NON-GREEN — broad pre-existing visual/developer debt remained; the one directly affected legacy expectation was corrected and the affected suite then passed |
| 211-version PostgreSQL 17 replay | PASS — fresh seed-disabled stack applied every version once during empty-stack initialisation, including `20260917133709` and revised `20260917144606`; union manifest `b965a56aa5976fdda321b5ed416763b257b4819582e1c6471b594be3fefe51c3` |
| SQL harness | PASS — one execution; IDV denial, safe preview, two-sided requests, owner acceptance, stale active-link recheck, deadline warning and expired-action assertions passed; final rollback retained zero fixture users |
| Catalog verification | PASS — 211 history rows ending at `20260917144606`; owner/SECURITY DEFINER/empty-search-path/ACL/private-RLS contract matched |
| Latest replay attempt | PASS — one full migration initialisation and one harness execution; production inaccessible before the harness; disposable stack and VM removed |
| Production apply | PASS — exactly `20260917133709` then `20260917144606`; exact approved hashes; no other migration |
| OA-ZYRA-288 live role matrix | PASS — Seeker, Main, Additional, removed/inactive, unrelated, current/paused, ended-in-period, pre-link-ended and Main-consent cases |
| OA-ZYRA-289 live verification | PASS — canonical harness plus catalog/ACL/direct-write, stable-code, rotation, rate-limit, neutral-result, current-IDV, counterpart-recheck and request-lifecycle probes |
| Rollback cleanliness | PASS — zero retained test users, codes, retired hashes, attempt rows or personal-code requests; sequence value 97 is the expected harmless non-transactional test gap |
| Founder iPhone | PASS — sole ZYRA app installed and launched; `app.zyraconnect.zyra`, version `1.0.0`, build `2` |
| Git operation | NONE |

Post-apply SQL harness:
`SOURCE/supabase/tests/zyra_oa289_personal_code_guardian_requests_suite.sql`
SHA-256: `75af0a0971de35d1c6847bc2fa6034043eb82be7a14c43c56b5f92aa7b50b428`.

The harness no longer depends on seed data. It creates a unique temporary
`auth.users` + `profiles` Seeker/Guardian pair inside its existing transaction,
runs the unchanged product assertions, and reaches the existing final
`rollback`. The true pre-edit harness hash was
`e1f04bc60b382dccbe36551ad7b506039e50eb336fd1c3320ac9f8f6dd971815`.
The first fixture correction changed the harness from
`e1f04bc60b382dccbe36551ad7b506039e50eb336fd1c3320ac9f8f6dd971815`
to `fa4da023e930603140939b8daa1e83a3a4e332d9c0becc951b6e2b680dc7a19c`.
The later catalog-only correction replaced the nonexistent
`information_schema.routine_columns` reference with an exact ordered
`pg_catalog.pg_proc` output-argument check. Its first array expansion attempted
an unsupported qualified three-array `unnest`; the current correction uses
supported `pg_catalog.generate_subscripts` and indexes the three catalog arrays
at each returned position. The final security revision additionally creates
verified temporary actors, proves an unverified caller cannot mint a code,
proves a reciprocal request cannot reactivate an already-active link, proves a
thirty-day request is not warned at day five, and proves logically expired
requests cannot be declined or cancelled. It executed once and passed.

Sanitised replay evidence is retained at
`SYSTEM/RESOURCES/REPORTS/OA-ZYRA-289_2026-09-17_FINAL_REPLAY/`:

- `replay-migration-markers.log` — 214 lines: three setup markers plus 211
  migration markers; SHA-256
  `185ce59da3161ce4c865773ff08afa1f316419d547e826fe489aa632e615454c`;
- `harness.log` — SHA-256
  `cbd8fa8299f52bf57141f1406f48ab1c572c8623d539dff277fa6ea52f7d8d1e`;
- `catalog.log` — SHA-256
  `8ac357a5f389ba8200f283b2a4a8e6755b383354a0e7356cb150831273a0d0d4`.

## 6. True pre-state ledger

| File | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/pubspec.yaml` | `4e314cbfacf2a0edbeb8a2053718b78534cdd18e69cd94b13df7f7e6bdf40087` | `726801957378b6c9789859cb8b3eed4bd358c2f07bda32a92c767def96f0ab06` |
| `SOURCE/pubspec.lock` | `308b761f4a7808b132d42504862a0cf7cc2a0a4342ee5f147abfaa4fdf5297f0` | `f16c204d4e44f3f6766130380815740922632c59f9f4be0b687444fed106b920` |
| `SOURCE/ios/Runner/Info.plist` | `edf58a6b5ae16f08dc459307b8aa470b3321589e00119d94e750d6977f83b11e` | `0253d89e7ea25e62138785c36a403d8b1b161f8da30e40dafc68eab73b88df17` |
| `SOURCE/android/app/src/main/AndroidManifest.xml` | `0325c264b92d601419d8bb2f4597ffc59462fb9cbd49cc39ae376149ba0da9a1` | `c33e7da1ebd781deb517961806146446f4f192a397a8a041586da6d740fd3a9c` |
| `SOURCE/lib/services/zyra_wali_link_service.dart` | `04e6be89ad413e3adb939344cdcd68bab6f03e61f63b8a756e63669334987659` | `f3634d5a7341ef9c60fafc55c83e08cef79fbd75fd606eda56be06ef7f57dba3` |
| `SOURCE/lib/screens/wali/link_guardian_panel.dart` | `721690b8c138512556d93314c8e2347ea46999cb98e9cb31105a7cff97a06b9f` | `35d7ba2557bc25a3fbf10111161a7e4770bc4de3fe4b953c82893f5eb13a8535` |
| `SOURCE/lib/screens/wali/accept_wali_invite_screen.dart` | `16b5690c33719689c8e6cdb6f61b45f2d40a655a3530107776caa0dabb97d824` | `1f04815a28d4d59ecf47508524b792e7f1cc14146afe6cad6978fa35d3438d9b` |
| `SOURCE/lib/screens/wali/wali_invite_seeker_screen.dart` | `fd08495a37d1c4d14c5ab89263e9f1ec4ab0c7b109834c7c22cb6c0661d9352f` | `e27bd760a5d185d7e8254ba50cec66110f230500c3243b03645deadbf23e4b36` |
| `SOURCE/lib/screens/wali/link_wali_screen.dart` | `72ce37edecbc051dc654e1595f262d20204051f04dae3a4e10355784c8360b65` | `04792652f7622540bd78fa13b98df016815cb1f1e34c55aa25ee18deedc9a2d1` |
| `SOURCE/test/zyra_wali_link_service_test.dart` | `caed2e4dad0fc2ccaf6884cc9371e8662568c2b37a267ff5a04454f650fa9331` | `ebba52c08125f837d80fd837f4b7bb78423ba7f78607ebc290eadc6368711519` |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | `4d5bab3de8e43a8c2cc2c658b61be53d6f41dc8f96b083ce178bf207a3183b83` | `67e46182d2c7539ecfafbf5e057135e0d1fb464c3f2b5cf47c44b39d78876f65` |
| `SOURCE/test/seeker_wali_tab_truth_test.dart` | reconstruction only: `4505997a238a7679cb70dbbbaebe945a34768a7299598ff7457eb822b373c660` | `1326103df6f6d463e99a72614fa55ec2d1663b92a860b8995b756ba300ba303b` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `7466900bbef633fce50941bc094e6f45e6d2f42d8aac121706c51d3588ca99b4` | `21ddc7c83858a54770430787c37fc928881b84734831d12efbaa3fe93aea2282` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `ac6ef0c7ae98102ed9739e1efb6e02b1161d770ac668c579ccbc1770955699ba` | `38f67ca1794aa2dadf7bc8257fefd10fc344251136774dacf8f03bf799a63d78` |
| `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V2.md` | `77cab08aacedc21876f423c138808e9f5fb75e2e62c5d618fd5e6d0d48a803c0` | `474f4ae3652b3ae97ab5499c0b373ed88426ca10abbb5ac23edc8ffd9088eec9` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md` | `e9561ee0c355f907aea6f349bb8063921611a51d89654a9dcb242ec4ef70435e` | `9c1ed587be719f8a9ef51e255ada8c8bd0e98c4787adc74dff96f48ddafd0d19` |

New files have no pre-state: the migration, SQL harness, shared code screen
and this handover. `seeker_wali_tab_truth_test.dart` was not snapshotted at
edit time; its prior bytes were reconstructed by reversing the one hunk and
matched the previously filed hash `4505997a…`. Per the 038 rule that value is
recorded as reconstruction evidence, not an audit anchor.

## 7. Remaining gate

The cutover and post-apply verification remain complete. The 2026-09-18 haptic,
camera-permission return, copy-confirmation and code-confirmation corrections
passed their source/tests and the newest signed profile build is installed and
running on the Founder iPhone. Founder device-behaviour and pixel acceptance
remain pending. The older TestFlight build's direct
invite insert is intentionally revoked by the new server boundary; the local
profile build uses the governed RPC flow.

## 8. Local account lifetime repairs measured 6 October 2026

The current source protects both `requestGuardianLink()` and
`acceptGuardianLinkRequest()` against replies from an earlier account lifetime.
The Founder authorised bounded local execution in ZYRA FINAL REALEASE; these
repairs have local service verification, not Founder device acceptance. The
installed build and production checks above remain dated historical evidence.
No new phone build, provider request or database change accompanied this repair.

Each method captures the signed-in actor and `ZyraAccountState.generation`, then
checks the current actor and lifetime at entry, after the existing capacity
preflight, before RPC dispatch, after its acknowledgement and at catch entry.
An obsolete reply cannot return client success or publish invitation/link
revision events. The safe result is “Your account changed. Please check your
Guardian requests before continuing.” This result does not claim that a
server-side write was undone, and neither method automatically retries a write.

The existing `String?` API, RPC names/parameters, current-owner error wording,
Basic/One capacity rules and valid acceptance null/204 acknowledgement contract
are unchanged. Decline, Cancel, legacy acceptance, reads, layouts, prices and
server authority were not changed in this lane.

### 8.1 Source identity and repair stages

- Exact pre-request service: `e090cce3c23d822d5a6514aea039cfae5ff089704d3fd1f485de07ed97a93688`.
- Sealed request-only service: `c3fe86bba85d148681a63f0a18f2736564df084dae9f32a003efeacb7a661634`.
- Current service after the separately bounded acceptance extension:
  `0929842abbccce5e628202b9a9911664a7a4ad11cce5e5b6e5a89f678df28a72`.

The acceptance extension changed only its exact method body. Main's byte
comparison confirmed that all other bytes, including the request repair, were
preserved. Full-byte backups, exact diffs and the original reproduced acceptance
failure remain in `SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/`.
The request-only receipt's source hash is historical after that extension; it
must not be rewritten to hide the staged repair.

### 8.2 Local verification and its limits

The final Guardian packet passed 87 distinct cases: 11 original lifetime cases,
9 added acceptance cases and 67 existing transport/model/account/capacity
controls. Main reran the 11 and 9 cases successfully; these repeat measurements
are not additional tests. Compared with the sealed request-only receipt, 10
cases add coverage: the 9 added acceptance cases and the previously held
same-actor reset case. The formerly failing A-to-B acceptance now passes but
is not a new case.

The tests used generated in-memory actors and strictly intercepted `.invalid`
HTTP endpoints with no unexpected requests. They cover observed account
synchronization, logout beginning and A-to-B-to-A replacement, not wholly
unobserved SDK identity changes. The capacity-await probe measures the existing
not-ready preflight only. Deployed RLS, real capacity enforcement, native
provider revocation, physical navigation and actual server mutation effects
remain separate checks. Source analysis was clean; the external evidence file
reported 11 unsuppressed `visibleForTesting` placement warnings and zero errors.

### 8.3 Evidence and remaining acceptance

All following paths are relative to
`SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/`:

- `NEXT_GUARDIAN_REPAIR.json` — request stage;
  SHA-256 `0f3ec3e19296f1b60952ad32321fd86ecde8adfa720df32995dd0e54257ab59a`.
- `NEXT_GUARDIAN_ACCEPT_REPAIR.json` — acceptance extension;
  SHA-256 `f3fd2094ad816f136ca3d9272888d97a2566cc73ef175b68c5e1dd8268c720ec`.
- `NEXT_GUARDIAN_ACCEPT_ROOT_REVIEW.json` — Main review, 28 matching references,
  exact outside-method preservation and repeat tests;
  SHA-256 `364f5d5a9c317f85ae951047671e68424e2e055c63e1e682a65c11b07c00a294`.
- `NEXT_FONT_NOTICE_REPAIR.json` — separate font licence text and unsigned
  asset-inclusion verification, not a Guardian or native release test;
  SHA-256 `1f26b5bb52d15e8707fab688f9e7d49c47d9c9cf5ca84569a3378d931e2eacd7`.

OA-ZYRA-289/303/305 reconciliation remains with the single register owner in
ADMIN. Local implementation and internal review do not close an OA, approve a
release, replace the earlier consumed migration authority or constitute
Founder acceptance. The Founder is away, so these new client changes have not
been installed on the phone.

### 8.4 Request acknowledgement after logout begins

A separate new fixture passed two cases: the current-owner positive control
and a request acknowledgement arriving after public `beginSignOut()`.
The second case adds one distinct coverage gap; it is not implied by the
acceptance method's earlier logout test. It dispatches one request, begins the
observed account logout, receives the original acknowledgement and returns the
safe non-success message without a new invitation revision or automatic retry.
The synthetic Auth token deliberately remains installed, so this tests the
client account lifetime rather than provider revocation or server rollback.

The fixture's analysis reported zero issues and its strict mock recorded no
unexpected HTTP. Its first attempted run was blocked while the new typed
compatibility service and its sole caller were being integrated; that compile
log is retained, and the second run passed after integration. No fallback
compatibility getters, SOURCE edits or changes to older Guardian evidence were
made for this test.

`NEXT_GUARDIAN_REQUEST_LOGOUT.json` in the same review directory records both
runs and the two passing assertions at SHA-256
`aec0f1dfc493e0769489c28bda629331351d4dcc2dc91b54ca355fa2c42c0681`.
Its `additionalUniqueCoverage.case` label contains a documentary inversion;
`NEXT_GUARDIAN_REQUEST_LOGOUT_CLARIFICATION.json` corrects that label without
changing the sealed receipt. The assertion blocks null-success and returns the
non-null non-success message, as described above.

## 9. Decline and cancel account lifetime — 6 October 2026

**Trace:** OA-ZYRA-289 and OA-ZYRA-305. This is a bounded, internally checked
local repair under the Founder's verified execution instruction. It is not
Founder acceptance, an OA closure, server acceptance or release approval.

### 9.1 As-built service change

Only `declineGuardianLinkRequest` and `cancelGuardianLinkRequest` in
`SOURCE/lib/services/zyra_wali_link_service.dart` changed. The service moved
from 59,969 bytes / SHA-256
`0929842abbccce5e628202b9a9911664a7a4ad11cce5e5b6e5a89f678df28a72`
to 60,971 bytes /
`41e8d60505d3db7526d73b97574077e284c8b0507475d264ec223513a438c339`.
Both methods now capture the actual Auth user and observed account generation,
reject an invalid entry before dispatch, and recheck that lifetime after the
RPC acknowledgement or exception before returning or publishing an invitation
revision. Late success/error from another account lifetime returns false.

The original outer try/catch remains, including the safe false result when the
SDK is uninitialised. Current-account true/false/error mapping, RPC names,
`p_request_id` payload, return API, link revision behaviour and no-retry
behaviour remain unchanged. Request, accept and capacity methods were not
changed. A discarded late acknowledgement is not proof of server failure or
rollback; the original server operation may already have completed.

### 9.2 Measured local evidence

The unchanged new 28-case service fixture first reproduced 14 failures and
14 passes on the pre-repair service. The failed run, assertions and observations
are preserved. After repair, the same 28 cases passed: both methods' current
true/false/error controls; late true/error after observed A-to-B, ABA, logout
entry and actual Auth mismatch without AccountState sync; and invalid-entry
zero-RPC controls. Both revision values and original actor/RPC counts were
checked. Four separate signed-out/SDK-uninitialised entry controls also passed.
These are 32 distinct new service cases, not 28 new cases for each repeat.

The service lane also repeated 75 retained checks (the earlier 72-case set and
the preceding three-case preflight set). The screen lane repeated 17 existing
preview/boundary checks separately. These are overlapping retained evidence,
not new ordinary screen-settlement coverage. Main independently repeated the
28 service cases, two public readiness controls and four extra entry controls;
those 34 repeats add no unique cases.

Full app source analysis and the targeted source analysis reported no issues.
External evidence-fixture analysis retained 22 service-lane and 13 readiness-lane
placement warnings, with zero errors; these warnings were not suppressed.
There was no native phone, provider, live database, real receipt or release
artifact measurement in this lane.

### 9.3 Caller remains unchanged and held

`SOURCE/lib/screens/wali/zyra_code_screen.dart` remains 62,187 bytes /
SHA-256
`029839431c16126c978a93fefb65b7d635bdc28880dde45491826bdaf2db226e`.
No caller repair is claimed. Two new ordinary public mount controls, one per
role, demonstrated the test admission block: SDK initialisation alone does not
set the private application readiness flag; the existing readers return
not-ready before HTTP, no pending request cards load and the public Decline/
Cancel controls cannot be reached. Both controls passed with zero HTTP but are
readiness observations, not mutation-settlement acceptance.

The requested screen assertions—old settlement cannot publish an error, clear
a newer busy state or trigger a reload—remain unmeasured. No bootstrap,
readiness bypass, private callback/state injection or new reader seam was
added. Rendered callback/read-refresh lifetime, `_load` and `_accept` remain
outside this patch. A separately scoped ordinary public generated-request
fixture path is needed before test-first caller repair; production readiness
must not be weakened to obtain that evidence.

### 9.4 Preservation, rollback and handover

Main's exact two-method comparison and independent read-only review confirmed
all other service bytes unchanged and the whole caller unchanged. Main's
source-tree comparison normalised only this service back to its pre-hash:
lib matched its baseline, and test, supabase, tool and ios trees were unchanged.
Native/package symlinks were not followed. Dependencies, native configuration,
backend/provider policy, approved app copy, UI and transitions were untouched.

True pre-change service/caller copies and the exact two-hunk diff are in
`SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/`:

- `NEXT_GUARDIAN_DECLINE_CANCEL_PRE_SERVICE.dart`
- `NEXT_GUARDIAN_DECLINE_CANCEL_PRE_CALLER.dart`
- `NEXT_GUARDIAN_DECLINE_CANCEL_SERVICE.diff`

Rollback was not executed. Any authorised rollback must first recheck the
current service hash and restore only the true pre-service bytes, without Git
or overwriting unrelated work.

The measured receipts in that directory are:

- `NEXT_GUARDIAN_DECLINE_CANCEL_SERVICE_RECEIPT.json`, SHA-256
  `ace7ac2350fbcb1023c0e1f00c4ec2b024fe2e44ebd2070287e97107df697368`.
- `NEXT_GUARDIAN_DECLINE_CANCEL_READINESS_RECEIPT.json`, SHA-256
  `93ad79a4baaa71746c86feb159e1d5c7ad4aaa353a96ed18e11524bbeb6abfc5`.
- `NEXT_GUARDIAN_DECLINE_CANCEL_ROOT_VERIFY.json`, SHA-256
  `b4388267f367de20a827959499d677a6ad3d6428270deab290a3e331a8af266a`.

The preceding 29,653 bytes of this handover were preserved as an exact prefix
and backed up to `NEXT_GUARDIAN_DECLINE_CANCEL_HANDOVER_BEFORE.md` at
SHA-256 `1af1effabc1c9971f0de5e535f478dfc84646d51f85cffafcc9498931517c4ea`.
Earlier source/document pins in sections 1–8 and their immutable packets are
historical snapshots, not assertions about this newer service. The compatibility
handover is unchanged at SHA-256
`61329fecb5b5b656b82f650287d41c9ef9d013745f56af82cb16f3f7ccaedd9e`.

ZYRA ADMIN remains the sole shared-register writer. This lane does not change
OA status, decision identifiers, scoring or release gates. The Founder is away:
no phone delivery was attempted. The unresolved screen test path and remaining
live/native/admission/commerce gates must stay explicit in the final relay.

## 10. Top-five client review — ordinary request caller repair (2026-10-08)

This is a new scoped caller stage, not a rewrite of section 9's service-stage
history. The Founder directly authorised the five review priorities in ZYRA
FINAL REALEASE, turn `01a11b99-0d84-7c51-8aa1-46e825adb2aa`, message
`01a11b99-0e4c-70e0-bafd-de46a2cc646d`. Main independently read that authority.
The local finding and repair trace to existing OA-ZYRA-289/305. ZYRA ADMIN
remains sole register writer; no status, identifier, score or release uplift.

### 10.1 As-built caller and unchanged boundaries

Only `SOURCE/lib/screens/wali/zyra_code_screen.dart` changed in this lane:
62,187 bytes / SHA-256
`029839431c16126c978a93fefb65b7d635bdc28880dde45491826bdaf2db226e`
to 65,735 bytes /
`510691e98378e9bac7f3eca9ccc58c4508c9eac36357caa8c39969504340e143`.
Two optional instance-only READ dependencies generate public request rows in
the synthetic fixture. Omitted parameters retain the exact existing service
readers and application not-ready boundary. There is no readiness setter,
global override or injected mutation callback. Production has no injected-reader
use. The original mutation services, RPC names, request/relationship payloads,
capacity preflight and privacy rules are unchanged.

Loads capture the actual Auth owner, observed account generation and latest-read
revision. Only a current, latest result can publish code/rows. The loaded
pending rows retain their owner/generation. Public Accept, Decline and Cancel
require that lifetime, the displayed pending row, mounted/current route and
ordinary non-preview state. One local lease is taken before any await, including
the relationship sheet. Ownership is rechecked before service dispatch and
after acknowledgement before error, onLinked or caller reload. A later
onLinked account/route change is rechecked before reload too.

The lease's finally block only releases the neutral local busy marker if still
mounted; a newer local mutation cannot start while the old lease is held.
Existing relationship cancellation, current-owner errors and genuine retry
remain usable. Copy/rotate/share/scan, relationship sheet, composer, camera and
remaining widgets are byte-identical to the true PRE. Main read the complete
original caller; an independent read-only agent checked the exact diff and
protected regions, finding no concrete issue. This is internal verification,
not Founder acceptance.

### 10.2 Test-first measurements and evidence

The original 20-case public caller fixture first measured 7 PASS / 13 FAIL.
Expanded retained-button, duplicate Accept, failure/retry and cancelled-sheet
controls produced a frozen 31-case baseline: 11 PASS / 20 FAIL. After repair,
the same entire 31-case fixture passed with no skipped cases. The original
6,888-byte 20-case body is byte-identical; the final measured fixture is 21,499
bytes / SHA-256
`99df583bd26c4819f9128dc29d67715a3788d81c5bed964ff28e9953fdaa01d8`.
No test assertion was relaxed.

The repaired cases cover late A-to-B/ABA errors, stale initial or superseded
reads, a relationship result under a replaced actor, retained old-row callbacks,
duplicate actions, current ACK, disposal and genuine retry. Targeted analysis
reported no issues. Ten relevant files repeated 103 PASS / 0 FAIL: seven SOURCE
files and three unchanged strict service fixtures. These repeats are not 103
new ordinary acceptance gates. The broader final main results are recorded in
the App Flow handover and aggregate receipt, not added to unique coverage here.

Rejected fixture-setup/missed-tap/async-assertion iterations and the first
spinner-timing guard iteration are retained and qualified in the packet, not
represented as valid production failures or passing acceptance. The strict
fake transport records unexpected routes/payloads rather than running a test
API inside the async callback.

Evidence is in
`SYSTEM/RESOURCES/REVIEWS/OA305_TOP_FIVE_CLIENT_2026_10_08/P4_CODE_CALLER.json`,
201,494 bytes / SHA-256
`e40e457053bee7e65c23565ba6e2edeae562be2dad2ac8842288ab2587532e07`.
True PRE, seam-only checkpoint, frozen baseline/final source and fixtures are
retained alongside it. The earlier `P3_P4_FLOWS.json` contains the preceding
read-only/service stage and an appended seam-baseline stage; its early
source-edits-zero statement is scoped to that earlier stage, not this repair.

### 10.3 Limits and delivery

This is local, synthetic ordinary Guardian-rendered caller proof with the real
public buttons and Father relationship branch, not a live admission bypass.
The application readiness flag stays false; only reads are injected. Actual
mutation services use strict fake HTTP under a synthetic `.invalid` session.
Seeker capacity, real JWT/RLS, relationship eligibility, provider identity,
server acceptance and multi-device races are not proved. No already-visible
old snapshot cleanup or full navigation-stack exhaustiveness is claimed.

These guards do not cancel a request already sent, revoke SDK sessions, undo a
remote commit or prove rollback. Native provider/recovery, intended release
artifact, identity and commerce acceptance remain separate. Main's signed
local PROFILE candidate includes this caller but the paired iPhone is currently
unavailable: no new installation or physical acceptance. Concept-only Pause
visibility and the held question-arrival body-scroll/fixed-cue choice are not
activated by this repair. No Git, backend migration, live data, provider or
payment action was performed.

The complete preceding handover is preserved as an exact prefix and backed up
to `HANDOVER_PRESTATE/CODE.md.PRE`, SHA-256
`68564a6d0793e7afd292d3644e8a067a968619a64c6ef5a6776bc2b220676630`.
Rollback was not executed; any rollback must first validate current bytes and
restore only this lane's true PRE under separately confirmed scope.

## 11. Original Invite composition reused in protected current UI — 19 October 2026

Founder requested the already-built original page, not a new visual design.
The protected Seeker Guardian Add action now opens LinkGuardianScreen and the
existing full/compact ZyraCodeScreen composition instead of the held placeholder.
It supplies a captured ZyraCodeLocalPreview adapter and inherited Back leading.
Ordinary/signup layouts and the live discovery-handle/request-then-accept contract
above remain; this integration does not activate a live request service.

Explicit local mode is terminal, never a fallback to ordinary services after
revocation/replacement. It binds owner/account generation, preview session, role,
adapter identity, route/lifecycle and caller cover epochs. Local demo-code lookup
uses only the supplied opposite-role fixture. Copy/Share/Scan/Rotate are truthful
local notices, QR is local, and confirmation says no request was sent. No native
clipboard/share/camera, telemetry, ambient capacity, AppState/DevScenario mutation,
onLinked callback or relationship RPC is invoked by that mode. A cover invalidates
pending lookup/results and makes the form retryable without losing typed input;
stale completions cannot overwrite a newer result.

Actual preimages are GUARDIAN_INVITE_PRE in76vv6v; ordinary caller lifetime suites
remain required alongside the new local suite. Real-font standard/compact200
own-code, entry and confirmation renders are planned, not yet inspected. Frozen
combined qualification/build/native delivery and Founder acceptance remain pending.
No production database/provider/security/signing/trust/release change occurs.
Existing OA151/289/304/305 retain ownership; shared registers remain ADMIN-owned.


### Combined scope clarification — 19 October 2026 (prepared)

The same `76vv6v` packet now uses hash-pinned `COMBINED_SCOPE_PLAN_4.json`:
4,828 Source inputs, the same 78 changed paths/75 existing Dart format targets,
85 primary suites, 51 proposed final frames and nine documents. Plan3 and all
failed diagnostics remain immutable history. The unchanged opt-in real-HEIC
acceptance suite requires separately authorized protected fixtures; none is
supplied here, so its skipped guard is excluded from primary qualification,
not reported as a pass. Synthetic processor/import coverage stays in scope.

Prepared regression found and repaired a Back callback identity issue that
re-armed the visible control during a consumed-state rebuild; the callback is
now stable for its guarded binding epoch. With the keyboard and enlarged text,
Circle comparisons use the available safe height and natural-height name/date
rows, retaining full names and existing selection guards. Stale fixture labels,
old vertical-only returns, exact wrapped-header assumptions and synthetic
keyboard lifecycle inputs were corrected without relaxing ownership, route,
privacy or network boundaries. Fresh affected-test replay and full frozen
checks/build/native delivery are still pending; no physical acceptance or live
photo-storage activation is claimed.


### Frozen checks and visual limits — 19 October 2026

Packet `76vv6v` now has clean frozen analysis and 1,861 distinct passing app
cases across 85 disjoint primary suites, with zero failures/skips. All 46
native/build recipe contracts pass, along with five overlapping visual replays,
75-file zero-change formatting, no-Git policy proof and 24 index tests. Root
opened all 51 final frames. These are internal checks, not Founder acceptance.

The first BUILD_PREFLIGHT invocation failed before execution because its
inspector path was relative to Source. Its receipt/log/companions remain
unchanged failure evidence. Absolute BUILD_PREFLIGHT_2 passed with 177 retained
host files, compatible engine and adequate space. A bounded report-only repair
captures the original fifteen-module qualification map and finalizer bytes;
only that report assembler changed, with all fourteen other modules (including
the twelve native/build producers) unchanged. Required prior checks bind their
original map/times; the retry binds the reporting-time map and exact absolute
arguments. Both maps and the preserved failure remain explicit in the packet;
no app Source, test result or native producer was altered by this repair.

OPEN visual finding under OA151/304: at 320x568 with 200% text, the pre-existing
whole-page Guardian FittedBox shrinks its body to unreadable size. Its complete
fit-to-one-page builder is unchanged from installed PRE. Normal-size header
alignment/labels pass, but compact200 readability is NOT accepted. Replacing
that single-page policy with scrolling is deferred for a separate scoped
Founder layout choice, not silently included in this photo/retirement patch.
Real-device photo acceptance and real-HEIC fixture acceptance remain separate.
Current native build/install/launch/post are still pending at this checkpoint.


### Built, awaiting fresh unlock — 19 October 2026

`76vv6v/HOST_PROFILE.1jO5Io/BUILD.json` is successful. The contained current-Dart
plus freshly regenerated objective_c / measured retained-host PROFILE build ran
02:53:35.366–02:54:16.639 UTC, with no full Xcode build. Compiler postcheck
verifies 3,571 regular input hashes plus one absent marker; existing main-app
identity/signature checks pass. CHECKED_AS_BUILT and BUILT_AS_BUILT retain the
4,828-input/78-path Source, 1,861 cases/85 suites and 51 inspected frames, with
the explicit pre-existing compact200 Guardian readability limitation above.

Fresh same-device LOCK at 02:55:50.024–02:55:54.297 UTC confirmed the paired
phone is locked (`sameDevice=true`, `unlocked=false`). No INSTALL/LAUNCH/POST
was attempted for this candidate. One current-candidate unlock question was
sent; after a reply, revalidate unchanged Source/artifact/identity and a fresh
positive lock check before installing. Last verified installed candidate stays
bjV1Jf in packet4oS3WH, not this new build. No sign-out/Google test, backend,
provider, signing registration, trust, upload or public-release action occurred.
Real chosen-photo acceptance on the iPhone and Founder acceptance are pending.



