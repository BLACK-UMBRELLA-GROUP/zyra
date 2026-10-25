---
id: DOC-ZYRA-0189
type: HANDOVER
status: CURRENT
feature: GUARDIAN NETWORK
purpose: FABLE CURRENT-STATE HANDOVER — GUARDIAN RELATIONSHIP SURFACES
links: []
owner: ZYRA chat
---

# FABLE CURRENT-STATE HANDOVER — GUARDIAN RELATIONSHIP SURFACES V1

**File:** `ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_STATE_HANDOVER_2026-08-30_V1.md`
**Date:** 2026-08-30 · **Author:** Fable · **Status:** CURRENT-STATE HANDOVER for external (ChatGPT) review — facts separated from recommendations; nothing here is approved direction.
> **RULED 2026-08-30 (same day):** the review this handover opened is
> COMPLETE — Joint Fable × ChatGPT position co-signed and ratified by the
> Founder as DR-ZYRA-224 (F1–F7). Source of truth for the ruled outcome:
> `ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V1.md` (programme
> OA-ZYRA-282). This handover remains the current-state evidence record;
> the UI it describes stays live until the held rebuild executes.

**Method:** every material claim below was read this round from the live Flutter tree, the live database catalog, or the governed registers. Claims taken from governed documents without fresh re-verification are marked **[doc — not re-verified this round]**. The superseded 28 Aug Dashboard snapshot was NOT used.

---

## PART A — TERMINOLOGY AND SCOPE

### A1. Seeker → Guardian tab
- **Screen:** `SeekerWaliTab` (`lib/screens/wali/seeker_wali_tab.dart`), rendering `SeekerGuardianDesigns` (`seeker_guardian_designs.dart`). On-page title: **"Guardians"**.
- **Navigation:** 4th of five Seeker bottom-nav tabs: Browse · Connections · Dashboard · **Guardian** · Profile. Opening the tab clears the Guardian section's notification dot (DR-ZYRA-154 section-read rule).
- **Current use:** shows the Seeker's **linked Guardians** (Main + Additional) as a carousel of relationship cards with each Guardian's genuine activity, an Add flow, and a per-Guardian detail screen (Make Main / Remove / Report). Header comment in the file states its ruled job precisely: *"Invitations moved to Dashboard on Founder direction (2026-08-26). This surface now has one job: show linked Guardians, their genuine activity and the existing add/detail flows."*
- **Multiple Guardians:** yes — one Main plus Additional Guardians; the carousel pages through them.
- **What sits elsewhere:** invitation status/cancel and compact Guardian status live on the **Seeker Dashboard** (Today · FAMILY, modules S14/S15 of the module inventory V3); generic bearer-code review and invite generation live behind this tab's add flow; Guardian-related notifications in the Notifications manager.

### A2. Guardian → Seekers tab
- **Screen:** `WaliSeekersScreen` (`lib/screens/wali/wali_seekers_screen.dart`). On-page title: **"Seekers"**.
- **Navigation:** the Guardian shell (`wali_home_shell.dart`) is **five tabs live: Dashboard · Network · Seekers · Notifications · Profile** — Seekers is 3rd. NOTE: this live shell does not match the navigation source document, which specifies Guardian (Standard) = Dashboard · Seekers · Profile and Guardian+ = Dashboard · Seekers · Browse · Network · Profile. Live has a Notifications tab and no Browse tab. Recorded as document/live drift (Part N/O).
- **Current use:** a flat list of linked Seekers as `ZyraWardCard`s (photo, first name, relationship label, "You are their Main Guardian"/"Additional Guardian") plus an invite entry point. **The cards carry no tap action** (the card widget supports `onTap`; none is passed) — the page is currently a read-only roster plus an invite button.
- **Multiple Seekers:** yes (DR-ZYRA-137: a Guardian may hold many wards). Main and Additional experiences differ only in the card's role line on this page.
- **Persistent Seeker context:** none is set here. Guardian-Network per-Seeker context selection lives on the **Network** screen, not this page.

### A3. Out of scope (referenced only for boundaries)
Guardian Dashboard, Seeker Dashboard, Guardian Network, Connections, full Journey flow, Profile/Settings, Notifications/Updates. Their overlap with the two audited pages is assessed in Part F without redesigning them.

---

## PART B — SEEKER GUARDIAN TAB: EXACT CURRENT STATE

| Order | Element | What it shows | Data source | Appears when | Action | Destination/state change | Live/mock | Final/experimental |
|---|---|---|---|---|---|---|---|---|
| 1 | Page header "Guardians" + **Add a Guardian** button | Title + add entry | — | Always | Tap add | `LinkGuardianScreen` (link/invite flow) | Live | Final |
| 2 | Guardian card carousel (production design: **Guardian Pulse**) | One card per linked Guardian | `wali_links` via `ZyraWaliLinkService.fetchLinkedPeopleResult(asWali:false)` | ≥1 Guardian | Swipe between Guardians | — | Live | Founder-selected production design; 4 alternates remain in code (Part L) |
| 3 | — Card "path" nodes: SEEKER ("You") → SHARED LINK (relationship) → GUARDIAN (first name) → JOURNEY ROLE (Main/Additional wording) | Relationship structure as a decorative path | `wali_links` (relationship, is_main) | Per card | — | — | Live | Final in Pulse design |
| 4 | — Status line "Connected · <when linked>" | Linked-since | `wali_links.created_at` | Per card | — | — | Live | Final |
| 5 | — Recent-activity line | That Guardian's latest genuine activity | `zyra_guardian_activity` RPC via `fetchActivityResult()` | When activity exists | — | — | Live | Final |
| 6 | — "View <name> full Guardian profile" | Detail entry | — | Per card | Tap | `GuardianDetailScreen` | Live | Final |
| 7 | Detail screen: profile block, relationship, "Linked <date>" line | Guardian identity as the Seeker may see it | `wali_links` + `profiles` (first name) | Detail open | — | — | Live | Final. **Deliberately no Verified row** — file comment: "no verification concept exists" for Guardian accounts today (pre-dates DR-ZYRA-221 IDV; intersection recorded in Part N) |
| 8 | Detail: activity list | That Guardian's activity events | `zyra_guardian_activity` | Detail open | — | — | Live | Final |
| 9 | Detail: **Make Main Guardian** | Role change | — | Non-Main Guardian shown | Confirm dialog | `zyra_set_main_guardian(p_wali_id)` RPC; carousel reloads via `linkRevision` | Live | Final |
| 10 | Detail: **Remove Guardian** (tap-once → Confirm/Cancel) | Unlink | — | Always on detail | Guarded confirm | `zyra_remove_guardian(p_wali_id)`; **blocked with explainer if the Guardian is Main and others exist** ("Choose a new Main Guardian first") | Live | Final (DR-ZYRA-136 rule) |
| 11 | Detail: **Report** | Safety report | — | Always on detail | Report flow | Independent of Remove (Founder 2026-08-06) | Live | Final |
| 12 | Empty state | Large + circle, "Add a Guardian" | — | 0 Guardians | Tap | Link flow | Live | Final (GN Draft 3.2 blank-surface pattern) |
| 13 | Links-unavailable state | Truthful failure + Retry | service Result | Fetch failed | Retry | Reload | Live | Final |
| 14 | Dev preview rows | Fake Guardians via developer toggles | `ZyraDevScenario` (guardianOverride/count/mainGuardian) | Dev builds with override on | — | — | Mock, dev-only | Dev tool (never in release path) |

**Not present on this page:** invitation pending/expiry/cancel (Dashboard-owned since 2026-08-26); any premium/upgrade surface ("Wali One capability model is documented but unbuilt" — detail-screen comment); any Journey content beyond the JOURNEY ROLE wording; any three-dot menu.

---

## PART C — GUARDIAN SEEKERS TAB: EXACT CURRENT STATE

| Order | Element | What it shows | Data source | Appears when | Action | Destination/state change | Live/mock | Final/experimental |
|---|---|---|---|---|---|---|---|---|
| 1 | Page header "Seekers" | Title | — | Always | — | — | Live | Final |
| 2 | Loading state | Spinner until link fetch returns | — | While loading | — | — | Live | Final (DR-ZYRA-166: never claims empty while loading) |
| 3 | Ward cards (`ZyraWardCard`, one per Seeker) | Photo, first name, relationship label ("Linked Seeker" fallback), role line "You are their Main Guardian" / "Additional Guardian" | `wali_links` via `fetchLinkedPeople(asWali:true)`; photos via `ZyraDiscoveryService.profilesByIds` signed URLs (a Guardian may view their own ward — DR-ZYRA-171 guard clause) | ≥1 Seeker | **NONE — cards are not tappable** (widget supports onTap; none passed) | — | Live | Final card family (DR-ZYRA-171); interaction absent |
| 4 | "+" circle + "Invite another Seeker" | Second invite entry | — | ≥1 Seeker | Tap | `WaliInviteSeekerScreen` | Live | Final (2026-08-07 fix: entry point used to vanish after first success) |
| 5 | Empty state | Centred + circle "Invite your Seeker" | — | 0 Seekers, loaded | Tap | `WaliInviteSeekerScreen` | Live | Final |
| 6 | Dev ward composition | Stand-in wards top up real ones | `ZyraDevScenario.composeWaliWards` | **Debug/profile builds only** (`kReleaseMode` guard verified in code) | — | — | Mock, dev-only | Dev tool (DR-ZYRA-152; release shows fetched links untouched) |

**Facts about this page's behaviour:**
- **No Journey information at all** — no stage, no Active/Paused/Ended, no waiting-on-you indicator. (The Guardian **Dashboard** Today's "YOUR SEEKERS" section DOES show ward photos, journey-state chips Active/Paused/Ended and a family snapshot — the summary surface is currently **richer** than this dedicated page.)
- **Ordering:** fetch order; no prioritisation of a Seeker needing action; every Seeker gets an equal card; no selection persists anywhere.
- **Failure state:** `fetchLinkedPeople` (non-Result variant) is used, so a failed fetch is indistinguishable from a genuinely empty account once loading ends — **this page currently violates the ruled EMPTY ≠ FAILED law** (the law was applied to Dashboard tabs in the OA-ZYRA-281 Phase 2 patch; this page predates it). Recorded in Parts K and N.
- Scanning at 3–5+ Seekers: a plain vertical list; workable but with zero triage (no ordering, no action indicators), it scales visually and fails informationally.

---

## PART D — COMPLETE INTERACTION MAP

### Seeker Guardian tab
| Element | Expected meaning | Current action | Destination | Backend | Result/state | Back-nav | Stale/error | Permission |
|---|---|---|---|---|---|---|---|---|
| Add a Guardian (header/empty) | Link a Guardian | Opens link flow | `LinkGuardianScreen` | Create: insert into `wali_invites` (returns bearer `token`); Accept path: `accept_wali_invite(p_token,p_relationship)` | On accept, `wali_links` row; `linkRevision` notifies; tab reloads | Pop returns to tab | Errors surfaced in flow | Server: `zyra_can_guardian_link` / `zyra_enforce_guardian_link_allowed` gates **[doc — function names verified in catalog; internals not re-read this round]** |
| Guardian card swipe | Browse guardians | PageView | — | — | — | — | — | — |
| View full Guardian profile | Open detail | Push | `GuardianDetailScreen` | — | — | Pop; `onChanged` reload | — | Seeker sees own links only (RLS: `wali_links` select = seeker_id or wali_id = auth.uid — verified live) |
| Make Main Guardian | Change acting Guardian | Confirm dialog → RPC | — | `zyra_set_main_guardian` | is_main moves; UI reloads | — | Failure keeps prior state | Server-side; DR-ZYRA-136 family of rules |
| Remove Guardian | Unlink | Tap-once → Confirm/Cancel | — | `zyra_remove_guardian` | Link removed; reload | — | Blocked client-side with explainer if Main + others exist (server rule behind it) | Server-side |
| Report | Safety | Report flow | — | Report pipeline | Independent of removal | — | — | — |
| Retry (links unavailable) | Reload | Refetch | — | selects | — | — | Truthful failure state exists | — |
| (Side effect) Opening the tab | — | Clears Guardian notification dot | — | `markSectionRead(guardian)` | Dot cleared | — | — | DR-ZYRA-154 |

### Guardian Seekers tab
| Element | Expected meaning | Current action | Destination | Backend | Result | Flags |
|---|---|---|---|---|---|---|
| Ward card tap | "Open this Seeker" | **NOTHING** | — | — | — | **NO-OP** — expected destination absent; the equivalent per-ward context exists only via Dashboard/Network surfaces |
| Invite your Seeker / + | Invite | Push | `WaliInviteSeekerScreen` | `wali_invites` insert (inviter_role='wali'); token flow; `accept_wali_invite` handles both directions | Link on acceptance | — |
| (Absent) per-card menu, reorder, journey open, review open | — | — | — | — | — | Not built on this page |

**Invitation lifecycle controls (both roles, for completeness):** create (`wali_invites` insert, returns token; relationship pre-filled from `lastUsedRelationship`, "never locked"), preview (`preview_wali_invite` — shows inviter first name before accepting), accept (`accept_wali_invite`), revoke (`zyra_revoke_wali_invite`), decline (`zyra_decline_wali_invite`), expiry (`expires_at` + `zyra_expire_due_wali_invites`; expiring notification tracked via `expiring_notified_at`). Seeker-side pending-invite display/cancel renders on the **Dashboard** FAMILY module (S15), not on the Guardian tab.

**Flags from this part:** (1) Guardian ward-card NO-OP; (2) Guardian Seekers tab silent-empty-on-error; (3) invitation management split across surfaces on the Seeker side (create on tab flow; status/cancel on Dashboard) — coherent under the 2026-08-26 direction but worth a deliberate re-confirmation in this review; (4) no action wording overpromises; no broken routes found on the Seeker tab.

---

## PART E — RELATIONSHIP AND AUTHORITY MODEL (current ruled behaviour)

**The link is per PERSON, not per Journey or attempt:** one `wali_links` row per Seeker↔Guardian pair — `id, seeker_id, wali_id, status, created_at, is_main, relationship` (verified live). Guardian relationships therefore persist across Journeys.

### Seeker side
- **Obtaining a Guardian:** bearer-token invitation (`wali_invites`, DR-ZYRA-083) — either party can invite; `inviter_role` records direction; `accept_wali_invite` creates the link. A named received invitation exists only as a token preview (`preview_wali_invite` returns the inviter's first name) — there is no in-app named invite inbox before code entry.
- **Main Guardian:** exactly one; `is_main`. Defined in product copy as the Guardian "asked to act on your Journey". Changed via Make Main (`zyra_set_main_guardian`). `auto_designate_main_wali` exists server-side (first/only Guardian becomes Main) **[catalog — internals not re-read]**.
- **Additional Guardians:** further linked Guardians, `is_main=false`. Maximum count: no cap found in the audited code paths; none asserted here **[not re-verified]**.
- **Removal:** `zyra_remove_guardian`. Ruled constraint DR-ZYRA-136: **a Seeker may not leave themselves without a Main Guardian** — removing the Main is blocked until another Guardian is made Main (client explains; `zyra_clear_main_guardian` now throws by design — orphan prevention noted in code). Removing the final Guardian: interaction with DR-136 and any Journey-state block **[not re-verified this round — flagged for the review]**.
- **During an Active Journey:** family-process roles (reviews/decisions) run through the Main Guardian; whether removal/replacement is additionally blocked mid-Journey is not re-verified this round and is one of the open questions (Part N).
- **Invitation expiry/cancel:** expiry via `expires_at` + scheduled expiry RPC; Seeker-side cancel = `zyra_revoke_wali_invite` from the Dashboard invitation module. Bearer-code limits: token-based, uppercase-normalised, previewable, declinable; deletion behaviour hardened by DR-ZYRA-134 (`accepted_by` semantics).
- **What the Seeker sees about a Guardian:** first name, relationship label, linked date, role, that Guardian's activity feed entries. **No Guardian verification state** (none exists yet), no plan/location/permission detail (deliberate, per design-file comment).

### Guardian side
- **Linking:** accepts or issues invitations (`WaliInviteSeekerScreen`); server gates `zyra_can_guardian_link` / `zyra_enforce_guardian_link_allowed` (e.g. role/eligibility rules) **[catalog names verified; rule text lives in WALI architecture/migrations]**.
- **Capacity:** DR-ZYRA-137 — a Guardian may hold many wards; the two Seekers in one Match may not share that Guardian, and DR-ZYRA-123 excludes shared-Guardian pairs at matching (Tier-1 romantic exclusion — also encoded in the OA-281 staged projection's participation rules).
- **Main vs Additional:** Main = the acting Guardian for family process (reviews/decisions; `wali_review_decision`); Additional = visibility-limited support role. The precise Additional-Guardian Journey-visibility set is a **HELD batch (DR-ZYRA-168 family / inventory G8)** — not expanded since.
- **Replacement:** role moves via `zyra_set_main_guardian` (Seeker-initiated). Guardian-initiated unlink from the Guardian side: not found on the audited pages (no remove control on the Seekers tab or its cards).
- **Isolation:** Guardian context is per-Seeker; selecting a Seeker for Guardian-Network purposes happens on the Network screen and does not follow the user around the audited pages.
- **Multi-tenancy visibility:** the Seekers tab and Guardian Dashboard show only that Guardian's own wards (RLS select on `wali_links` verified: seeker or wali only).

---

## PART F — DASHBOARD OVERLAP AND OWNERSHIP MATRIX

Baseline for this matrix — the Dashboards as they exist NOW: both roles run the ratified three-tab presentation (Today · Updates · Insights; DR-ZYRA-222/223), built and Fable-verified 2026-08-30, pending Founder device acceptance. The Updates server projection is staged only (revision in progress under OA-ZYRA-281). Discovery Health FAILED validation; **Insights renders honestly empty for both roles**. Seeker Dashboard Today carries the FAMILY module (compact Guardian status + invitation state). Guardian Dashboard Today carries RIGHT NOW · TO DO · YOUR SEEKERS (ward cards, journey chips, family snapshot) · GUARDIAN NETWORK context · one recent move; its Updates tab shows permitted Seeker-labelled Timeline movement.

| Information/action | Dashboard today | Dedicated page today | Duplication? | Review classification (proposed for debate) |
|---|---|---|---|---|
| Guardian connected status (Seeker view) | S14 FAMILY compact ("Dad · Guardian connected") | Full card per Guardian | Compact vs detail | **NECESSARY CONTEXT ON BOTH** (summary→detail continuity) |
| Main Guardian identity | S14 shows relationship label | Card + role node + detail | Mild | **DASHBOARD SUMMARY** + **DEDICATED PAGE DETAIL** |
| Additional Guardians list | Not on Dashboard | Carousel | No | **DEDICATED PAGE DETAIL** |
| Guardian invitation pending/expiry/cancel | S15 module (owns it since 2026-08-26) | Not shown on tab | No | **UNRESOLVED — deliberate split to re-confirm**: status on Dashboard, creation on tab |
| Add/link Guardian | Dashboard empty-state "Add Guardian" (S14) AND tab header/empty add | Yes — two entry points | Yes | **DUPLICATE — REVIEW**: propose Dashboard becomes ROUTE ONLY to the tab flow |
| Replace/reassign Main; Remove Guardian | Not on Dashboard | Detail screen | No | **DEDICATED PAGE DETAIL** (correct today) |
| Guardian activity (per-Guardian feed) | One recent move may surface via Updates | Card line + detail list | Partial | **DEDICATED PAGE DETAIL**; Dashboard = movement only |
| Linked Seekers roster (Guardian view) | YOUR SEEKERS on Today: photos + journey chips + family snapshot | Seekers tab: thinner cards, no journey info, no tap | **INVERTED** — summary richer than the dedicated page | **DUPLICATE — RESHAPE**: Dashboard keeps compact status; the tab must become the detail/management surface |
| Number of Seekers / journey-state chips (Active/Paused/Ended) | Dashboard chips | Absent on tab | Yes (one-sided) | **DEDICATED PAGE DETAIL** (move depth to tab; Dashboard keeps counts) |
| Current Journey / stage / progress per ward | Dashboard journey lines + `wali_journey_detail_screen` exists as a screen | Absent on tab | — | **DEDICATED PAGE DETAIL** via per-Seeker route (currently missing) |
| Family Review / Guardian Gate actions | Guardian Dashboard RIGHT NOW / TO DO triage | Absent on tab | No | **DASHBOARD SUMMARY** (priority) + route into process detail |
| Paused/waiting states | Dashboard | Absent on tab | No | **DASHBOARD SUMMARY**; tab shows per-ward state as context |
| Recent movement / Updates | Updates tab(s), ruled unread-backed + domain rows | Guardian card activity line (Seeker side) | Partial | **DASHBOARD (Updates) owns movement**; per-Guardian history is page detail |
| Guardian Network status/actions | GUARDIAN NETWORK block on Guardian Today; Network tab exists | Not on Seekers tab | No | **SHOULD LIVE ELSEWHERE** (Network surface; out of scope here) |
| Verification state | Seeker Today shows own verification (IDV programme) | Not shown for Guardians anywhere | No | **UNRESOLVED** — DR-ZYRA-221 makes verification mandatory at onboarding for all accounts; Guardian-facing display needs a future ruling |
| Profile information (ward photo/name) | Dashboard ward cards | Tab cards | Yes | **NECESSARY CONTEXT ON BOTH** |
| Saved/Considering/Passed ward activity | Dev-only staged chips on Guardian Dashboard (HELD) | Absent | No | **UNRESOLVED — HELD** (DR-ZYRA-104 PROPOSED, unratified; DR-217 item 7 privacy review pending). Must NOT be granted to fill pages |
| Insights/intelligence | Honestly empty both roles; D6: zero Guardian insight families | Absent | No | **DASHBOARD (Insights) owns**; nothing moves to these pages |
| Premium/upgrade state | None on audited surfaces | None | No | **ROUTE ONLY if ever** (no upgrade surface on relationship pages — NO-list discipline) |
| Empty/setup states | Dashboard FAMILY "No Guardian connected · Add" | Tab + circles | Overlapping prompts | **NECESSARY CONTEXT ON BOTH**, but one canonical add ROUTE |

Objective restated: *Dashboard tells me the current situation; the dedicated page lets me manage and understand the relationship.* Today the Seeker side roughly honours that (with an add-entry duplicate); the Guardian side inverts it.

---

## PART G — WHAT THE PAGES CURRENTLY OWN (de facto)

**Seeker Guardian tab currently owns:** the linked-Guardian roster; Main/Additional structure and reassignment; per-Guardian genuine activity; the add/link flow; Guardian detail (relationship, linked-since, activity, Make Main, Remove, Report).
**One sentence:** *the place a Seeker sees and manages who guards them — thin, but coherent.*

**Guardian Seekers tab currently owns:** a read-only linked-Seeker roster (photo, name, relationship, own role per Seeker) and the invite-a-Seeker entry point. Nothing else.
**One sentence:** *a roster page that names the relationship but offers no way to act on it or look into it.*

---

## PART H — DATA, BACKEND AND SECURITY

**Flutter:** `seeker_wali_tab.dart` (5.8KB) · `seeker_guardian_designs.dart` (55KB, 5 designs) · `guardian_detail_screen.dart` (33KB) · `link_guardian_panel.dart` / `link_wali_screen.dart` · `accept_guardian_invite_screen.dart` / `accept_wali_invite_screen.dart` · `wali_seekers_screen.dart` (9.1KB) · `wali_invite_seeker_screen.dart` · `wali_home_shell.dart` · `zyra_ward_card.dart`. **Services:** `zyra_wali_link_service.dart` (814 lines — links, invites, activity, role RPC wrappers, `linkRevision`/`invitationRevision` notifiers) · `zyra_guardian_info_service.dart` · `zyra_guardian_suggestion_service.dart` · `zyra_wali_journey_service.dart` · `zyra_discovery_service.profilesByIds` (ward photos, guard-suite clause 2).

**Tables:** `wali_links`, `wali_invites` (columns listed in Parts E; verified live). **RPCs/functions (live catalog, verified):** `accept_wali_invite`, `preview_wali_invite`, `zyra_revoke_wali_invite`, `zyra_decline_wali_invite`, `zyra_expire_due_wali_invites`, `expire_wali_invite_if_due`, `zyra_set_main_guardian`, `zyra_clear_main_guardian` (client no longer calls), `zyra_remove_guardian`, `auto_designate_main_wali`, `zyra_can_guardian_link`, `zyra_enforce_guardian_link_allowed`, `zyra_guardian_activity`, `wali_review_decision`, `zyra_attempt_summary_for_guardian`, `guardians_for_unlocked`, `wali_has_wali_one`, plus dev seeds (`zyra_dev_set_guardian_suggestions`, `zyra_dev_guardians_on_decided`, `zyra_dev_set_guardians_on_decided`) and **DB-side purchase mocks** (`mock_purchase_wali_premium`, `mock_set_wali_plan`) — flagged in Part N.

**RLS (verified live):** `wali_links` SELECT restricted to `seeker_id = auth.uid() OR wali_id = auth.uid()`; an INSERT policy exists (predicate not displayed by the probe — internals **[not re-read this round]**). `wali_invites` policies not pulled this round **[to verify in any implementation phase]**. Role RPCs are server-authoritative; the client's Main-removal block is an explainer in front of a server rule, not the enforcement.

**Security posture questions answered:** authentication = Supabase auth; authorisation = link-pair RLS + definer RPCs; relationship proof = the `wali_links` row; enforcement is server-side for links/roles/invites; the client hides nothing security-relevant on these pages. Stale relationship: `linkRevision` refetch on change; after removal the roster reloads. After block/deletion: DR-ZYRA-134 governs deletion; block interactions with guardianship **[not re-verified this round]**. Main vs Additional is reliably distinguishable (`is_main` server column).

**Missing backend capability (relevant to the felt problem):** nothing on the Seekers tab reads `zyra_attempt_summary_for_guardian` or the timeline services — the per-ward journey context the Dashboard shows is absent here by omission of reads, not by missing backend. **Pending/staged:** the OA-ZYRA-281 Updates projection (staged only, revision in progress) will carry guardian-relevant movement classes; nothing else staged touches these pages.

---

## PART I — PRIVACY AND VISIBILITY MATRIX

Legend: ✔ visible · ✖ not visible · △ limited/summary · **HELD** = staged/undecided · columns are current live behaviour unless marked.

| Item | Seeker (self) | Main Guardian | Additional Guardian | Unrelated Guardian | Dashboard summary | Dedicated page detail |
|---|---|---|---|---|---|---|
| Seeker profile basics + photo | ✔ | ✔ (own ward — guard-suite clause 2) | ✔ ward card **[extent beyond card not re-verified]** | ✖ | Ward card | Ward card |
| Journey status/stage | ✔ | ✔ (Dashboard lines, journey detail screen) | **HELD** — DR-ZYRA-168 batch, unexpanded | ✖ | ✔ Guardian Today | ✖ on Seekers tab (absent) |
| Milestones (timeline) | ✔ | ✔ permitted, Seeker-labelled (Guardian Updates) | **HELD** (same batch) | ✖ | Updates | ✖ |
| Guardian decisions / Family Review outcomes | ✔ (party) | ✔ (actor; `wali_review_decision`) | △ **[per WALI architecture baseline — not re-verified]** | ✖ | RIGHT NOW / TO DO triage | Process screens, not these tabs |
| Compatibility answers / private ratings / messages | ✔ own | Ruled by WALI_ARCHITECTURE_CURRENT_VERSION_V5 baseline **[doc — not re-verified this round]** | same | ✖ | ✖ | ✖ on audited pages (nothing renders) |
| Saved / Considering / Passed browse activity | ✔ own | **✖ live. HELD**: DR-ZYRA-104 PROPOSED (2026-07-26, never ratified); DR-ZYRA-217 item 7 privacy review pending; chips exist DEV-ONLY on Guardian Dashboard | ✖ | ✖ | dev-only chips | ✖ |
| Journey end reason / safety reason | ✔ (as ruled per flow) | Collection ≠ display law applies (DR-ZYRA-223 invariant family) — no end-reason rendering on audited pages | ✖ | ✖ | ✖ | ✖ |
| Seeker verification state | ✔ own (IDV programme) | ✖ (no Guardian-facing verification display exists) | ✖ | ✖ | Seeker's own Today only | ✖ — **future ruling needed** (DR-ZYRA-221 intersection) |
| Guardian identity (as Seeker sees it) | — | first name, relationship, linked date, activity; **no verification row** | same pattern | ✖ | S14 compact | Guardian tab cards/detail |
| Other linked Guardians (cross-visibility between Guardians) | ✔ (roster) | **[not re-verified this round]** | **[not re-verified]** | ✖ | ✖ | Seeker tab shows all; Guardian-side mutual visibility unaudited |
| Guardian Network information | △ (Seeker-side GN rules) | GN surfaces (Network tab; `wali_gn_shared.dart`) | GN rules **[doc]** | ✖ | GUARDIAN NETWORK block | Network screen (out of scope) |
| Other Seekers of the same Guardian | ✖ (a Seeker cannot see fellow wards) **[expected; not re-verified]** | ✔ own roster | ✔ own roster | ✖ | — | Seekers tab |

**Ruled vs live mismatches found:** none where live EXCEEDS ruled visibility on these two pages (the audited pages under-display rather than over-display). The open Guardian browse-activity question remains **open** (nothing ruled since the last handover; the dedicated privacy proposal remains a filed draft). **Nothing may be granted Saved/Considering/Passed visibility to make a page look fuller** — restated as binding for this review.

---

## PART J — BASIC VS PREMIUM (current truth only)

| Capability | Basic | Premium entitlement | Implemented | Documented | Contradiction |
|---|---|---|---|---|---|
| Seeker: link/manage Guardians (all Part B actions) | ✔ free | — | ✔ | ✔ | None — essential relationship management is not premium |
| Guardian: roster + invite Seekers | ✔ free | — | ✔ | ✔ | None |
| Guardian Network surfaces | — | `guardian_premium` capability (commercial name Guardian+ per pricing source; DR-ZYRA-105/106) | Network tab live with capability gating inside (`wali_has_wali_one` exists server-side) **[gating internals not re-audited]** | ✔ | Live shell shows a Network tab for all Guardians while the nav doc ties Network to Guardian+ — presentation vs entitlement to confirm |
| "Wali One" premium model on Guardian detail | — | documented concept | **Unbuilt** (explicit code comment) | Partially | Stale doc-vs-code seam, recorded |
| Advanced multi-Seeker tools / process intelligence | — | future | ✖ | Future lists only | — |
| Upgrade surfaces on the audited pages | — | — | **None** (verified) | — | None — and per the Insights NO-list discipline, no upgrade-anxiety surface belongs here |
| DB purchase mocks (`mock_purchase_wali_premium`, `mock_set_wali_plan`) | — | — | Present in live schema | Dev tooling | Flagged Part N: confirm release inaccessibility |

No premium difference is invented here; none exists on these pages today.

---

## PART K — EMPTY, LOADING, FAILURE AND STALE STATES

**Seeker Guardian tab:** no Guardian → + circle "Add a Guardian" (truthful empty). One Main → single Pulse card. Main + Additional → carousel. Invitation pending/expired/cancelled → **rendered on Dashboard S15, not here** (tab unchanged). Link failed → flow-level error. Guardian removed → reload to remaining roster (Main-guard rule enforced first). Main reassignment required → blocking explainer dialog. Loading → spinner. Links fetch failed → **truthful unavailable state with Retry** (✔ complies with EMPTY ≠ FAILED). Activity fetch failed with links present → cards render, activity treated as unavailable (partial truth held). Cached-but-stale: no cache layer; refetch on revision events.

**Guardian Seekers tab:** no Seekers → centred + circle. One/multiple → equal cards. Main vs Additional → role line only. Journey states (none/active/paused/awaiting) → **not represented at all**. Loading → spinner (DR-ZYRA-166 fixed the false-empty-while-loading defect). **Fetch failed → renders the EMPTY state — VIOLATES the ruled EMPTY ≠ FAILED law** (non-Result fetch; predates the Phase 2 law). Cached-but-stale: none.

---

## PART L — DESIGN VARIANTS AND DEVELOPER CONTROLS (rechecked against the live tree)

- **Seeker Guardian page designs:** five in code (`ZyraGuardianPageDesign`): 1 · Guardian pulse (PRODUCTION — pinned in `seeker_wali_tab.dart`), 2 · Shared path, 3 · Action board, 4 · Activity flow, 5 · Living link. The selector rail is **retired from the developer panel** (no panel reference found in `lib/dev/`); designs 2–5 remain compiled in `seeker_guardian_designs.dart` (55KB) as unreachable-in-product alternates → cleanup candidates, not product risk.
- **Guardian dev toggles (live):** `guardianOverride` (`useLiveGuardianData` inverse), `mainGuardian`, `additionalGuardianCount` (`guardianCount` derived), `composeWaliWards` / `composeWaliJourneys` (debug/profile only; `kReleaseMode` guard verified on the Seekers tab and Guardian Dashboard), fake-Guardian fixtures, ward Saved/Considering/Declined chip counts (dev-only, Guardian Dashboard), `ZyraGuardianDashboardTodayState` scenario states, DB-side dev seeds (`zyra_dev_*`). Reset semantics per DR-ZYRA-152 ("zero means zero, every time").
- **Prior references rechecked:** Guardian Pulse = now production (was one of five experiments). Sibling designs = retired-from-rail, still in code. Ward composition = live dev mechanism as documented. Staged Browse chips = still dev-only, still HELD. Linked-Seeker fixtures = compose mechanism above. GN context slider = Network-screen territory, untouched by this audit.
- **Release leakage check:** the release path shows fetched links untouched (verified guards); no developer labels or fake counts found in release paths of the two audited pages.

---

## PART M — CURRENT VISUAL EVIDENCE

**No current screenshots, baselines or candidate renders exist for either audited surface.** The visual suite's images cover the production Seeker Dashboard fixtures (24-variant matrix from OA-ZYRA-281) and the Dashboard Lab concept matrix; nothing captures `SeekerWaliTab`/`SeekerGuardianDesigns` or `WaliSeekersScreen` states. Stated explicitly rather than substituting archived imagery.
**Supported export route (for later, on Founder instruction):** add fixture states for these two screens to the direct visual suite and run the targeted candidate capture used for OA-ZYRA-281 (manifest + PNG variants, `approved:false`, no auto-promotion). Codex owns that execution when a design round reaches evidence stage.

---

## PART N — KNOWN ISSUES AND GOVERNED RECORDS

| Item | Record | Status | Affects | Blocks this review? |
|---|---|---|---|---|
| Guardian browse-activity visibility | DR-ZYRA-104 (PROPOSED 2026-07-26, unratified) + DR-ZYRA-217 item 7 HOLD + filed privacy proposal draft | OPEN, Founder-owned | Part I; any temptation to fill pages | No — but the review must not assume it |
| Additional-Guardian Journey visibility | DR-ZYRA-168 batch (inventory G8) | HELD | Part E/I | No |
| Guardian ward-card NO-OP (no destination) | This handover (new observation) | OPEN | Core felt problem | Central subject |
| Seekers-tab EMPTY==FAILED violation | This handover vs DR-ZYRA-223 empty≠failed law | OPEN defect | Part K | Should be fixed in whatever this review produces |
| Guardian shell nav vs navigation doc drift (five tabs incl. Notifications; no Browse) | This handover | OPEN doc defect | Part A2/O | Fix documentation regardless of outcome |
| Dual add-Guardian entry points (Dashboard S14 + tab) | Inventory V3 vs live | OPEN question | Part F | Review decides ownership |
| Invitation surfaces split (create on tab flow; status/cancel on Dashboard S15) | Founder direction 2026-08-26 | RULED but worth re-confirmation in this review | Part D/F | Review may re-open deliberately |
| Guardian-facing verification display | DR-ZYRA-221 (IDV mandatory) intersection | FUTURE ruling needed | Part I | No |
| DB purchase mocks in live schema | This handover | Confirm release inaccessibility | Part J | No — separate hygiene check |
| Updates projection (guardian movement classes) | OA-ZYRA-281 | Staged only; revision in progress | Part F/H | No — parallel programme |
| Old six-level→three-tab reconciliation | DR-ZYRA-222/223, OA-ZYRA-281 | Phase 2 verified; device acceptance + apply GO pending | Baseline in Part F | No |
| No visual baselines for these pages | Part M | OPEN | Evidence for any redesign | Evidence step later |
| Stale "Wali One" comment vs docs | Part J | Minor seam | Docs | No |

No new OAs are created by this handover (per the review instruction); the two defect-class items (NO-OP cards; EMPTY==FAILED) are recorded here for the joint recommendation to absorb.

---

## PART O — FILES AND SOURCE OF TRUTH

**Canonical code (live, audited):** the Part H file list. **Experimental/stale within them:** designs 2–5 in `seeker_guardian_designs.dart` (retired rail); `wali_dashboard_preview.dart`, `wali_dev_scenario_panel.dart` (dev-only, current); no file found whose name claims currency it lacks on these surfaces.

**Document authority by topic:**
- Guardian architecture / wali links / visibility baseline: `WALI_ARCHITECTURE_CURRENT_VERSION_V5.md` **[named by DR-ZYRA-104 as the ratified baseline; not re-read this round]**.
- Invitations/link mechanism: DR-ZYRA-083 + DR-ZYRA-086 (+ DR-ZYRA-134 deletion semantics).
- Main/Additional rules: DR-ZYRA-136, DR-ZYRA-137, DR-ZYRA-123.
- Guardian navigation: `APP/Navigation/SEEKER NAVIGATION/Summary.md` carries the role rows — **stale vs the live five-tab Guardian shell** (contradiction flagged).
- Seeker navigation: same file — current (updated through DR-ZYRA-223).
- Journey visibility: WALI architecture baseline + DR-ZYRA-168 HELD batch.
- Guardian Network: `ZYRA_GUARDIAN_NETWORK_CURRENT_VERSION_V2.md` + GN build contract/handover.
- Dashboard ownership: `ZYRA_DASHBOARD_MODULE_INVENTORY_CURRENT_VERSION_V3.md` (contract) + `ZYRA_INSIGHTS_SYSTEM_CURRENT_VERSION_V1.md` (intelligence) — both current, 2026-08-30.
- Design-system for person rows/cards: DR-ZYRA-171 card family.

**Contradictions to fix regardless of outcome:** guardian nav doc rows; the Network-tab-for-all vs Guardian+ entitlement presentation; the stale Wali One comment.

---

## PART P — FABLE OBSERVATIONS — NOT YET APPROVED

1. **What each page should become.** Seeker Guardian tab: *the guardianship manager* — roster, roles, per-Guardian history/permissions, linking — already 70% true; it needs substance, not restructure. Guardian Seekers tab: *the ward workspace* — a roster where **every card opens a per-Seeker room** (journey state via existing `zyra_attempt_summary_for_guardian`/timeline reads, pending family actions, my role, GN context entry, invite management). Today it is a dead-end list — the only major surface in the app whose primary object cannot be opened.
2. **Duplication to remove.** Guardian Dashboard Today's YOUR SEEKERS should thin to counts + the one actionable state (its RIGHT NOW/TO DO job), with the roster/journey depth moving to the Seekers tab; the Seeker Dashboard's second "Add Guardian" entry should become a route to the tab flow.
3. **Repetition that must stay.** Compact Guardian-connected status on Seeker Today (S14); ward name+photo context wherever a ward is referenced; invitation status pinned on Dashboard while pending (it is a live obligation — Today's class), with the tab showing the same state as context.
4. **Why the pages feel wrong today.** Seeker tab: one oversized decorative card (path nodes restate three facts with ceremony) and low information density — pretty, thin. Guardian tab: **inverted hierarchy** — the summary surface (Dashboard) is richer than the dedicated page, cards do nothing, journey context is absent, failures masquerade as empty. Both pages under-use real backend that already exists.
5. **Missing information.** Seeker side: what each role means (one-line Main/Additional explainer), invitation state context, what a Guardian can currently see (a trust/privacy disclosure — powerful for a guardianship product). Guardian side: per-ward journey state, waiting-on-you indicators, my-role clarity, a route into everything.
6. **Never add:** browse-activity chips without the Founder privacy ruling; message content; desirability/comparison of wards; engagement filler; upgrade surfaces on relationship management.
7. **Sub-navigation:** neither page needs internal tabs. Roster → detail (push) is the right shape for both; the Seeker side already has it, the Guardian side lacks the push.
8. **Shared design framework:** yes — the DR-ZYRA-171 card family + detail-screen pattern on both sides, same states, same truth laws. The Pulse carousel's path visual should be assessed against the plainer card family for density.
9. **Strongest page contracts (proposed for debate):** Seeker Guardian tab = "see and manage who guards me, and what they can do"; Guardian Seekers tab = "see who I support, what each needs from me, and get to their room in one tap". Dashboard keeps priority/summary/movement; these pages keep management/detail/history.
10. **Codex build economy note:** the per-Seeker room can be assembled substantially from existing screens/services (`wali_journey_detail_screen`, attempt summary, review flows) — this review is mostly an information-architecture ruling, not a greenfield build.

---

# QUESTIONS FOR CHATGPT

1. **The inverted hierarchy:** do you accept "Dashboard = summary/priority; dedicated page = management/detail" as the governing contract, and the Guardian Dashboard YOUR SEEKERS thinning that follows? Where would you draw the exact line for what stays on Guardian Today?
2. **Per-Seeker room:** should ward cards open a dedicated per-Seeker screen (my proposal), or route into existing surfaces (journey detail, Network context) without a new intermediate screen? Argue the navigation cost honestly.
3. **Invitation ownership:** status/cancel on Dashboard with creation on the tab is the ruled split (2026-08-26). Keep, or consolidate invitation lifecycle onto the dedicated pages with Dashboard as route-only? This is a re-open — treat it as such.
4. **Seeker-side density:** is the Pulse path-card worth its space, or should the tab adopt the plain card family + a richer detail screen? Consider the "what my Guardian can see" disclosure idea — value vs risk.
5. **Role disclosure:** how explicitly should Main vs Additional powers be surfaced to BOTH parties, given Additional-Guardian visibility is a HELD batch? Can we phrase role explainers without pre-empting the held rulings?
6. **Truth laws:** confirm the EMPTY ≠ FAILED law and the no-op-card prohibition should be ratified as page-level requirements for any outcome here (they were Dashboard rulings; these pages need them extended).
7. **Multi-ward scale:** at 3–10 wards, what ordering/triage rule should the roster use (needs-action first? journey-state grouping?) without inventing scores or surveillance?
8. **Verification intersection:** once DR-ZYRA-221 IDV enforcement is live, should either party see the other's coarse verified state on these pages, or is that a Dashboard/profile matter? Flag the consent/privacy shape you would require.
9. **DR-ZYRA-104 disposal:** it has sat PROPOSED since July. Should this review recommend the Founder formally close or narrow it, so the browse-activity question stops haunting every Guardian surface?
10. **Scope discipline:** what would you cut from my observations as scope creep for a V1 of this review?

**Process:** respond adversarially; Fable will challenge back per the established loop; joint recommendation → Founder ratification → documentation → only then Codex. No Codex contact, no code changes, no migrations from this handover.

— Fable, 2026-08-30
