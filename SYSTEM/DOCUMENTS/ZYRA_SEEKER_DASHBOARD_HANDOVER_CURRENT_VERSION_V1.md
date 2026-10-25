# ZYRA Seeker Dashboard — Implementation Handover

**Version:** V1  
**Status:** CURRENT_VERSION — CODE COMPLETE; Fable documentation check and Founder device observation pending  
**Date:** 2026-08-24; amended 2026-08-30  
**Implementer:** Codex, Lead Architect  
**Authority:** Founder direct instruction in Codex conversation, 2026-08-24  
**Related governance:** AD-AIOS-099; AD-AIOS-104; DR-ZYRA-214; DR-ZYRA-216; DR-ZYRA-217; DR-ZYRA-222; DR-ZYRA-223; OA-ZYRA-257; OA-ZYRA-264; OA-ZYRA-265; OA-ZYRA-281  
**Product source:** `APP/Navigation/SEEKER NAVIGATION/Summary.md`

> **Current production authority — 2026-08-28:** §13 records the
> OA-ZYRA-265 / DR-ZYRA-217 Dashboard-as-Home implementation now live. §12
> remains the OA-ZYRA-264 typed truth-boundary foundation. Where earlier
> sections describe a Notifications card, deny a consolidated Journey
> projection, or use the four-level resolver renderer, §13 supersedes only
> that presentation shape. Earlier measurements remain dated evidence.

> **Presentation ruling — 2026-08-30 (DR-ZYRA-222 D1):** the six-level Home
> presentation recorded in §13 is RULED-SUPERSEDED by the three-tab Seeker
> Dashboard (Today · Updates · Insights). CORRECTED 2026-08-30: production
> code moved to a three-tab renderer on 2026-08-30 (after §13's 2026-08-29
> verification; unrecorded build — audit, drift correction and a fresh
> handover proceed under OA-ZYRA-281; build authority to be stated in
> Phase 1). §13 is now a DATED as-built record of the six-level build.
> Content rules survive re-homed per DR-ZYRA-222 Decision 2. Insights
> governance: `ZYRA_INSIGHTS_SYSTEM_CURRENT_VERSION_V1.md`; module contract:
> inventory V3.

> **Live Updates wiring — 2026-08-30:** §15 records the final OA-ZYRA-281
> client wiring after migration `20260830145711` was applied and independently
> verified. It supersedes §14.2–§14.7 wherever those sections describe a
> client-assembled Updates path, a staged/unapplied projection, or a pending
> client-wiring gate. The three-tab information architecture itself is
> unchanged.

> **2026-08-25 developer comparison addendum:** Six role-aware Dashboard
> concepts now exist behind authorised developer access. They do not replace
> this production Dashboard. The current as-built Lab authority is
> `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V5.md`.

## 1 · What was built

The Seeker shell's third navigation destination is **Dashboard**, not a
standalone Notifications tab. For a normal authenticated Seeker it is also the
default landing page. The Dashboard is a real hub with these live workflows:

- Connections — opens the existing Seeker Connections tab.
- Guardian — opens the existing Seeker Guardian tab.
- Notifications — opens the existing full Notifications manager.
- Guardian invitations — shows only existing sent/pending or received-preview
  state and its actions. Generic bearer-code entry lives behind Guardian `+`.

The existing unread notification count remains visible in two places: the
Dashboard navigation item and the Notifications card. Opening Dashboard does
not mark notifications read. Returning from the Notifications manager causes
the shell to refresh the unread count immediately.

The bottom-navigation order is unchanged. Invitation status/actions moved out
of the Seeker Guardian page; linked-Guardian detail/add functionality remains.

## 2 · Why this shape

The Founder reported that the expected Dashboard replacement was absent. The
measured live state confirmed that `HomeShell` still mounted
`NotificationsScreen(isTab: true)` and labelled the fourth navigation item
`Notifications`.

The implementation uses a hub rather than merely renaming the notification
feed. That keeps the title truthful and preserves the full notification
management controls without duplicating their service state. It also avoids
inventing Journey or Guardian counts that the current client has no singular,
truthful cross-surface projection for.

## 3 · Architecture and data flow

```text
ZyraNotificationService unread poll
                 ↓
        HomeShell._unread
          ↙             ↘
Dashboard nav badge   Dashboard Notifications card
                              ↓ tap
                    NotificationsScreen (pushed route)
                              ↓
        fetch / mark read through ZyraNotificationService
                              ↓ return
                   HomeShell._refreshUnread()

Dashboard Connections card → HomeShell._goToTab(1)
Dashboard Guardian card    → HomeShell._goToTab(3)

ZyraGuardianInvitationDashboard
    ├── fetchPendingInvites() → pending sent rows
    └── revokeInvite(token) → cancel live sent invitation

Guardian page + → LinkGuardianScreen
                    ├── AcceptWaliInviteScreen → review/accept incoming code
                    └── LinkGuardianPanel → create outgoing code
```

`HomeShell` remains the singular owner of tab selection and unread polling.
`SeekerDashboardScreen` receives its navigation callbacks and hosts the shared
invitation module. That child owns only the existing invitation reads/actions;
it does not take over shell navigation. `NotificationsScreen` remains the
singular notification feed/selection/read-state implementation.

## 4 · Navigation and entry points

- Seeker bottom navigation: Browse · Connections · Dashboard · Guardian · Profile.
- Dashboard is tab index 2.
- `HomeShell` defaults to index 2 and normal Seeker branches in
  `ZyraSessionRouter` route there. Auth, missing-profile and role-selection
  branches remain exceptions; this amendment does not claim every possible
  deep-link/security flow was device-observed.
- Notifications is reached from the Dashboard Notifications card as a pushed
  route with its normal back arrow.
- The live unread badge remains on tab index 2.
- Guardian `WaliHomeShell` and its Notifications tab are not changed.

## 5 · Live files and content hashes

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | New Seeker Dashboard hub and responsive glass cards | `34421f1e88c3ca97c30304ddf89c8b3d99669a846114b0ea35d05a9d647c8d22` |
| `SOURCE/lib/screens/home/home_shell.dart` | Mounts Dashboard at tab 2, routes its cards, carries unread badge | `12c5f17262948efc2ca92d9eb41b4967c465122db9cb9e5e62b38080e95d5f69` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | Current Seeker page identity and destination order | `68f3bbe6c8873e9aa7a98fb6021d9760f4c4ae080f7b339fec5fcbf52d7120a0` |
| `SOURCE/lib/dev/zyra_page_preview_screen.dart` | Dashboard preview inventory | `70ca7f72c816b834f9fb46ee04e850689229e3bf27772cf5bad2f6679b23aa20` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | Page-aware Dashboard controls/destination order | `617dd2b820c9b4420f4b8fa4b796c1dee38e7b2bc62ee2e2b5eecd3ec34249dd` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | Focused content, callback and large-count tests | `f48dcf3cc9913932ffe05cd9745c905196019a8e02dd8d5c98ddf84e2bdae838` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Dashboard fixture at phone widths and large text | `470d60065ef60dab0a1057a572f46795c698e9378290c49e7051b57075f843e4` |
| `SOURCE/test/app_shell_correctness_test.dart` | Locks page and item order to Browse, Connections, Dashboard, Guardian, Profile | `678f50236ca162b03eab5b93a7a6ae9d17469cb20101acc549b3df7a133b1698` |
| `APP/Navigation/SEEKER NAVIGATION/Summary.md` | Product navigation truth updated to Dashboard order | `a5c553bc9ca290623c16811d4909ead7a8e5c26f842178f0972209ef90e8f4de` |
| `SYSTEM/RESOURCES/UI_GATE/ui_gate_config.json` | Retired Bell replacement points to Dashboard notification access | `167a54845e05d34450073c27a866e2b0d6bc51f217464cdacdc8ffac93890c52` |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | Adds Seeker Dashboard as an A-risk render fixture | `8b1bf7cadf32b0173bacb3cdb785e77e51123bc1e4ca8169ebd6d00476bad2db` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V3.md` | Regenerated repository documentation map; includes both Dashboard and navigation-haptics handovers | `e5483eb32febd94a27cf0ba9afb4fa48134c05bc14ec98efb5436fd1e6d89e20` |

This handover is itself the current as-built record; a self-hash is omitted
because embedding it would change the value it records.

The UI gate also regenerated its component, token, developer-toggle,
terminology and duplicate/dead-UI inventories plus `state.json`,
`visual_state.json` and the candidate manifest. Final run evidence is:
`SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_VISUAL_AUDIT_2026-08-24_2cdf8d91.md`
(`3f635883c9de740f2e47dc0769d045dfbb8d5d79448caf205b399e73670a63ec`).

## 6 · Developer controls; mock versus production

- `DevPage.dashboard` is now the current page identity for Seeker tab 2.
- Preview Control lists the three Dashboard destinations and both notification
  attention states.
- Action Control states explicitly that notification badge data comes from
  real actions; no synthetic notification switch was added.
- Debug/profile and release builds use the same Dashboard widget and routing.
- No fake unread count or entitlement bypass was introduced. Named received
  invitations remain labelled developer preview because the bearer-code schema
  cannot address/query a recipient before the code is entered.
- The visual test fixture supplies an unread count only inside the test process.

## 7 · Migrations and persistence

No database migration was created or applied. No schema, RLS, RPC, trigger,
storage or authentication changed. App Surface adds only a non-sensitive
device-local developer preference; Dashboard invitation state remains server
authoritative through the existing service and RPCs.

## 8 · Tests and measured verification

| Measurement | Result |
|---|---|
| Pre-change source trace | `HomeShell` mounted `NotificationsScreen(isTab: true)` and labelled tab 3 `Notifications`; no Seeker Dashboard screen existed |
| `flutter test test/seeker_dashboard_screen_test.dart` | PASS · 3/3 focused tests |
| `flutter analyze --no-pub` | PASS · no issues |
| `python3 tools/zyra_visual_gate.py --force --full` | BASELINE-PENDING only · all deterministic, analyzer, structural, render and complete-suite steps PASS |
| Visual render matrix | PASS · 48 render variants · small 320×568, standard 390×844, large 430×932, plus 1.3× text where declared · no new L2 findings |
| Focused landing/surface/Dashboard/Guardian suite | PASS · 82/82 |
| Guardian Network/Journey focused suite | PASS · 22/22 |
| Direct visual render suite | PASS · 190/190; no overflow or exceptions at declared fixtures |
| `flutter test --no-pub` | PASS · 488/488 current full suite |
| Database/SQL probes | Not applicable — no database change |
| Wireless iPhone delivery | PASS · signed profile build installed/launched on paired iPhone; Founder interaction/design observation remains pending |

The visual gate remains `BASELINE-PENDING` because zero screenshots have been
approved. It did not and may not self-promote candidates. This is existing
OA-ZYRA-257 governance, not a failure introduced by Dashboard.

## 9 · Known limitations and remaining work

1. **Fable documentation verification is pending.** Fable must check this
   handover against disk and reconcile any wider navigation references. Owner:
   Fable. No new OA allocated by Codex; Documentation Owner files register work.
2. **Physical phone observation is pending.** The Founder must confirm the
   Dashboard label, hub spacing and card navigation in the installed profile
   build. This is a verification step, not a known defect; no OA raised.
3. **The Dashboard intentionally does not claim consolidated Journey status.**
   Existing live surfaces remain the source of truth. Adding consolidated
   backend status cards would be a separate Founder product decision, not a
   defect in this authorised replacement; no OA raised.
4. **Production cannot list named received invitations before code entry.**
   `wali_invites` is a bearer-code flow and has no recipient address. The
   truthful code-review route therefore lives behind the Guardian page's
   top-right `+`; Dashboard is reserved for real pending/received status and
   collapses the module when no status exists. Named received rows remain
   preview-only. No migration was authorised or invented.

## 9A · 2026-08-26 amendment file evidence

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | Live Dashboard host including invitation module | `66fd2285c089ba84aaa51c559f8e1cec0cee2edc785c3de92f76b8e23d186693` |
| `SOURCE/lib/screens/home/home_shell.dart` | Dashboard default tab/index and live callbacks | `96bfb85bed460fb7a3082ede2b44a1119992877ab10a0016e5adcbf77db4b2b6` |
| `SOURCE/lib/services/zyra_session_router.dart` | Normal authenticated landing route | `016ea216d2e61e9230494d297031c2d5cd09f9476a14efe4715ee83be7f99635` |
| `SOURCE/lib/widgets/zyra_guardian_invitation_dashboard.dart` | Dashboard invitation-status UI and truth boundary | `687516b1fe2660eec63e921c1e8b6c836604362ef0f947df308422875898f941` |
| `SOURCE/lib/screens/wali/link_guardian_panel.dart` | Guardian `+` code-entry and invite-generation flow | `8ed079b4efcfff6b8604a99e481b5e442ac3d4f572ee153113eb15d479f34bf6` |
| `SOURCE/lib/services/zyra_wali_link_service.dart` | Existing invite reads/RPCs plus revision notifications | `808f1cb54b1c5e20b1166fcf13e7cb7eb02fe30b12178644940f6429915d2824` |
| `SOURCE/test/dashboard_landing_and_surface_persistence_test.dart` | Landing and restart persistence | `318e32ef996429482a3b2b20c71fe1722ed4ea700e7825c98ba4e1ebc0f7a6d2` |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | Invitation matrix, collapsed-empty state and duplicate-surface guard | `81cd6659b2c307d3f07ca559bfc65a559e910f780b6f7d16323d7bfe035a8c9e` |

## 10 · Authority map and superseded model

| Layer | Authority |
|---|---|
| Founder decision | Direct Codex conversation, 2026-08-24 |
| Product behaviour | `APP/Navigation/SEEKER NAVIGATION/Summary.md` |
| UI verification contract | `SYSTEM/DOCUMENTS/ZYRA_UI_CONSISTENCY_GATE_CURRENT_VERSION_V1.md` + OA-ZYRA-257 / DR-ZYRA-214 |
| As-built truth | This handover |
| Superseded model | DR-ZYRA-149's standalone Seeker Notifications tab; retained as history in the product Summary, not live navigation |
| Still-live nested surface | `SOURCE/lib/screens/notifications/notifications_screen.dart` |

## 11 · Next steps

1. Founder installs and observes the profile build.
2. Fable verifies this handover and reconciles/indexes documentation.
3. Any phone-observed defect receives an OA before further implementation.

No commit or git mutation was run. No migration was created or applied. Codex has not
self-approved this work.

## 12 · OA-ZYRA-264 production resolver and Guardian truth-boundary amendment — 2026-08-28

### 12.1 Authority and status

- **Authority:** Founder implementation instruction relayed in
  `SYSTEM/RESOURCES/MESSAGES/009_FABLE-CODEX_2026-08-28_GATES_AGREED_TRACE_FILED.md`.
- **Contract:** DR-ZYRA-216 and the acceptance bar in message 008 §“Tests and
  evidence required from implementation”.
- **Tracking:** OA-ZYRA-264.
- **Status:** CODE COMPLETE. Fable disk/document verification, Claude
  architecture review and Founder device/design acceptance remain pending.
- **Boundaries honoured:** no migration, no SQL application/probe, no
  entitlement gating, no git, production learning inactive.

### 12.2 What was built and why

The production Seeker Dashboard no longer composes independent legacy cards or
lets a mock Lab dataset decide importance. It now has one Flutter-free,
deterministic resolution boundary and one production renderer:

1. typed readers preserve `loading`, successful `available` (including empty)
   and `unavailable`;
2. a production adapter maps existing server-backed reads into a
   `DashboardSnapshot`;
3. `DashboardResolver` ranks object-backed signals without IO;
4. `DashboardResolution` carries one Answer, every remaining obligation, a
   stable Journey/search summary, at most three non-obligations, tone and
   source health;
5. `ZyraResolvedDashboard` renders exactly **Answer → Your Journey → Other
   Actions → Worth Knowing**.

This shape gives the user one immediate answer without losing a second real
obligation. Passive viewing cannot demote an unresolved action. A calm answer
is prohibited while any action-bearing source is loading or unavailable and no
known obligation exists. Deterministic ties are class → due time → event time →
stable ID. The Notifications manager remains reachable from a compact header
utility and unread badge; there is no generic Notifications card.

### 12.3 Architecture, data flow and failure flow

```text
Existing server-authoritative readers
  onboarding + Journeys + Notifications
  Guardian invites + linked people + Guardian activity
                    ↓ parallel read
ZyraSeekerDashboardAdapter
                    ↓ typed DashboardSource values
DashboardSnapshot
                    ↓ pure DashboardResolver (no Flutter/Supabase import)
DashboardResolution
  answer + otherActions + journey + worthKnowing + tone + sourceHealth
                    ↓
ZyraResolvedDashboard
  Answer → Journey → Other Actions → Worth Knowing
```

Reader failure is data, not an empty list. `ZyraSourceResult<T>` now preserves
Guardian reader failures. `SeekerWaliTab` and the Dashboard invitation module
show unavailable + Retry separately from successful empty. A failed invitation
refresh retains last-known authoritative rows; only a later successful empty
removes them. The adapter attaches all independent futures immediately and
maps each successful/null/typed result into its corresponding Dashboard source.
Production insight input is an honest successful empty source under
OA-ZYRA-259; no personal conclusion is activated.

### 12.4 Navigation and entry points

`SeekerDashboardScreen` owns production loading and maps resolver targets to the
existing destinations: Discovery, Connections/Journeys, Connections/Activity,
Guardian, Notifications, Profile, Preferences and onboarding. Journey summary
routes are stable: Searching → Discovery; Potential/Active/Paused/Ended →
Connections Journeys. The compact Notifications utility always opens the
existing full Notifications manager. Dashboard remains the normal signed-in
Seeker landing page; authentication/onboarding/deep-link guards remain outside
this slice.

### 12.5 Guardian Route 2

Guardian Pulse is the production Route-2 composition base inside the
Founder-directed near-full-page envelope. It shows role, one current state and
at most two real, privacy-safe activity rows. The four sibling Guardian page
designs remain developer-only comparisons. Safe activity wording is limited to
“Guardian link active”, “Shared a profile suggestion”, “Family Review
completed”, and “Family Review is open”, with the approved timing labels.
Unknown types remain safe; malformed identity/type/time rows are rejected.
Raw Family Review decisions, suggestion third-party names, “accepted
invitation”, and “connected and ready” are not exposed.

### 12.6 Live implementation and test files

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/models/zyra_dashboard_resolution.dart` | Typed snapshot/resolution contract and pure deterministic resolver | `3fdbbf062a8c9cf64f62cf19587bca7aa18ab33b11c47a5278d6baf94a505058` |
| `SOURCE/lib/services/zyra_dashboard_adapter.dart` | Existing live reads → production Seeker snapshot | `22c257e64a391d1484000c98d8340d380d496417084217d87fc49a20adb7f67f` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | Production load/retry lifecycle, Lab guard and route mapping | `42c37e085f86f0ec439d236d77594afde840f4d3ed3c6cb77297233a267f2386` |
| `SOURCE/lib/widgets/zyra_resolved_dashboard.dart` | Single production hierarchy and Notifications utility | `3b25056a5d2de21b4ac02f5ddecbebe0bdde644fb136043a8fbfc36df3c274b3` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | Five developer Lab presentations consuming the same resolution | `ca4e1b6c21923f569c49a4e6914fb18ff169b0d684196027d3e469cad158dd2e` |
| `SOURCE/lib/services/zyra_wali_link_service.dart` | Typed Guardian invite/link/activity truth results and safe activity parsing | `3ff3486b51d4633716b42339cff4147d4416faa2e39876a738af7bf184b4553a` |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | Loading/empty/unavailable Guardian host with independent Retry | `0f48b4ea79109c2f2109f9dfa9fe77759a634b8e8ec302d4c3aa0dd56e36e9be` |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | Guardian Pulse Route-2 renderer plus four dev-only siblings | `c25172cf10e9747b515e7fca3356f3b0f18d54cb5cefe79179774835212a1a4d` |
| `SOURCE/lib/widgets/zyra_guardian_invitation_dashboard.dart` | Typed invitation failure/empty/last-known boundary | `e32a7b2454ece6e4bef64ac9f341b4a5ba8f5fb6c87e6b7500fe88232b142989` |
| `SOURCE/test/zyra_dashboard_resolver_test.dart` | Pure priority, tie, health, cap and no-passive-demotion contract | `b729fb218506933209dc4aa7c11c68c9e251b0888de265a671479131054fcfb1` |
| `SOURCE/test/zyra_dashboard_adapter_test.dart` | Live-shape mapping and privacy boundaries | `8acf41cc5dca839763e2e263b502f928ccdcb1fabfb6d9825b38e4665ec9200c` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | Production hierarchy, failure, utility, Lab guard and 3-surface compact text | `29352e9ae94d773b5f6e5363d6ea873a53817b568f61b50108b5f366cb4ef728` |
| `SOURCE/test/dashboard_production_routing_test.dart` | All production destinations, Journey routes and action disclosure | `c53570d288ea8170f84dd3b77bbaec6919be7cb787606e5b035006ed3d5b6d32` |
| `SOURCE/test/dashboard_lab_test.dart` | Lab A–H/five-layout/three-surface parity on shared resolution | `2d9b5576896cc26bfc70e455a71c9b409f212e8c930a38cde097a16f8249ce83` |
| `SOURCE/test/zyra_wali_link_service_test.dart` | Typed source and all-four-type privacy wording/parser coverage | `2d297ce62546f78b7907f93a95c1ed60711b88b83c65895fdbdb825bc7aefc2f` |
| `SOURCE/test/seeker_wali_tab_truth_test.dart` | Guardian failed/empty retry boundaries | `c5dbd176e87790f7b9c4b0eff9edcf7cdc1076fc1bd84cfac1f6d7c73d27b422` |
| `SOURCE/test/guardian_page_design_test.dart` | 0/1/6 links, Pulse privacy, compact text and nav clearance | `3a87b8e6872c78ac0493db698fc3ad8b93d0a419d154490eef7b3488789ae87a` |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | Successful empty, unavailable Retry and last-known preservation | `d90af4d4411c21c2c9bd132f2d5fbae7479ed6fe05d013d5b0d1d9adce0acbdc` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Deterministic calm and resolved production Dashboard fixtures | `be34fe27c5b05b23316e110b817be2491fd59963bfb67b70896b28c362441248` |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | Adds resolved production hierarchy to governed visual matrix | `d9e9eb1356cde34fba33f939ecfa998363da46c8276aa371b55787baea54f81d` |

### 12.7 Developer controls and mock versus production

- No new developer control was added.
- Dashboard Lab remains authorised-developer-only. Its five visual concepts and
  A–H fixtures are mock presentation data, but they now build a snapshot and
  consume the same `DashboardResolution` used by production.
- Production uses only `ZyraSeekerDashboardAdapter` and existing live readers;
  it never reads a developer scenario as account truth.
- Guardian Pulse is the production base. The other four current Guardian page
  compositions remain developer-only until Founder selection/cleanup.
- The invitation loader injection is a widget-test seam only; the null/default
  path calls the typed live service and cannot grant production state.

### 12.8 Migrations, persistence and SQL

**None.** No migration file was created or applied and no SQL was run. Pause
“whose move” enrichment remains outside this slice under OA-ZYRA-261. Existing
Supabase tables/RPCs and server-authoritative state remain unchanged.

### 12.9 Measured verification

| Measurement | Result |
|---|---|
| Focused OA-ZYRA-264 command covering ten named test files | PASS · **119/119** |
| `dart format --output=none --set-exit-if-changed lib test` | PASS |
| `flutter analyze --no-pub` | PASS · no issues |
| `python3 -m unittest tools/test_zyra_check.py` | PASS |
| `python3 tools/zyra_check.py --quiet` | PASS |
| `flutter test --no-pub test/visual/zyra_visual_regression_test.dart` | PASS · **216/216**, including 215 render variants and manifest governance |
| `python3 tools/zyra_visual_gate.py --force --full` | Exit 0 · **BASELINE-PENDING** · 215 render variants across 65 fixtures; formatter, analyzer, structural checks, visual suite and complete Flutter suite all PASS; no open L2 findings |
| Governed final report | `SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_VISUAL_AUDIT_2026-08-28_27fcffb9.md` · SHA-256 `38f826d929e16580668562e4972261e0b3f21b1598b6d45706ed8d1380307359` |
| iOS profile build | PASS · `Runner.app` 34.9 MB; Xcode build 32.4s |
| Paired iPhone install/runtime | PASS · installed to device `00008130-001A2C1E26F8001C`; `flutter run --profile` exposed VM service; CoreDevice process list confirmed `Runner.app/Runner` PID 68754 |
| Founder visual/interaction acceptance | **PENDING — not yet measured** |

The first sandboxed gate attempt could not write Flutter's SDK cache; it was an
environment permission failure, not a product failure. The final escalated run
above is the governing result. Zero approved screenshot baselines exist, so
`BASELINE-PENDING` remains truthful OA-ZYRA-257 governance rather than an
OA-ZYRA-264 test failure.

### 12.10 Known limitations and next owners

1. **OA-ZYRA-264:** Fable verifies files/hashes and documentation; Claude then
   performs the independent architecture pass; Founder accepts copy/design on
   device.
2. **OA-ZYRA-261:** pause “whose move” requires separately authorised/applied/
   probed migration work and is absent here.
3. **OA-ZYRA-259:** production learning remains inactive; Lab insight states
   remain mock-only.
4. **OA-ZYRA-257:** approved visual baselines remain Founder-pending.
5. Current live Guardian activity supplies `linked` rows; the four-type
   privacy/parser contract is implemented and tested for future truthful rows.
6. Named received invitations cannot be queried before bearer-code entry with
   the present schema. No migration was authorised.
7. All new user-facing copy and the four sibling Guardian compositions remain
   pending Founder device/design review.

### 12.11 Authority, supersession and reconciliation

| Layer | Authority |
|---|---|
| Product/architecture decision | DR-ZYRA-216 + Founder authorisation filed in message 009 |
| Build/acceptance contract | Message 008 §“Tests and evidence required from implementation” |
| As-built Dashboard truth | This §12 |
| As-built Guardian truth | `ZYRA_GUARDIAN_PAGE_REVIEW_CURRENT_VERSION_V1.md` current amendment |
| Lab truth | `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V5.md` §10G |
| Superseded claims | Earlier Notifications-card and no-consolidated-Journey statements in this file; pre-resolver Lab-specific priority logic |

**Governed documents made stale by this change:** this handover's earlier
sections, the Guardian Page Review current section, Dashboard Lab V5,
Developer Control V1 and `APP/Navigation/SEEKER NAVIGATION/Summary.md` required
same-cycle amendments. Those amendments are included in this work.

**Reconciliation record:** Codex as-built amendments written; Fable
documentation verification and filing are pending. Codex has not self-approved
the implementation.

> **Fable note, 2026-09-01 (DR-ZYRA-226 reconciliation).** Two supersessions
> now sit above this handover's 2026-08-26 amendment, which describes a
> *Dashboard-owned* Guardian invitation workflow:
>
> 1. **DR-ZYRA-224 F2 (2026-08-30)** moved the full invitation lifecycle —
>    create, preview/continue, pending, expiry, cancel/revoke, decline,
>    detail — to the dedicated relationship pages. Dashboard keeps a compact
>    obligation summary and one Manage route, and loses cancellation controls
>    when the dedicated page ships.
> 2. **DR-ZYRA-226 (2026-09-01)** amends F2 in part: the underlying object
>    changes. `wali_invites` evolves from an unaddressed bearer token into a
>    **recipient-bound request** (sender, recipient, direction/context,
>    proposed relationship, pending/accepted/declined/cancelled/expired).
>    Dashboard ownership is unchanged — summary and route only.
>
> The as-built text above is **deliberately not rewritten.** It is the
> truthful record of what was built on 2026-08-26 and why, and rewriting it
> would destroy the evidence trail rather than correct it. Read it as history;
> read `ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V2.md` §2 and §2.1
> for current law. The linking model is RULED, NOT BUILT — its contract
> returns to the Founder before Codex sees it.

---

## 13 · OA-ZYRA-265 / DR-ZYRA-217 Dashboard-as-Home amendment — 2026-08-28

### 13.1 Outcome and reason

The production Seeker Dashboard is now a calm, conditional home over the
existing OA-ZYRA-264 resolver. The resolver remains the priority brain; the
renderer now gives stable state, movement and governed intelligence distinct
places instead of treating every fact as a competing card.

The governed order is:

`Header → RIGHT NOW → YOUR JOURNEY / YOUR SEARCH → MY ZYRA → FAMILY → RECENTLY → ZYRA INTELLIGENCE`

RIGHT NOW, Journey/Search and Family always have a truthful presentation.
MY ZYRA, Recently and Intelligence render only when their source has useful
content. Empty optional sections leave no heading or dead card.

### 13.2 Resolution and data-flow amendment

```text
existing live owner reads
  ├── onboarding progress
  ├── Journey rows + returned Timeline milestones
  ├── unread count + unread notification rows
  ├── linked Guardians + pending invitations + safe Guardian activity
  └── production insight source = successful empty
              ↓
ZyraSeekerDashboardAdapter
  ├── obligation / movement signals
  ├── stable Journey/Search summary
  │     ├── latest completed stage — returned milestones only
  │     ├── next milestone — canonical stage-map order only
  │     └── momentum — returned recent milestone only; quiet week is silent
  ├── DashboardStableState
  │     ├── source-aware MY ZYRA orientation items
  │     └── source-aware Family status
  └── at most one deterministic calm advisory with mandatory "why"
              ↓
DashboardResolver (pure and IO-free)
  obligation → action-gap failure/loading → movement → insight → calm/advisory
              ↓
ZyraResolvedDashboard (one production renderer)
```

Passive viewing never demotes an obligation. Equal-priority items use the
existing deterministic due/event/id tie-break. The selected movement or
insight is removed from lower sections so one event is not repeated.

### 13.3 Six-level behaviour

- **Header:** greeting plus compact Notifications utility and truthful unread
  badge. The full Notifications manager remains reachable.
- **RIGHT NOW:** exactly one resolver answer. A calm answer may add one
  separately modelled advisory; every advisory explains why it is shown.
  Remaining obligations are retained, two shown immediately and the rest
  behind an explicit `N more actions` disclosure.
- **Journey/Search:** remains the emotional centre and adapts across searching,
  potential, active, paused and ended. Latest/next/momentum lines render only
  when proved. No score, streak or invented future content is produced.
- **MY ZYRA:** compact useful orientation only. Zero Potentials/unread values
  are suppressed; informative Guardian absence remains. There is no Journey
  tile. Saved is deliberately omitted from production because the current
  decision reader cannot distinguish failure from empty and photo filtering
  can undercount; a misleading growth/count tile is not rendered.
- **FAMILY:** compact stable status always. Connected wording uses a
  relationship label only; missing relationship falls back to neutral
  `Guardian`, never the person's first name. A real pending invitation expands
  through the existing invitation component. The status surface is not a
  navigation card; only its explicit action navigates.
- **RECENTLY:** one newest-first stream, capped at three, with the explicit
  `View all notifications` footer. There is no Since-Last-Visit or This-Week
  section and no `last_seen_at` bookmark.
- **ZYRA INTELLIGENCE:** the renderer slot exists, but the production adapter
  supplies honest empty under OA-ZYRA-259. Test-only governed insight fixtures
  prove the presentation without activating automated conclusions.

At compact width or increased text size, the Family action moves beneath the
status lead. This repaired a measured 22-pixel horizontal overflow without
changing normal-width hierarchy.

### 13.4 Production, mock and developer boundaries

- Production reads `ZyraSeekerDashboardAdapter`; the client cannot stage live
  account truth from Dashboard Lab controls.
- Five Dashboard Lab skins remain authorised-developer-only. They use the
  shared resolver for priority, while still retaining all configured quiet
  mock modules for progressive comparison. This is not six-level production
  presentation parity and does not activate learning.
- Three visual fixtures now cover calm advisory/suppression, the resolved upper
  hierarchy, and the lower Family/Recently/Intelligence levels. The Intelligence
  fixture says explicitly that it is test-only.
- A pending-invitation visual fixture was deliberately not added: the live
  invitation widget owns an independent fetch. Its injected-loader tests cover
  empty, unavailable, received, pending, accept, decline and cancel states
  deterministically.

### 13.5 Files and hashes

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/models/zyra_dashboard_resolution.dart` | Stable-state, advisory, Journey-line and six-level resolution contract | `04e2af7ad50fe1c57d10f309385863773630c445c83c9f9bd038050b9717f7be` |
| `SOURCE/lib/services/zyra_dashboard_adapter.dart` | Existing truthful reads → Home snapshot; relationship-only Family copy | `66a3d3f4e187c9394e528ab3f4dfa945fc12627800adeb1c29d7839dba59cc41` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | Load/retry lifecycle plus complete loading/failure stable-state snapshots | `a6da1b8a0f7e24c401eca4b628d1ea4ca7a59068dc526e89cbb762df2a47d44a` |
| `SOURCE/lib/widgets/zyra_resolved_dashboard.dart` | Single conditional six-level Classic Glass renderer | `602ac48b7b2c12a3258bcf692fe6e41ef6b08a4e7cee34458e5da47dfe5b985a` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | Dev Lab priority parity with quiet modules kept reachable | `f16d9325e76971f820dec3abf248b333713f3c6a703e58af1664cc6566d6b4fb` |
| `SOURCE/test/zyra_dashboard_resolver_test.dart` | Ranking, advisory, stable-state, suppression and health contract | `e2c4a6d8d82ce8c2c6c5c411ae8cdb6f5a6a51e738e44054cdaaf8c1d80fb521` |
| `SOURCE/test/zyra_dashboard_adapter_test.dart` | Live-shape, Journey proof, zero suppression and Family privacy coverage | `0a0a085cca8ca658ff6e7c37bab75fb2d3414fb1fe00cbc5fcfd387891a5a5ca` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | Six-level order, suppression, advisory, routes and compact text | `aef92f0f390a4df107c3679fd5cb44542162726969414b39da67b318aa268227` |
| `SOURCE/test/dashboard_production_routing_test.dart` | Typed destinations and explicit action disclosure | `c53570d288ea8170f84dd3b77bbaec6919be7cb787606e5b035006ed3d5b6d32` |
| `SOURCE/test/dashboard_lab_test.dart` | A–H/five-layout/three-surface dev comparison coverage | `2d9b5576896cc26bfc70e455a71c9b409f212e8c930a38cde097a16f8249ce83` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Three Home fixtures across compact/standard/large/130% states | `fa81cc8bdb663ccbf5157117c24804f5848aaf08d71531bcd21b7d38640c388d` |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | Governed calm, resolved and lower-level Home fixture declarations | `71d8693e2dd49476c7a9a9d0d9605f89f27332b2de5ecdb7611d5d69d24a40f0` |

Representative candidate evidence remains non-authoritative:

| Candidate | SHA-256 |
|---|---|
| `SOURCE/test/visual/candidates/seeker-dashboard-unread__standard.png` | `8deac3a43c97933f4acd534add5832793b6276f20c484be6cf61a7b2f6289ab4` |
| `SOURCE/test/visual/candidates/seeker-dashboard-resolved-actions__standard.png` | `9557a4780f9c25595c432c92f522156cfae373698d863394fc6b3e08c11e9ff9` |
| `SOURCE/test/visual/candidates/seeker-dashboard-home-lower-levels__standard.png` | `1dc2ed90bae987aaca8b54feba4420416a50a1c2f950635b48f908b59cfb7260` |

### 13.6 Measured verification

| Measurement | Result |
|---|---|
| Focused resolver/adapter/renderer/routing/Lab/loading/icon command | PASS · **92/92** |
| `flutter analyze --no-pub` | PASS · no issues |
| `flutter test --no-pub` | PASS · **599/599** |
| Direct visual suite | PASS · **220/220** including manifest governance and 219 render variants |
| `python3 tools/zyra_visual_gate.py --force --full --capture-candidates` | Exit 0 · **BASELINE-PENDING** · 219 variants across 66 fixtures; formatter, analyzer, structural checks, visual/capture and full Flutter suite all PASS |
| Governing report | `SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_VISUAL_AUDIT_2026-08-28_2c73f4ad.md` · SHA-256 `9cf25e71f85b15f896472c454ec53b62ca3639021451ceafc76e293e107f634b` |
| `flutter build ios --profile --no-pub` | PASS · Xcode 53.5s · `Runner.app` 35.0 MB |
| Wireless device/install | Paired iPhone detected; `flutter install --profile` exit 0 on `00008130-001A2C1E26F8001C` |
| Automated launch/process observation | **PENDING** · Apple denied launch because the current development profile/signature is not yet trusted on the phone; no running process was claimed |
| Fable disk/document verification | **PENDING** |
| Claude architecture review | **PENDING** |
| Founder device/copy acceptance | **PENDING** |

There are zero approved visual baselines. Candidate PNGs are review evidence,
not design authority, and Codex did not approve them.

### 13.7 Migrations, limitations and next owners

**Migration/SQL:** none created, changed, applied or probed.

1. The legacy Timeline reader collapses failure into empty. Only returned rows
   prove latest/momentum; an empty result yields no claim rather than a false
   status. A future typed Timeline read must preserve failure separately.
2. Saved remains absent for the truth-boundary reason in §13.3. Fable decides
   whether a separate owner-count read belongs on the register.
3. Intelligence remains production-empty under OA-ZYRA-259.
4. No Seeker plan/entitlement read, Discovery Health, `last_seen_at`, new
   deadline or OA-ZYRA-261 “whose move” state was added.
5. Guardian Dashboard and G4 Browse chips are unchanged; Guardian sequencing
   remains after Founder acceptance of the Seeker Home.
6. New user-facing copy and candidate screenshots require Founder device
   review. Fable verifies disk and reconciles product/register/index truth;
   Claude performs the independent architecture pass.
7. Wireless pairing works and the package install command passed, but Apple
   refused automated launch with `RequestDenied · Security`. The one-time
   device action is Settings → General → VPN & Device Management → Developer
   App → trust the current Shakeel Ahmed development certificate, then open
   ZYRA. If that Developer App row is absent, Xcode → Settings → Accounts must
   create/download a valid Apple Development certificate first. This is an
   Apple signing/trust gate, not a Dashboard test failure.

### 13.8 Concurrency trace

File ownership for `SOURCE/lib/widgets/zyra_resolved_dashboard.dart` was not
predeclared correctly during one delegated renderer task. That worker deleted
the file while overlapping work was in flight, temporarily blocking compile.
The Lead Architect interrupted the worker and took ownership. The worker's
restored implementation then became the live base; the Lead Architect refined,
formatted, tested and hashed the final disk state. No change was lost. This
late trace records the overlap under the handover standard; future work must
declare one owner per file before editing.

---

+## 14. OA-ZYRA-281 / DR-ZYRA-223 Phase 2 correction and Updates projection — 2026-08-30

### 14.1 As-built outcome

Phase 2 reconciles the production three-tab Dashboard without reopening its
information architecture:

- Seeker Today no longer repeats movement from Updates. The old
  `dashboard-section-today-movement` preview is absent and the regression test
  asserts exclusivity rather than duplication.
- `AT A GLANCE` is now `MY ZYRA`; the section heading is `FAMILY` while the
  person/content identity remains Guardian.
- Updates and Insights now carry explicit `loading`, `available`, `partial`
  and `unavailable` section truth. A failed read cannot render a successful
  empty state.
- The production calm preference advisory is removed. Calm Today says only
  `Nothing needs your attention right now` and
  `There are no current actions waiting on you.`
- Seeker Insights honest-empty copy is exactly:
  `No insights available yet` and
  `ZYRA will only show an insight when real, governed evidence supports it.`
- Visual review exposed an existing initial-tab mismatch: an initially opened
  Updates/Insights page showed the correct page but highlighted Today. The
  pager position now starts from the same index as the PageController. This is
  an acceptance-critical state correction, not a layout redesign.

### 14.2 Current client flow and sequencing

The app deliberately retains the client-assembled Updates path until the
staged RPC is separately approved and applied:

```text
existing caller-scoped reads
  ├── unread notifications
  ├── Journey Timeline milestones
  └── safe Guardian activity
             ↓
typed source state (loading / available / unavailable)
             ↓
DashboardResolver
  ├── Updates state = combined notification + Guardian-activity health
  └── Insights state = independent governed source health
             ↓
role Dashboard renderer
  ├── failed/partial presentation with Retry
  └── successful empty presentation only after successful reads
```

After a separate migration apply GO, client wiring can replace this assembly
with `public.zyra_dashboard_updates` without changing the visible three-tab
law. No client call to an unapplied RPC exists in this build.

### 14.3 Guardian same-law delta

Guardian three-tab remains Today / Updates / Insights under DR-ZYRA-223. The
bounded Guardian changes are:

1. Today source failure no longer forces Updates or Insights into the same
   failure presentation.
2. Updates tracks its own Timeline aggregate loading/failure state, keeps
   last-known successful rows during a failed refresh, and clears them only
   after a successful empty read.
3. `ZyraWaliJourneyService.fetchTimelineResult` returns `null` on failure and
   an empty list only on a successful empty. Its attempt lookup uses the new
   typed `currentAttemptIdResult`, so an upstream failure cannot collapse to
   empty before the Timeline query begins.
4. Guardian Insights remains honestly empty under D6: zero Guardian insight
   families, process never behaviour, no Seeker behavioural intelligence and
   no filler.

The future Guardian shared-resolver migration G12 was not started.

### 14.4 Staged Updates projection

Staged file:

`SOURCE/supabase/migrations/20260830145711_oa281_dashboard_updates_projection.sql`

SHA-256:

`b17011aac9d5771eb76894f66559ab4e5ef941231ff121d5737e4255b6b60043`

The migration creates one read-only, caller-scoped projection for both roles:

- `stable security definer set search_path = ''` with fully qualified objects;
- caller only from `(select auth.uid())`, null caller returns no rows;
- limit clamped to 1–20 and complete three-part cursors required;
- branch-local notification, participation, suggestion and review ownership;
- controlled class/template/destination keys only;
- real unread semantics for notifications; no invented unread on domain rows;
- deterministic descending keyset order on
  `(occurred_at, class_key, source_id)`;
- no count and no user-data write; and
- execute revoked from `public, anon`, granted to `authenticated,
  service_role`.

Supporting indexes are staged for the five measured source families, with a
second `wali_id` suggestion index because the same system serves Guardian
callers. The live `journey_family_review_responses` table has no `id` column;
its real primary key is `(review_id, wali_id)`. The implementation therefore
uses `(review_id, responded_at desc, wali_id)` and derives a stable opaque UUID
from the composite key instead of manufacturing a schema column.

The connected-project read-only probe on 2026-08-30 confirmed the RPC and all
six new indexes are absent. The remote migration list ends at
`20260829183507_identity_verification_phase_a_storage`; OA-ZYRA-281 has not
been applied. Local executable SQL validation was unavailable because no
Docker/Podman runtime is installed, so the staged SQL is covered by static
contract tests and remains subject to Fable verification before apply GO.

### 14.5 Fixture and reversible evidence

The production matrix is now six fixtures × four variants = **24**:

- adjusted existing: unread/calm, resolved actions, lower levels;
- new: Updates populated, Updates successful empty, Insights successful empty;
- variants: compact, standard, large and standard at 130% text; and
- Lab fixtures untouched; no fake populated production Insight.

Candidate manifest:

`SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json`

SHA-256:

`47756a93f53494fc6e37fbc4380940db78c480caf9f2da84932291e1fc2a4648`

Candidates remain unapproved and cannot auto-promote. Forward/reverse evidence
is under `ARCHIVE/PATCHES_OA-ZYRA-281_2026-08-30/OA-ZYRA-281_PHASE_2/`. The documented
reverse command restored 12 files to exact pre-edit SHA-256 values and both
new files to absent: **14/14**. The restored tree passed clean analysis and
the original **667/667** suite. Forward restoration then matched every
recorded post-edit hash: **14/14**.

### 14.6 Final measured verification

| Measurement | Result |
|---|---|
| `flutter test --no-pub` | PASS · **691/691** |
| `flutter analyze --no-pub` | PASS · no issues |
| `python3 tools/zyra_check.py` | PASS · **0 findings** across 182 files |
| Direct visual suite | PASS · **232/232** including manifest governance and 231 render variants |
| OA-ZYRA-281 candidate capture | PASS · **24/24** renders |
| Reverse pre-state proof | PASS · **14/14** states; clean analyzer; **667/667** tests |
| Forward post-state proof | PASS · **14/14** SHA-256 matches |
| Remote non-application probe | PASS · RPC absent; six indexes absent; migration absent |
| Fable independent verification | **PENDING** |
| Founder direct device acceptance | **PENDING** |
| Founder migration apply GO | **PENDING** |

### 14.7 Preserved boundaries and next gate

- No insight store, Discovery Health object, dormant insight table or
  production Insight was built.
- `score_candidates` is untouched.
- No git operation was used.
- No migration was applied locally or remotely.
- Candidate screenshots are review evidence, not design authority.
- The next authorised steps are Fable independent verification, Founder
  device acceptance, and a separate Founder GO before migration application
  or RPC client wiring.

---


## 15. OA-ZYRA-281 live Updates wiring — 2026-08-30

### 15.1 As-built production flow

Both production roles now use one client reader and one live server source:

```text
public.zyra_dashboard_updates
             ↓
ZyraDashboardUpdatesService.fetchPage
  ├── complete three-part keyset cursor
  ├── closed title/detail/destination renderer
  ├── TRUE / FALSE / NULL unread preservation
  └── whole-page failure on malformed data
        ↙                         ↘
Seeker Dashboard adapter       Guardian Dashboard
        ↓                         ↓
Updates tab                   Updates tab
```

The previous Seeker unread-notification plus Guardian-activity assembly and
the Guardian per-Journey Timeline fan-out are removed from Dashboard Updates.
Those source services remain available to the surfaces that own them. The
Dashboard does not run the old and new systems in parallel.

### 15.2 Truth and failure contract

- RPC success with rows is `available`; RPC success with zero rows is an
  honest empty state; RPC failure is `unavailable`. The single projection
  cannot manufacture a branch-level `partial` state.
- A failed refresh retains previously successful rows only as visibly
  `LAST-KNOWN UPDATES` / `showing last-known rows`; it never paints them as
  fresh and never replaces failure with empty.
- `is_unread = TRUE` receives the unread affordance. `NULL` receives no read
  indicator or read semantics. `FALSE` is preserved for the reserved future
  explicit-read contract but is unused by the live projection.
- Every key emitted by migration `20260830145711` is present in the closed
  renderer. If any title, detail or destination key is unknown, the whole row
  becomes `Update available` / `Open ZYRA to review it.` with no navigation.
- Guardian person context is resolved only by matching `related_match_id` to
  the already-authorised Journey roster. No name or new identity field was
  added to the definer projection.

### 15.3 Live performance evidence

Read-only post-index evidence was taken against the live project with real
caller claims and `EXPLAIN (ANALYZE, BUFFERS)`:

| Case | Evidence |
|---|---|
| Long-Journey Seeker | 3 authorised participations; 16 authorised milestones; 20 returned domain rows; full RPC 19.543 ms; 1,956 shared hits; no reads or temp spill |
| Multi-Seeker Main Guardian | 12 linked Main-Guardian Seekers; 6 authorised participations; 20 rows across 3 related matches; zero suggestion rows; full RPC 14.986 ms; 1,958 shared hits; no reads or temp spill |
| Four live keyset pages | 5 / 5 / 5 / 5 rows; 20 total and 20 distinct `(class_key, source_id)` pairs; pages disjoint |
| Notification branch | 0.095 ms at 7-table-row cardinality |
| Suggestion branch | 0.089 ms at 1-table-row cardinality |
| Milestone branch | 0.583 ms, 16 authorised of 23 table rows |
| Review-open branch | 0.433 ms, 4 authorised of 4 table rows |
| Review-response branch | 0.108 ms, successful empty at 0 table rows |

At today's tiny tables the normal planner correctly prefers small sequential
scans for several branches. A diagnostic index-eligibility plan, with
sequential scans disabled only for planning evidence, selects all five live
Dashboard indexes by their exact names. Notifications and suggestions are
directly caller-keyed; Timeline and review branches join through the
caller-scoped participation rows on attempt plus match before presentation.
No branch authorises an unbounded cross-user result. A numerical Dashboard
latency budget is not defined in 043 or the governing Dashboard documents, so
the measured 14.986–19.543 ms server execution is recorded without inventing
a pass threshold.

### 15.4 Fixtures and verification

The OA-ZYRA-281 production candidate set is now 10 fixtures × 4 variants =
**40**. It covers Seeker and Guardian populated Updates, successful empty and
visibly last-known states, plus the retained Seeker Today/Insights acceptance
surfaces. Every candidate is `approved:false`; automatic promotion remains
disabled.

| Measurement | Result |
|---|---|
| Focused wiring / resolver / role / migration suite | PASS · **101/101** |
| Full Flutter suite | PASS · **724/724** |
| `flutter analyze --no-pub` | PASS · no issues |
| `python3 tools/zyra_check.py` | PASS · 0 findings across 183 files |
| Direct visual suite | PASS · **248/248** |
| OA-ZYRA-281 candidate capture | PASS · **40/40** |
| Migration source integrity | unchanged live-applied source; no schema or migration edit in this wiring round |
| Fable independent verification | PENDING |
| Founder final visual inspection | PENDING |

No insight store, schema change or new migration was created;
`score_candidates` remains untouched; no git operation or self-approval was
used.

---


## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-24 | Replaced the Seeker standalone Notifications tab with Dashboard while preserving full notification access and unread state. |
| V1 amendment | 2026-08-26 | Made Dashboard the normal authenticated landing, added the Dashboard-owned Guardian invitation workflow, and documented its bearer-code/preview boundary. |
| V1 amendment | 2026-08-28 | Added OA-ZYRA-264 typed sources, pure resolver, production adapter/single renderer, truthful Guardian failure states and Route-2 Guardian Pulse evidence. |
| V1 amendment | 2026-08-28 | Added OA-ZYRA-265 / DR-ZYRA-217 six-level Seeker Home, stable state, calm advisory, Journey proof lines, intelligent suppression, lower-level visual fixtures and measured gate evidence. |
| V1 amendment | 2026-08-30 | Added OA-ZYRA-281 / DR-ZYRA-223 three-tab correction, truthful per-tab failure law, Guardian same-law conformance, staged one-system Updates projection, 24-variant evidence and reversible proof. |
| V1 amendment | 2026-08-30 | Wired both production Updates tabs to the live caller-scoped projection, removed parallel client assembly, added tri-state unread, fail-closed templates, visible last-known rows, Guardian match context, live performance evidence and 40 unapproved candidate variants. |
