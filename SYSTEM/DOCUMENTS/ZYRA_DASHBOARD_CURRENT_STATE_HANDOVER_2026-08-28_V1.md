# ZYRA Dashboard — Current-State Handover

> **SUPERSEDED 2026-08-29 (point-in-time snapshot).** This document describes
> the pre-Home renderer as it stood 2026-08-28 and was the input to the
> Founder/ChatGPT direction round. The Seeker Dashboard has since been rebuilt
> as the six-level conditional Home (DR-ZYRA-217; MESSAGES/011 GO; MESSAGES/012
> completion; Fable-verified 2026-08-29). Current as-built truth:
> `ZYRA_SEEKER_DASHBOARD_HANDOVER_CURRENT_VERSION_V1.md` §13. Do not use this
> file as current renderer truth.


**Document:** `ZYRA_DASHBOARD_CURRENT_STATE_HANDOVER_2026-08-28_V1.md`
**Status:** CURRENT-STATE SNAPSHOT — facts only; no proposals in §1–§15. Prepared for the Founder's KEEP / CHANGE / REMOVE / ADD / REORDER / BASIC / ZYRA ONE review with ChatGPT.
**Author:** Fable, 2026-08-28
**Evidence freshness (Addendum A3):** every code fact below was read from the live tree on **2026-08-28** (newest relevant file: `seeker_dashboard_screen.dart`, 16:14 local; Codex's OA-ZYRA-264 amendment landed today and IS reflected). The five supporting as-built documents' SHA-256 hashes from message 010 were re-verified against disk today: **5/5 match**. Code-level hash verification of the OA-ZYRA-264 file table is a separate pending Fable step and is not claimed here.
**One sentence of orientation, because it changes how you read everything:** the Seeker Dashboard was REBUILT TODAY (OA-ZYRA-264, DR-ZYRA-216) from a hub of link-cards into a resolver-driven page — Answer → Your Journey → Other Actions → Worth Knowing. Founder device acceptance of that rebuild is still PENDING.

---

## 1 · Seeker Dashboard — current production state (screen order)

Visible to a normal release user. Background is the gender gradient (the only male/female difference on this page). Pull-down anywhere refreshes all sources. Landing: Dashboard is the default signed-in tab (index 2; Browse · Connections · Dashboard · Guardian · Profile).

| Order | Element | What it shows / data | Appears when | Plan | Action → destination | Status |
|---|---|---|---|---|---|---|
| 1 | Header: "Dashboard" + greeting | "Assalamu alaikum, {first name}." or "Your ZYRA, in one place." if no name | Always | Both | Not clickable | Live |
| 2 | Notification utility (top-right circle + badge) | Bell icon; badge = real unread count, "99+" cap | Always; badge only when unread > 0 | Both | Opens the full Notifications manager (pushed route, back arrow; shell refreshes unread on return) | Live |
| 3 | **THE ANSWER** (one prominent card) | The single highest-ranked item, chosen by the pure resolver — see ranking below | Always (one of four forms) | Both | Per signal (below) | Live, Founder acceptance pending |
| 3a | — Answer: signal form | Eyebrow by kind (DECISION DUE / NEEDS YOUR ATTENTION / READY FOR YOUR DECISION / YOUR NEXT STEP / WHAT CHANGED / INSIGHT FOR YOU), title, detail, action label | When any obligation/movement exists | Both | Signal's target (see §6) | Live |
| 3b | — Answer: calm form | "ALL SETTLED · Nothing needs you right now" or "READY FOR INTRODUCTIONS · New introductions will appear here when they are available." | Only when every action-bearing source loaded successfully AND no obligation exists | Both | Not clickable | Live |
| 3c | — Answer: loading form | "UPDATING YOUR ZYRA · Checking what is ready for you" | While sources load | Both | Not clickable | Live |
| 3d | — Answer: refresh-required form | "COULD NOT REFRESH EVERYTHING · Some of your Dashboard is unavailable" + Retry | When an action-bearing source failed and no known obligation outranks it — calm is PROHIBITED under partial failure | Both | Retry reloads all sources | Live |
| 4 | **YOUR JOURNEY** (label + one card) | Always exactly one Journey summary — see §8 for the five kinds, stage x-of-8 and progress bar | Always (loading/unavailable variants have Retry) | Both | Searching → Discovery (tab 0); every other kind → Connections/Journeys (tab 1) | Live |
| 5 | **OTHER ACTIONS** (group) | Every remaining obligation, compact rows; 2 shown, then "N more actions" disclosure row expands in place; never mixed with Worth Knowing; never deleted by the cap | Only when a second+ obligation exists | Both | Per signal | Live |
| 6 | **WORTH KNOWING** (list) | Ranked non-obligations, hard cap 3 | Only when at least one exists | Both | Per signal | Live |
| 7 | Guardian-invitation module (special render) | When the top invitation signal surfaces, it renders as the real invitation module (sent/pending rows, expiry countdown, Cancel) instead of a plain card | Only with real pending sent invitations | Both | Cancel = live `revokeInvite` RPC; row → Guardian tab | Live |

**What produces the signals (adapter, all real server reads, started in parallel — no AppState pre-hydration assumed):** onboarding progress → one BLOCKING GATE card when incomplete ("Continue your profile" / "{answered} of {due} answers saved", detail "Your profile stays hidden and Journeys remain locked until setup is complete.", action Continue setup → onboarding resume); Journey rows (potential/active/ended incl. paused flag); unread notifications → WHAT CHANGED rows (title/body, Review update → manager); pending sent Guardian invitations → one summary signal (count + earliest expiry "Expires today"/"N days left") → Guardian tab; Guardian activity → rows for `suggested` / `review_answered` / `review_waiting` with privacy-safe fixed wording (`linked` rows are deliberately NOT dashboard movement — stable relationship state stays on the Guardian page); insights → **honest empty** (see §9).

**Resolver ranking (deterministic):** deadline decision (by due time) → blocking gate → decision without deadline → your own Journey move → meaningful movement → governed insight → calm; ties break class → due → event time → stable ID; passive viewing NEVER demotes an obligation; hero doesn't reshuffle without material change.

Removed from production today (existed until this morning): the Connections card, the Guardian card, the generic Notifications card, and the line "Your Journeys, Guardian and updates are all here." None survive in the live renderer.

## 2 · Guardian (Wali) Dashboard — current production state (screen order)

Built 2026-08-15 as a hub (DR-ZYRA-171); NOT rebuilt onto the resolver — it keeps its own role-specific reads. Background gender gradient. Release users see items marked [release]; several sections are developer-preview only.

| Order | Element | What it shows / data | Appears when | Action → destination | Status |
|---|---|---|---|---|---|
| 1 | Header "Dashboard" + greeting | Wali first name greeting | Always [release] | — | Live |
| 1a | GN dev chip (top-right) | Guardian Network dev scene control | Developer builds only | Opens GN dev sheet | Dev-only |
| 2 | GN Seeker slider | One segment per linked Seeker; selection SHARED with Network page via GNContext | Dev preview only, ≥1 Seeker | Selects Seeker here and on Network page | Dev-only until GN goes live (contract Rule 44) |
| 3 | Loading spinner | — | While first fetch runs (loading checked before empty, DR-ZYRA-166) | — | Live |
| 4 | Full-page error state | "Couldn't load your dashboard · Check your connection" + Try again | Fetch failed AND nothing cached | Retry | Live |
| 5 | Empty state | Guardian-audience invitation module + centred big "+" — "Invite your Seeker" (GN Draft 3.2 pattern: no bar, no paragraph) | No linked Seekers | + → WaliInviteSeekerScreen | Live |
| 6 | Stale banner | "Couldn't refresh — showing what was loaded." + Try again | Refresh failed but rows exist (stale beats blank, DR-ZYRA-167) | Retry | Live |
| 7 | GN Connections panel | Selected Seeker's Guardian Network context (moved in from the Network page, Founder 2026-08-23) | Dev preview only | GN interactions | Dev-only |
| 8 | Guardian-audience invitation module | Sent/pending invite state and actions | Always in list view [release] | Cancel invite = live RPC | Live |
| 9 | **NEEDS YOUR ATTENTION** | Family Review cards ("Both families decide… Your decision is waiting." → Review) then Guardian Gate cards ("waiting at the Guardian Gate… Only a Guardian can complete this step." → Open); else the honest line "Nothing needs you right now." | Always (absence is stated, never implied) [release] | Card → WaliJourneyDetailScreen | Live |
| 10 | **YOUR SEEKERS** — one ZyraWardCard per ward | Photo (real read), name, "You are their Main Guardian"/"Additional Guardian", status line ("Journey with {name} — {canonical stage / Journey paused / Journey awaiting a decision / Journey ended}" or "No Journey yet"), 8-stage rail for active Journeys, chips: Active/Paused/Ended (real counts) + Saved/Considering/Declined (**STAGED dev-only** — no Guardian RLS read path for Browse activity exists; owner-only tables) | Always [release] | Card → Journey detail (only when a live Journey exists) | Live; Browse chips honest-staged |
| 11 | **RECENTLY** | Latest Timeline milestone per live Journey (≤4), friendly labels ("Faith & Values complete", "Salam exchanged", "Journey paused"…), relative time | When any live Journey has milestones [release] | Row → Journey detail | Live |

**Multi-Seeker:** every linked Seeker gets a card; the GN slider (dev) selects one for the GN panel. **Additional Guardians see no Journey rows** — DR-ZYRA-168 ruled full Main-equal visibility as the target, shipping as its own coordinated batch (RLS + RPC + guard-suite); the screen deliberately doesn't preempt it. **Pause states:** "Journey awaiting a decision" (pending shared-pause negotiation) and "Journey paused" render from neutral state — no actor is ever shown. **ZYRA One promotion:** none on this screen (Guardian+ promotion lives on the Network page, not the Dashboard). **AI:** none.

## 3 · Layout structure

**Seeker:** fixed header (title/greeting/notification utility) above one scrollable ListView — Answer (top priority, alone) → Your Journey (always) → Other Actions (conditional group) → Worth Knowing (conditional). Nothing reorders dynamically except the resolver's own ranking; nothing collapses except the "N more actions" disclosure (expands; re-collapses only when the action set changes). Pull-to-refresh. Bottom padding clears the floating nav.

**Guardian:** fixed header (+ dev GN slider) above one scrollable ListView — attention first, then people, then recency: [dev GN panel] → invitations → NEEDS YOUR ATTENTION → YOUR SEEKERS → RECENTLY. No collapsible sections; no dynamic reordering; empty state replaces the whole list.

## 4 · Dashboard design options (the Lab)

Developer-only, session-only selector; both role renderers switch together; **as of today all five consume the same `DashboardResolution` contract as production** (mock snapshot in, same resolution out). Default/reset = **Now / Journey / You**.

1. **Now / Journey / You** — attention first, current Journey second, personal context third (reset state).
2. **ZYRA Compass** — one daily focus, compact status board, supporting insight.
3. **Journey Lens** — Journey state (active/potential/paused/searching) is the centre.
4. **Living Priorities** — one primary + two secondary priorities, progressive disclosure.
5. **Progress Story** — where you are, what moved, what comes next.

**Deprecated:** the earlier six-concept generation (Journey Command Centre, Modular Personal Hub, Layered Story, Interactive Canvas, Calm Daily Overview, Sectioned Status) is retired; its render captures are archived at `SYSTEM/RESOURCES/UI_GATE/ARCHIVE/RETIRED_DASHBOARD_MODELS_2026-08-25/` (30 PNGs). "Sectioned Status" as a current name is stale anywhere it still appears (reconciled 2026-08-28). **The production Dashboard is NOT one of the five** — it is the separate resolver renderer; no Lab concept has been promoted.

## 5 · App Surface designs (three options)

Global, device-local, developer-only selector under the dev **Home** door — NOT a Dashboard-specific control, and there is no member-facing preference.

1. **Classic Glass** — existing glassFill/glassBorder tokens + one restrained lavender actionFill accent. **Current app-wide default; the only surface release users ever get.**
2. **Glass Signals** — neutral Classic Glass surfaces, meaningful colour kept for icons/progress signals.
3. **Status Accents** — stronger semantic colour on status surfaces and active highlights.

Selection rebuilds shared theme-token readers **app-wide** (Dashboard, Browse, Connections, Guardian, Profile all read the same tokens) and both Dashboard mock configs; it persists on-device across relaunch; sign-out/shared reset restores Classic Glass. No page is documented as missing the surface application; Founder device confirmation of that claim is part of the pending acceptance pass. The ZYRA wordmark is locked (Syne) regardless of surface.

## 6 · Interaction map (production)

**Seeker Dashboard:** notification utility → Notifications manager (push; unread refreshes on return) · onboarding gate card → resume onboarding flow · Journey card: searching → Browse/Discovery (tab 0); potential/active/paused/ended → Connections → Journeys section (tab 1) · notification signals → Notifications manager · invitation signal/module → Guardian tab (tab 3); Cancel = live revoke RPC in place · guardian-activity rows → Guardian tab · "N more actions" → expands in place (state only) · calm/loading cards → no-op by design · Retry (refresh-required / journey-unavailable) → reload.
**Flags:** duplicate destination BY DESIGN twice (notification signals + utility both → manager; invitation signal + activity rows both → Guardian tab). No broken links, wrong destinations, placeholder or mock behaviours found — the routing test suite covers every destination (part of today's 119/119). Deep-link/auth guards are explicitly OUTSIDE the rebuilt slice (unchanged from before). Back-navigation: manager and Journey detail are ordinary pushes with back arrows.

**Guardian Dashboard:** attention cards → Journey detail · ward card → Journey detail (only with a live Journey; otherwise not clickable) · RECENTLY rows → Journey detail · empty-state + → Invite Seeker screen · invitation module Cancel → live RPC · stale banner Try again → reload. Dev-only: GN chip/slider/panel per GN contract. No broken or placeholder interactions found; the one deliberate no-op is a ward card with no live Journey.

## 7 · Guardian invitations — exactly what exists now

- **Sent/pending (real):** listed on BOTH dashboards via the shared module (Seeker audience / Guardian audience), from the live `fetchPendingInvites` read: created date, expiry countdown ("Expires today" / "N days left"), **Cancel = real `revokeInvite(token)` RPC**. A failed refresh keeps last-known rows and offers Retry — failure is never painted as "no invitations"; only a later successful empty removes rows. The module collapses when no status exists.
- **Received (accept/decline):** the schema is a **bearer-code flow** — `wali_invites` has no recipient address, so nobody can be shown a named received invitation before entering the code. The real accept route lives behind the Guardian page's top-right **+** → LinkGuardianScreen → AcceptWaliInviteScreen (enter/review/accept code). Named received rows exist **only as developer preview**, labelled as such. Decline-by-recipient: not a schema concept (a code simply isn't used; sender may cancel; codes expire).
- **Duplication:** invitation STATUS/actions were moved OFF the Seeker Guardian page into the Dashboard module on 2026-08-26; a dedicated test guards against the page re-duplicating them. Linked-Guardian detail and add/link stay on the Guardian page.
- **After action:** the service fires invitation/link revision notifiers; the Seeker Dashboard listens and reloads automatically.

## 8 · Journey content on the Dashboards

**Seeker (Tier 2 is always present):** exactly one summary — ACTIVE: "You & {first name}", canonical stage label + "Stage N of 8", progress bar, Open Journey; PAUSED: "Paused · {stage}", Review Journey; POTENTIAL: "{n} Potential Journeys · Review each possibility at your own pace", Review Potentials; ENDED (latest, only when nothing live): "Your Journey with {name} · This Journey has ended", View Journey; SEARCHING: "Ready for introductions" (or "Preparing your profile" when onboarding incomplete), Open Discovery. Journey obligations (e.g. a decision) additionally surface as Answer/Other-Action signals from notifications. **The Dashboard does NOT know:** whose move it is (excluded until the shared-pause migration is separately authorised — OA-ZYRA-261), stage-level decision detail, or any deadline (none ratified).

**Guardian:** per-ward status line using canonical stage names only ('Phase N' never shown), the 8-stage rail on active Journeys, real Active/Paused/Ended counts, "Journey awaiting a decision" for pending pause negotiations (neutral, actor-free), Family Review and Guardian Gate attention cards (the two things that genuinely wait on a Guardian), and RECENTLY milestones. **Does NOT know:** ward Browse activity (no RLS read path — chips are dev-staged), anything for Additional Guardians (DR-ZYRA-168 batch pending), pause actors (by design).

## 9 · ZYRA learning / AI — what ACTUALLY exists

| Name | What it does today | Real or mock | Deterministic/LLM | Affects recommendations | Stores learning |
|---|---|---|---|---|---|
| Production insights source | Adapter emits an **honest successful empty list** — the INSIGHT FOR YOU eyebrow exists in the renderer but can never fire in production | Real code, empty by design (OA-ZYRA-259 P1) | Deterministic | No | No |
| Lab insight mock states | Developer-only insight cards incl. positive/neutral/insufficient-data/preference-review and a Basic-vs-One depth mock | Mock, dev-gated | Deterministic fixtures | No | No |
| Everything else AI | **Does not exist in the app** | — | — | — | — |

**Idea/documentation only (NOT implemented):** the entire learning system — `ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md` (rules DRAFT: evidence tiers, safe wording, confirm-before-apply, Basic 1 / One 3 depth) awaiting Founder ratification + an Article 9 solicitor gate. The P1 data audit's verdict stands: current tables hold latest-state, not behavioural history; all onboarding rows are synthetic; **production learning cannot be switched on honestly from the present schema.** Unfinished backend work = the whole aggregation layer (P2+), deliberately unbuilt.

## 10 · Basic vs ZYRA One — current Dashboard difference

| Dashboard feature | Basic | ZYRA One | Implemented? | Documented? |
|---|---|---|---|---|
| Any Seeker Dashboard difference | identical | identical | **NO difference exists** | Learning Loop V1 documents a future 1-vs-3 insight split (draft) |
| Any Guardian Dashboard difference | identical | identical | **NO difference exists** | Guardian+ features are documented/gated on the **Network page**, not the Dashboard |
| Plan reads available to gate anything | — | — | Only `hasWaliOne()` exists (used by wali home shell/profile/network/session router — NOT by either Dashboard); **no Seeker plan read exists at all** | Pricing V2 documents the plans |
| Lab mock Basic/One insight depth | mock | mock | Dev-only mock | Matches Learning Loop V1 intent |

**Flagged contradiction (not resolved here, per instruction):** documentation describes plan-differentiated Dashboard intelligence; implementation has zero plan awareness on either Dashboard and no Seeker entitlement read anywhere in the client.

## 11 · Empty / loading / error states — what the user sees today

**Seeker:** loading → "Checking what is ready for you" + Journey "Refreshing your Journey" · any action-bearing source failed → "COULD NOT REFRESH EVERYTHING… Try again before relying on what needs your attention" + Retry (calm suppressed) · Journey source failed → "Journey status could not be refreshed" + Retry · no Journey + onboarding complete → READY FOR INTRODUCTIONS calm + searching card · onboarding incomplete → the gate card IS the answer (page is never "quiet") · no insights → nothing (no placeholder) · no actions → sections simply absent · all well → ALL SETTLED calm. No offline-specific state beyond the failure states.

**Guardian:** first-load spinner → full-page connection error + Try again (nothing cached) → stale-rows banner (something cached) · no Seekers → invitation module + big "+" ("Invite your Seeker") · Seekers but no Journeys → cards say "No Journey yet", attention says "Nothing needs you right now.", RECENTLY absent · multiple Seekers → one card each (+ dev GN slider). Invitation module in both roles: unavailable ≠ empty, Retry, last-known preserved.

## 12 · Developer toggles (Dashboard-related)

All live behind `ZyraDeveloperAccess`/non-release; one shared `ZyraDevScenario` ChangeNotifier is the single mutable owner (state, not presentation-only — the real Lab/GN/ward readers consume it). Four-door rail (keys `dev_rail_preview/actions/home/style`) reaches every page.

| Toggle | Door/page | Values | Creates | Mutates real test state? | Reset |
|---|---|---|---|---|---|
| Dashboard Lab enable + layout | Actions (Dashboard) | off · 5 concepts | Swaps both role renderers to the chosen mock concept | Yes (scenario) | Reset → Now/Journey/You |
| Dashboard scenario fixtures A–H | Actions (Dashboard) | 8 staged states | Typed mock snapshots through the real resolver (incl. calm, failure, insight states) | Yes | Yes |
| App Surface | Home | Classic Glass · Glass Signals · Status Accents | Rebuilds app-wide surface tokens; device-persisted | Tokens only (presentation) | Sign-out/shared reset → Classic Glass |
| Guardian ward composition | Actions (Guardian) | real + stand-in wards, counts | Composes YOUR SEEKERS list (real rows first, 0 = zero) | Yes | Yes |
| Guardian journey composition + staged review | Actions (Guardian) | journeys per ward, one staged open review | Composes Journey rows/attention | Yes | Yes |
| Ward Browse chips | Actions (Guardian) | Saved/Considering/Declined counts | Staged-only chips (see §2.10 honesty note) | Yes (staged counts) | Yes |
| Active Journey count (Connections) | Actions (Connections) | count | Staged Active Journeys (the post-Pause-handover addition) | Yes | Yes |
| Pause scenario (13 states) | Actions (Journey/Connections) | 13 states × plan axis | Drives real pause readers | Yes | Reset → Active, version 0 |
| GN scenes/chip/slider | GN sheet | GN scenes | Guardian Network preview states | Yes | Yes |
| Account/plan switcher | Home | dev accounts; wali plan mock | Signs into seeded accounts; `mockSetWaliPlan` flips Guardian+ (Network page, not Dashboard) | Yes | — |
| Page Preview | Preview | read-only inventory | Deterministic page previews incl. Dashboard states | No (read-only) | — |

Release builds: none of the above exists; the four-door host returns nothing.

## 13 · Known issues / unfinished work (existing OAs only)

1. **Founder acceptance of today's rebuilt Seeker Dashboard + Guardian Pulse is pending** — copy, hierarchy, device feel (OA-ZYRA-264; also my code-hash/document verification pass and Claude's architecture review).
2. **Visual baselines: zero approved** — the gate runs BASELINE-PENDING everywhere (OA-ZYRA-257).
3. **Production learning inactive; insights slot always empty** (OA-ZYRA-259; Article 9 solicitor gate additionally blocks faith-derived families).
4. **Pause "whose move" absent from both Dashboards** until the staged migration is authorised/applied/probed (OA-ZYRA-261 — also the three deadline decisions).
5. **Additional Guardians see no Journey rows** — ruled, batch pending (DR-ZYRA-168).
6. **Ward Browse-activity chips are dev-staged only** — a real Guardian read is an open privacy/RLS decision raised with the hub build (register entry from DR-ZYRA-171 round).
7. **Named received invitations impossible pre-code-entry** under the bearer-code schema; preview-only rows exist in dev (Seeker Dashboard handover §9.4; no migration authorised).
8. **Live Guardian activity is effectively `linked`-rows only today** (0 suggestions / 0 review responses / 0 open reviews live) — and `linked` is deliberately not Dashboard movement, so the Guardian-activity signal lane is correct but empty in practice.
9. **Guardian page gaps recorded, not fixed:** no verified badge (written refusal — nothing to verify against), Guardians have no photos, pending invitation has no name (same bearer-code limit) — Guardian Page Review V1.
10. **Four sibling Guardian page designs + five Lab concepts await Founder selection/cleanup** — until then they are permanent-looking developer comparisons (cleanup path documented in both handovers).
11. **Basic/One Dashboard difference: none implemented** while documentation describes one (§10 contradiction — a decision, not a defect).

## 14 · Files and source of truth

**Canonical production code (Seeker):** `lib/models/zyra_dashboard_resolution.dart` (contract + pure resolver) · `lib/services/zyra_dashboard_adapter.dart` (live reads → snapshot) · `lib/screens/home/seeker_dashboard_screen.dart` (host, Lab guard, routing) · `lib/widgets/zyra_resolved_dashboard.dart` (the single renderer) · `lib/widgets/zyra_guardian_invitation_dashboard.dart` (invitation module) · `lib/screens/home/home_shell.dart` (tabs, callbacks, unread) · `lib/services/zyra_session_router.dart` (landing).
**Canonical production code (Guardian):** `lib/screens/wali/wali_dashboard_screen.dart` (hub) · `lib/widgets/zyra_ward_card.dart` · `lib/services/zyra_wali_journey_service.dart` · `lib/services/zyra_wali_link_service.dart` (typed truth results) · `lib/screens/wali/wali_journey_detail_screen.dart` · Seeker-side Guardian page: `lib/screens/wali/seeker_wali_tab.dart` + `lib/screens/wali/seeker_guardian_designs.dart` (Guardian Pulse = production base).
**Entitlements:** `lib/data/zyra_entitlements.dart` (caps matrix) · `lib/services/zyra_entitlement_service.dart` (`hasWaliOne` only).
**Experimental (dev-gated):** `lib/models/zyra_dashboard_lab.dart` · `lib/widgets/zyra_dashboard_experience.dart` (5 concepts) · `lib/dev/zyra_dev_scenario.dart` · `lib/dev/dev_scenario_panel_v2.dart` · `lib/dev/zyra_dashboard_lab_controls.dart` · GN files (`wali_gn_shared.dart` etc., Rule-44 gated) · 4 sibling Guardian designs inside `seeker_guardian_designs.dart`.
**Deprecated/archived:** the six-concept Lab generation (archive PNGs listed in §15); the pre-resolver hub cards (git history + superseded sections of the handover).
**Governing documents (all verified current today):** `ZYRA_SEEKER_DASHBOARD_HANDOVER_CURRENT_VERSION_V1.md` (§12 = today's truth) · `ZYRA_GUARDIAN_PAGE_REVIEW_CURRENT_VERSION_V1.md` · `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V5.md` (§10G) · `ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` · `APP/Navigation/SEEKER NAVIGATION/Summary.md` (product navigation truth) · DR-ZYRA-216 + MESSAGES/007–010 (the architecture agreement trail) · `ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md` + data audit (AI rules, draft) · `JOURNEY_SUSPENSION_CURRENT_VERSION_V4.md` (pause model) · `ZYRA_PRICING_CURRENT_VERSION_V2.md` (plans).
**Stale-name warning for ChatGPT:** any document line calling the current Lab renderer "Sectioned Status", or describing Dashboard link-cards (Connections/Guardian/Notifications cards), predates 2026-08-28 and is superseded.

## 15 · Screenshots / visual references

No current-state PNG exports exist: the 215-variant visual matrix renders in-test, and zero baselines have been approved (OA-ZYRA-257), so nothing current is committed as images. What exists on disk: **30 archived PNGs of the RETIRED six-concept Lab era** at `SYSTEM/RESOURCES/UI_GATE/ARCHIVE/RETIRED_DASHBOARD_MODELS_2026-08-25/` (useful only as history — do not treat as current). The current fixture INDEX (which states are render-covered: Seeker calm/resolved hierarchy/failure at 3 sizes + 130% text; Guardian 0/1/6 links; all Lab concepts × roles × 3 surfaces) lives in `SYSTEM/RESOURCES/UI_GATE/state_matrix.json`. The two practical routes to real pictures, when you want them: your installed profile build (the pending acceptance pass), or asking Codex to export the fixture render set as PNGs — a small, already-supported step I can brief in one line.

## 16 · Open questions (already on the table, no new ones invented)

Founder: accept/adjust today's production Seeker Dashboard + Guardian Pulse on device (OA-ZYRA-264) · select-or-archive the 5 Lab concepts and 4 Guardian siblings · first visual baselines (OA-ZYRA-257) · pause deadlines + migration authority (OA-ZYRA-261) · learning-loop rules ratification + solicitor timing (OA-ZYRA-259) · DR-ZYRA-168 batch timing · the Guardian Browse-activity RLS privacy decision · whether any Basic/One difference should exist on the Dashboards (§10).

---

## FABLE OBSERVATIONS — NOT YET APPROVED

Kept short, per instruction. (1) The five Lab concepts changed meaning today: since all now render the same resolver output, they are presentation skins, not competing products — the honest comparison your ChatGPT session should run is production-renderer vs the two or three skins you actually like, then archive the rest. (2) The Basic/One question is now clean: nothing on either Dashboard is plan-aware, so whatever you decide starts from zero rather than untangling — and needs a Seeker entitlement read built before anything can be gated. (3) The Guardian Dashboard is the older architecture; if the resolver page feels right on your phone, the same Answer-first shape fits Guardian (attention cards are already halfway there) — one decision, not a rebuild proposal. (4) The single highest-leverage unlock for Guardian usefulness is the Browse-activity RLS decision (issue 6): it converts the only staged-dishonest element on either dashboard into real data. (5) Before the ChatGPT session, the ten-minute device pass on the new Dashboard would ground the KEEP/CHANGE/REMOVE conversation in the thing that actually shipped today.

*— End of current-state handover. Facts measured 2026-08-28 by Fable; no code, documentation or register changes were made by this document beyond its own filing.*
