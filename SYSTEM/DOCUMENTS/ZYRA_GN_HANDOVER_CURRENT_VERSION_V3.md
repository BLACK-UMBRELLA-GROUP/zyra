---
id: DOC-ZYRA-0176
type: HANDOVER
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA — Guardian Network: Implementation Handover
links: []
owner: ZYRA chat
---

# ZYRA — Guardian Network: Implementation Handover

**Document:** ZYRA_GN_HANDOVER_CURRENT_VERSION_V3.md
**Version:** V3
**Status:** CURRENT_VERSION — the implementation handover for Guardian Network. This is the third document of the GN triad and answers "what actually exists in the app". Product rules live in the specification; build obligations live in the contract; THIS file records reality, verified against the live files by SHA-256 and refreshed through the Portrait focus default and Browser action-layout addendum of 2026-09-27.
**Date:** 2026-09-27
**Owner:** Founder
**Author:** Fable (Documentation Owner)
**Latest addenda:** Codex under AD-AIOS-111; historical authorship retained.
**Standard:** `IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md` (`BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/`) — the ONE group-wide authority for BUILD → DOCUMENT → TRACE → HANDOVER. The concurrently-created `IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md` is archived and superseded.
**Register:** OA-ZYRA-247 (D14 ratification/build) · OA-ZYRA-248 (Draft 3.x restructure) · OA-ZYRA-249 (tablets, open) · OA-ZYRA-250 (listener-leak crash fix) · OA-ZYRA-251 (retired-preview cleanup) · OA-ZYRA-252 (this handover + single-source fix) · DR-ZYRA-213 / OA-ZYRA-255 (four-state production access correction).

---

## 2026-09-27 Portrait focus default and Browser action-layout addendum — OA-ZYRA-257

Founder selected **4 · Portrait focus** from the five Network card treatments
as the temporary constructor/reset default. All five remain selectable; this
supersedes the earlier provisional card default without changing D14 authority,
privacy, states or production access. The shared mode-pill gutter remains.

A separately grouped **Network Browser actions** comparison contains Current,
Quiet Next, Speak first and Profile first. Current remains the action default.
The alternatives respectively reduce Next's visual weight, lead with the gold
contact action, or lead with View profile. Browser controls now have44px tap
targets. All choices retain the same captured-family callbacks and visible
labels: **Next sets aside and advances**, View profile opens the bounded photo
viewer, and Main-only Speak opens the request confirmation. Additional contact
remains disabled; Sent/Received controls and their styling are unchanged.
No live service, backend policy, migration, Auth or payment action was added.

The current UI Consistency Gate handover records six source/test hashes,
50 focused passing tests, clean six-file analyzer/formatter checks, the
repaired Browser target-size finding, and eight unapproved real-font candidates.
Both standard and compact/enlarged-text matrices cover all20 design/action
combinations. Compact captures show scroll-reachable actions, not whole-page
no-scroll fit or untruncated long labels. The recommendation of Quiet Next is
design judgement, not measured skip-rate evidence or Founder selection.
Fresh main PROFILE/production Founder-opt-in build and strict signature/main
identity verification passed. Physical iPhone install sequence4688, direct
launch and new executable PID43242 were post-verified; the current UI handover
records its final hash/container. Internal verification and installation remain
separate from Founder physical acceptance and action-layout selection. No
TestFlight upload or production Network activation.

---

## 2026-09-27 Network mode-pill spacing addendum — OA-ZYRA-257

The Founder requested cleaner separation between the Browser/Sent/Received
mode pill and its card, without selecting one of the five preview designs.
`SOURCE/lib/screens/wali/wali_network_screen.dart` now has a fixed 16px
gutter after the pill and outside the shared PageView. The existing 4px
scroll-child top padding yields about20px initial card clearance, while the
fixed gutter survives vertical scroll. All five designs and three tabs share
it; Expanded body/card height gives back the same16px on normal viewports, so
bottom actions keep their clearance. The no-Seeker and production access
branches are unchanged. The current UI Consistency Gate handover carries
source hashes, 26 focused passing tests, 15 unapproved visual candidates and
local delivery evidence. This is a presentation-only, developer-preview
change; the five choices and D14 product/authority boundaries remain open as
before. It is internally checked, not a Founder design acceptance.

---

## 1 · PRODUCT — the rules this build implements

**The ONE authoritative specification:**
`ZYRA/SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_NETWORK_CURRENT_VERSION_V2.md`
— §D14 (the ratified interaction model) is **binding**: the Rung 0–4 ladder (Recommendation → Request connection → Connected → Proceed to the Seekers → simultaneous reveal), silence discipline (14-day quiet expiry → "No longer active"; 90-day initiator-side wait; 6-month pair cooldown), live-process cap of 3 per Seeker context, access-ends-on-closure, three separate Seeker consents (participate / photo level with after-connect DEFAULT / pause), calm delivery, Main-Wali-only authority, Guardian+ per guardian (ZYRA One covers the Main Wali only — WORKING RULE pending pricing mirror), no search/enumeration, per-stage analytics, and the exact naming set.
— The Surface-layout addendum (2026-08-23) records the Founder's Draft 3 ruling: **the Dashboard is the home of everything about the user** — Connections renders there; the Network page is Discover-only; one shared Seekers-by-name slider on both pages.

**The build contract:** `ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md` — Rules 1–44 plus two in-place amendments: Rule 44 amended for profile-mode dev switching (the Founder tests unplugged), and the "GN DRAFT 3" amendment recording the surface moves, the shared GN library, and the retirement of the Discover/Connections toggle.

**Approved and open decisions:** D14 ratified in full 2026-08-23 ("Ratify all", R-a…R-g + clarifications; record in `REPORTS/ARCHIVE/GN_MODEL_DEBATE_2026-08-23/` — three Fable↔ChatGPT rounds + FINAL_JOINT_RECOMMENDATION.md). **D1–D13 remain open** (spec §16) — notably the Guardian-profile field set (blocks part of OA-ZYRA-246), monetisation surfaces beyond the entitlement gate, and Phase-2 alignment scope.

**Superseded models (do not build against these):**
- The 2026-08-22 first-draft preview ("Suggest"/"Pass" vocabulary, plan/scene preview enums) — retired; module archived (see §5).
- The Family Introduction Request chain WITHIN Guardian Network — superseded by contract Rule 43 (own-Seeker Suggest, Rule 20, is unchanged).
- `ZYRA_GUARDIAN_NETWORK_2026-08-22_V1.md` (SYSTEM/DOCUMENTS) — archived predecessor of the spec.
- `APP/Guardian Network/GUARDIAN_NETWORK_2026-08-22_V1.md` — the reconciliation draft that briefly carried CURRENT_VERSION in a second folder; archived 2026-08-23 with a supersession banner. **There is now exactly one current GN spec** (the SYSTEM/DOCUMENTS V2).
- Draft candidates v1–v12 (`SYSTEM/RESOURCES/OVERNIGHT_GN_2026-08-23/02_DRAFT_*.dart`) — history; v13 is live.

## 2 · IMPLEMENTATION — what exists in the app today

### 2.1 Live files (SHA-256 first 16, measured from the live working tree 2026-08-23)

| File | SHA-256[:16] | Role |
|---|---|---|
| `lib/screens/wali/wali_network_screen.dart` | `50ec05c3f4ffe2fc` | Network page (GN Draft 3.2 lineage) — Discover-only; responsive metadata Wrap fixes the measured narrow-screen overflow; production now resolves the governed four-state access matrix and removes price from the lock |
| `lib/screens/wali/wali_gn_shared.dart` | `2a3e51ae954de42c` | The GN library: GNContext + models + swipeable four-name selector + all-Seeker picker + Connections panel + sheets; reset clears selection, stages, scene, role and analytics |
| `lib/screens/wali/wali_dashboard_screen.dart` | `68e84cc605a4990d` | Dashboard hub + Seeker slider + CONNECTIONS section |
| `lib/screens/wali/wali_seekers_screen.dart` | `fbeba9203ca9287b` | Seekers tab (blank state → ZyraAddCircle) |
| `lib/widgets/zyra_state_widgets.dart` | `af43a5206d02caba` | + ZyraAddCircle (the picture-1 "+" blank-page invitation) |
| `lib/dev/zyra_dev_scenario.dart` | `b160603cc655351b` | Dev store — GN preview plan/scene state REMOVED (OA-ZYRA-251); deterministic linked-Seeker fixtures now reach 10 for selector stress testing |
| `lib/dev/wali_dev_scenario_panel.dart` | `a4e946353b8565a7` | Side panel — Network card exposes the D14 lab plus all four production access/dependency states without mutating entitlement or links |
| `lib/screens/wali/wali_home_shell.dart` | `8c9e1a8aa4200bd9` | IndexedStack navigation: Dashboard tab 0, Network tab 1; keeps shared surfaces mounted and hosts the Guardian calm-landing promotion surface |
| `test/guardian_network_preview_test.dart` | `d34cfbc0feaab876` | Current D14/GNContext/GNScene suite plus four-state production access coverage at 320/390px (9 tests) |

Other load-bearing files: `zyra_developer_access.dart` (the dev gate), `zyra_segmented_toggle.dart` (the slider control), `zyra_entitlement_service.dart` (Guardian+ resolver), `zyra_wali_link_service.dart` (WaliLinkedPerson) and `zyra_promotion_engine.dart` (developer-only access-state staging). Backups of every pre-change file live in `SYSTEM/RESOURCES/OVERNIGHT_GN_2026-08-23/` (03_/04_BACKUP_*).

### 2.2 Architecture and why

**GNContext (ChangeNotifier singleton, in wali_gn_shared.dart)** is the singular GN state: `selectedSeekerId` + `effectiveSelected(wards)` (falls back to the first ward — there is deliberately no "nothing selected" state), the mock `stageOf/setStage` map keyed `'{ward.id}/{family.id}'`, `scene`, `isMainWali`, `choosing`, `liveCount`, `incomingCount`, `servedFamily`, `advance()` (the 450ms algorithm-serve transition), `track()` (Rule 41 provisional analytics), `reset()`. WHY: the Founder's Draft 3 ruling requires Dashboard and Network to agree about the selected Seeker and every request's stage at all times; both pages stay mounted in the shell's IndexedStack, so one ChangeNotifier both pages listen to is the smallest mechanism that cannot drift. It is app-lifetime and never disposed, exactly like AppState.

**GNScene vs GNStage** — the two are different axes. `GNStage` is a FAMILY's position on the D14 ladder: none · setAside (Rule 19) · sent (Rung 1) · incoming (Rung 1, theirs) · connected (Rung 2) · proceedMine (Rung 3) · revealed (Rung 4) · closed ("No longer active", Rule 27). `GNScene` is a PAGE-LEVEL dev scenario: standard · merge (Rule 24 dedup card) · capReached · empty · loading · error. Scene is global (not per-Seeker) — a deliberate simplification, listed as debt in §6.

**Wards** come from one composition everywhere: `AppState.instance.waliRealLinkedSeekers`, topped up in debug/profile by `ZyraDevScenario.composeWaliWards` — the SAME list the Dashboard/Seekers pages draw, so GN can never act for a Seeker the rest of the app does not show. Mock families: `_gnFamiliesA/_gnFamiliesB` (in the GN library, per the Rule 44 amendment) chosen by ward-index parity — a placeholder serving rule, not a product rule.

**Shared Seeker selector (Founder follow-up, 2026-08-23):** `GNSeekerSlider` is the same widget on Dashboard and Network and is now directly horizontally draggable. Its frosted fill follows the finger and settling writes the singular `GNContext.selectedSeekerId`; Network additionally keeps its full-body `PageView` in sync through `onSelect`. To remain legible for large families it renders at most four names at once. When more exist, a compact `+N` chevron opens an accessible, scrollable all-Seeker sheet; picking any row writes the same GNContext and, on Network, moves the pager. This is presentation overflow only — it is NOT a four-Seeker product cap. The debug/profile fixture count now reaches ten so the exact case is testable from the existing Linked Seekers control.

**Navigation entry points:** WaliHomeShell tab 0 = Dashboard, tab 1 = Network (IndexedStack keeps all five pages alive; this is what makes cross-page state sync trivially correct). WaliProfileScreen holds an `onNavigateToNetwork` callback to tab 1 (the Guardian+ purchase path). There is deliberately NO GN deep navigation: the merge card reviews its incoming request in place via `showGNIncomingSheet`, and the cap card points to the Dashboard in words.

**Data flow (one action, end to end):** tap "Connect with this family" on the Dashboard's Incoming card → `GNContext.track('connected', familyId)` + `setStage(ward, family, GNStage.connected)` → `notifyListeners()` → both pages' `_onChange` → Dashboard CONNECTIONS section re-renders the family under CONNECTED, and the Network page's deck serves the next family. No service call exists anywhere in the flow — see §2.4.

### 2.3 Developer and testing controls

- **GN preview-control icon** (top-right of Network AND Dashboard, `!kReleaseMode` + developer gate) → `showGNDevSheet`: an icon-only sliders control with tooltip/semantics, replacing the visible `DEV` word; the sheet provides every GNScene, role Main/Additional (Rule 37 advisory view), reset, and the analytics-events viewer (`ctx.analytics`, newest 20).
- **WaliDevScenarioPanel** (side pull-out): composes wards ("Linked Seekers" count — still current, still real), Journey/review staging. Its retired GN plan/scene controls remain removed (OA-ZYRA-251); its Network card points to the D14 lab and separately stages Basic/no Seeker, Basic/linked, Guardian+/no Seeker and Guardian+/linked-unavailable production access states.
- **The dev gate:** `ZyraDeveloperAccess.canUseDeveloperTools` = authorised operator (Supabase app_metadata zyra_role) OR seeded @zyra.test account; hard-false in release. GN preview requires it; the Founder tests unplugged in PROFILE builds (`flutter run --profile`), which the gate and the contract's Rule 44 amendment both honour.
- **Listener discipline (OA-ZYRA-250):** listener ADDS may be gated, but REMOVES are ungated and `_onChange` is mounted-guarded in the network and dashboard screens — the account switcher can flip the dev gate between initState and dispose, and a leaked listener crashed the app (Founder's 2026-08-23 log). Follow this pattern in any new screen that listens to a singleton.

### 2.4 Mock vs production behaviour

- **Developer builds (debug/profile, gated):** the full D14 preview remains available and everything in that preview is PROVISIONAL mock data in the GN library. The side panel can instead stage each production access state for deterministic testing. No Supabase row is read or written by any GN action; analytics are in-memory only.
- **Release builds:** entitlement (`ZyraEntitlementService`) and accepted Seeker links resolve independently into four truthful states: (1) Basic/unlinked → Link a Seeker, no upsell; (2) Basic/linked → privacy-safe Guardian+ explanation, then See Guardian+ only after a tap; (3) Guardian+/unlinked → access active, Link a Seeker; (4) Guardian+/linked → Guardian Network not available yet, with no purchase-to-unlock claim. Price is absent from the lock. The Dashboard renders NO D14 GN content in release (`gnPreview` is false), and no mock family, stage or slider can appear.
- **Developer purchase preview:** any local Guardian+ activation path says no payment is taken and does not alter production entitlement truth.

## 3 · TESTING — measured current results

### 3.1 Before the current-architecture repair

`flutter test test/guardian_network_preview_test.dart` measured **0/4 passing**.
The suite asserted the retired pre-D14 preview model and exposed a **155-pixel
right RenderFlex overflow**. This is the measured reason the old test/control
model was retired, not an inferred cleanup.

### 3.2 After the repair

- `flutter test test/guardian_network_preview_test.dart` — **9/9 PASS**.
  Covers the D14 default/standard render, shared Seeker selection, explicit
  `GNScene.empty`, `error`, `capReached`, `merge` and `loading` branches
  (loading asserts `ZYRA is choosing the next family…`), local
  Set-aside/advance + analytics, complete `GNContext.reset()` isolation,
  icon-only preview control, direct slider drag, four-name legibility and
  selection of the tenth Seeker through the overflow sheet, the four-state
  production access matrix at 320×568 and 390×568, and the rule that the
  Guardian+ explanation appears only after a user tap. The first run of
  the new test measured a **145-pixel bottom overflow** in the default 800×600
  harness; the sheet height was then bounded to the available viewport and the
  final focused run passed with no overflow.
- `flutter test test/guardian_network_preview_test.dart test/journey_guardian_selection_test.dart test/wali_onboarding_gender_test.dart`
  — **22/22 PASS**: 9 GN current-architecture/access tests + 12 Journey Guardian
  selection/reveal/Salam tests + 1 Wali onboarding gender test.
- `flutter test` — **174/174 PASS** across the complete current repository
  suite.
- `flutter analyze` — **PASS, no issues**.
- Retired-reference sweep — **zero** `GuardianNetworkPreview`,
  `guardianNetworkPlan`, `guardianNetworkScene`, old plan-label or old
  page-state-label references in `lib/` and `test/`.
- `python3 tools/zyra_check.py` — exits **1** on three unrelated, pre-existing
  heuristic findings: two missing-member heuristics in
  `zyra_journey_service.dart` lines 1251–1252 and one unused-import heuristic
  in `journey_flow_screen.dart` line 60. Flutter analyzer is clean. These are
  outside Guardian Network and are not represented as GN failures.

### 3.3 Device verification still required

The Founder phone protocol remains: blank states on Dashboard/Network/Seekers;
drag the top selector on Dashboard; swipe the Network body; select Seeker ten
through `+N`; verify cross-page selection; open all preview scenes from both
icon-only controls; and repeat the OA-ZYRA-250 account-switch crash repro.
These observations are **PENDING — not measured in this repair pass**.
Automated results above do not substitute for the device observation.

The final profile build was measured on the connected wireless device: Xcode
completed in **31.8s**, then the app installed and launched successfully in
**305.1s** on Shakeel Ahmad's iPhone, iOS 26.6. The delay was traced to a stale
earlier Flutter deployment attached to the same bundle; only that stale
process was terminated, after which the final deployment completed. This
proves build/install/launch only; it does not claim the pending touch
interactions above were visually observed.

The measured 155-pixel overflow is fixed by the responsive `Wrap` in the
Guardian metadata row; the focused 430×932 widget test now passes.

## 4 · MIGRATIONS

**Current implementation/repair: none.** No migration was authored, applied or
authorised; no backend, production analytics or live Guardian Network process
was added. The feature remains a developer-only D14 mock plus the production
four-state access/dependency/availability shell; no live GN family process was
introduced.

Future mock-to-production work would require Founder-authorised migrations in
this dependency order:

In dependency order: (1) GN tables + RLS (families-in-network, requests, processes, closures — privacy-minimal history rows per Rule 30); (2) the serving algorithm (replaces ward-index parity + in-file families; enforces eligibility recheck at the five Rule 35 checkpoints server-side); (3) per-guardian entitlement (Rule 38 — hasWaliOne covers the Main Wali only; Additional Guardians need their own Guardian+; pricing wording mirrors into ZYRA_PRICING at next bump); (4) the analytics pipeline (Rule 41 — replace the in-memory tracker; 13 event names are already final); (5) calm-delivery notifications (badge + ≤1 daily digest, zero Seeker identifiers); (6) photo-consent storage (three levels, prospective, per Rule 34); (7) timers (14-day expiry, 90-day/6-month cooldowns — server-side, Wali-switch-proof); (8) GNContext then becomes the client cache of server state — its API was shaped so screens should not need to change.

## 5 · REMAINING WORK, BUGS, DEBT

**Open register items:** OA-ZYRA-246 (current reconciliation: verified badge,
compatibility band and profile sheet now exist; availability remains absent;
the served card still lacks the build-contract `Save` and own-Seeker `Suggest`
actions; pricing/Guardian-profile decisions remain open) · OA-ZYRA-247/248
(Founder phone test/closure) · OA-ZYRA-249 (tablet strategy decision) ·
OA-ZYRA-250 (account-switch device repro). OA-ZYRA-251/252 are completed by
the current-architecture repair, measured tests and this reconciled handover.

**Technical debt, in honesty order:** focused current-architecture coverage now
proves the four-state release access shell, but cannot prove server persistence
or a live production GN process because neither exists yet; `GNScene` is
global, not per-Seeker; mock families use ward index parity; photo placeholder
uses an empty profile-image value; analytics are in-memory;
`wali_home_shell.dart` still has the gated-remove pattern (mounted guard makes
it a benign leak risk; tracked in OA-ZYRA-250's sweep);
`dev/wali_dashboard_preview.dart` is a separate non-GN preview and was not
audited here.

**Next implementation steps:** Founder phone-tests the current build → close
247/248/250 on measured device evidence → D1–D13 ratification round (spec §16)
→ Codex Phase-2 alignment against the contract + this handover → seek explicit
Founder authorisation before any migration/backend work.

## 6 · CONCURRENCY NOTE (2026-08-23)

Two concurrency events are preserved. First, the retired preview cleanup was
performed in parallel; the module was removed from SOURCE and archived, while
the test was subsequently rebuilt against current D14/GNContext architecture.
Second, two handover standards were drafted concurrently. The duplicate
`IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md` is explicitly superseded; the ONE
authority is `IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md`. No OA
identifier collision occurred: the live registers were re-read and existing
OA-AIOS-363/OA-ZYRA-251/252 entries were updated instead of appended again.

## 7 · 2026-08-26 account-link invitation and surface amendment

`WaliDashboardScreen` now hosts the role-aware **account-link invitation**
module. This is not a Guardian Network family-connection request and does not
change GNContext/GNScene/GNStage product rules. The separation is:

- account link: Guardian ↔ Seeker identity relationship, existing
  `wali_invites` bearer code and `ZyraWaliLinkService`;
- Guardian Network: family-to-family discovery/connection, still governed by
  the GN specification and current D14/mock boundary.

Ongoing account-link invitation status and code review now live on Dashboard;
invite-generation screens create a new code but no longer duplicate their
outstanding lists. The current schema cannot query an addressed recipient, so
named received rows remain labelled developer preview.

Wali/Guardian cards, sheets, pills, selector chrome, dialogs and profile/Seeker
surfaces now consume the shared global App Surface tokens while retaining GN
gold and destructive/status semantics. Current Wali Dashboard SHA-256:
`2ecc207868d9898a18347bb8b0a2f75d27ca4e4311ecbfe8273eee711c287e28`.
Current GN shared-library SHA-256:
`598837682cafeb07d6ec461cad88cb9c18afbb7b443ccf5a669c8a4cd675005a`.

The 2026-08-26 complete Flutter suite passed 474/474; direct visual fixtures
passed 190/190; `flutter analyze` and `python3 tools/zyra_check.py` are clean.
No GN or account-link migration was created or applied in this amendment.

## 8 · 2026-09-19 Founder-selected Rung 0 presentation amendment

The Founder selected Guardian Network card design Option 1 for the developer
preview. This is a presentation and action-label amendment only; the D14 state
ladder, privacy boundary, access states and mock-versus-production boundary are
unchanged.

The served-family surface now fills the available Network viewport with one
full-bleed family-photo card and no explanatory header/footer or unused lower
space. It removes `Chosen for`, the one-family explanatory line, compatibility
band/reasons, age, region and provisional-data copy from Rung 0. The Guardian
identity is rendered as `Main Guardian · Relationship`. The Network header no
longer exposes the top-right preview-control icon.

The visible Rung 0 actions are now:

- `Next` — retains the existing internal `GNStage.setAside` progression and
  advances to the next served family without feedback copy;
- `View profile` — opens a privacy-bounded photo viewer containing only the
  Seeker photo made available to Guardians in this preview; and
- `Speak to Guardian` — opens a concise Main-Guardian request confirmation and
  retains the existing `GNStage.sent` transition.

No live photo source, service call, backend process or migration was introduced.
The photo surface remains a deterministic placeholder because the current mock
`GNFamily` model does not carry production photo URLs. Release behaviour remains
the governed unavailable/access shell described in §2.4.

Measured verification for this amendment:

- `flutter test test/guardian_network_preview_test.dart` — **11/11 PASS**;
- `flutter analyze` — **PASS, no issues**;
- complete `flutter test` — **1680 passed, 1 skipped, 126 failed** from unrelated
  pre-existing repository failures; none of the focused Guardian Network tests
  failed; and
- `python3 tools/zyra_check.py` — exits 1 on four unrelated existing findings in
  `main.dart` and `zyra_guardian_capacity.dart`; no Guardian Network finding.

Current amendment SHA-256 values:

- `wali_network_screen.dart`:
  `1acd7cdd934c1470151846779e917d4362d6a588ea5adefade07d0803d018e5e`;
- `wali_gn_shared.dart`:
  `3ae24619d8590172aea446b7ba0379965e65042754b9e9223a16c70330486b39`;
- `guardian_network_preview_test.dart`:
  `2d1380c49a1cef848bf45a668a8f1260d8e8ae192674b1b6716b9ecffae3c31e`.

OA-ZYRA-247/248 remain the existing device-test and reconciliation owners for
this developer-preview work. Phone visual/touch verification of the selected
layout remains pending; no new OA identifier was created.

## 9 · 2026-09-19 borderless page and current action-colour amendment

Following direct Founder review of Option 1 in-app, the served-family surface
no longer uses an outer border, rounded card shell or inset card margins. The
photo/gradient surface now fills the complete Discover area below the shared
Seeker selector and continues behind the floating navigation, while the action
cluster remains raised above that navigation for touch access. This makes the
screen read as one continuous page rather than a bordered card.

The served-card actions are now borderless. `Next` and `View profile` use quiet
neutral ZYRA glass; `Speak to Guardian` no longer uses the retired pink primary
fill and instead uses a restrained Guardian-Network gold tint and gold text.
The Guardian shield also loses its outline. Other Guardian Network surfaces
retain their existing action semantics and colours.

Measured verification for this amendment:

- `flutter test test/guardian_network_preview_test.dart` — **11/11 PASS**;
- `flutter analyze` — **PASS, no issues**; and
- the focused render test now asserts the full-bleed `Stack`, the non-primary
  gold-accent Speak action and its borderless state.

Current amendment SHA-256 values:

- `wali_network_screen.dart`:
  `612083752f590551e5966f95861d4b1a31e23728aedac1e34521e2551c526eaa`;
- `wali_gn_shared.dart`:
  `3c53260e319e22c226e8fe0628be50934d487fea0142e1d8e0e90720e0a8c80a`;
- `guardian_network_preview_test.dart`:
  `efbc13ad3f58023ed282ed7fa0b755886d53a5e615b5f3042289b3af54a51d61`.

No backend, production-photo integration or migration was added. Phone visual
review remains the next evidence step under OA-ZYRA-247/248.

## 10 · 2026-09-20 photo-led identity and spacing amendment

Following direct Founder review on-device, the Browser card now makes the
person—not ZYRA's internal selection reasoning—the dominant visual. The former
`HIGH FIT` badge and `Practising` / `Nearby region` / `High compatibility`
chips have been removed from the discovery card so the surface does not expose
or market the private logic ZYRA uses to choose a suitable family.

The available vertical area now expands one large portrait surface. Name/age
display and region sit over a bottom photo scrim, matching the Browse-first
identity hierarchy and reducing the need to open `View profile` merely to see
the person. The complete portrait surface is also a direct, accessible profile
action. The mock `GNFamily` model now accepts the permitted photo set: its
first photo fills the card and the full set passes into the existing swipeable
Browser-style viewer. An empty developer fixture retains the privacy-safe
full-frame initial placeholder, while future authoritative permitted photos
can render without a second card redesign.

The Guardian relationship remains visible but is now a simple unboxed row with
shield, `Main Guardian · Relationship` and verification status. `View profile`
and `Speak to Guardian` remain equal-width actions and `Next` remains below
them. Fixed, even gaps replace `spaceBetween`, preventing the previous tight
top grouping and loose lower gap.

The empty `Sent requests` and `Received` modes now use the shared borderless
ZYRA empty-state treatment: centred icon, title and supporting text only. The
former glass notice card is retained for genuine authority notices such as an
Additional Guardian being told that the Main Guardian handles requests; it is
no longer used merely because a request list is empty.

Measured verification:

- `flutter analyze` — **PASS, no issues**;
- `flutter test test/guardian_network_preview_test.dart` — **14/14 PASS**;
- the focused test now proves the internal-fit/reason copy is absent and the
  photo-led area occupies more than 250 logical pixels at 430×932; and
- no migration, service call, production entitlement or Guardian Network state
  rule changed.

Current amendment SHA-256 values:

- `wali_network_screen.dart`:
  `4b4671367f3bd4fbcb3ebe9775f590d114bb8a980c220b542d7229b300e92890`;
- `wali_gn_shared.dart`:
  `94a1a2a84e52549c6742f1881c2259cb68749877f26134e5fab81e717897f146`;
- `guardian_network_preview_test.dart`:
  `1005bdd9df56155920f8b91dc780cdfe22c34f450fdcf0f75e851783ccea43e0`.

OA-ZYRA-266 now owns the future website verification claim and OA-ZYRA-300
owns the source-verified Imam Ahad quotation placement. Neither item was
published by this app-card change.

— END OF HANDOVER — verify the latest amendment SHAs before trusting any statement above; if a SHA differs, the code has moved past this document: update it or file the gap. —
