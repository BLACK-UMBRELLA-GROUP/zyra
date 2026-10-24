# ZYRA Dashboard — Module Inventory ("What can exist, and when")

**Version:** V1
**Status:** CURRENT_VERSION — **DRAFT FOR FOUNDER REVIEW.** No implementation authority. Visual design stays frozen until this table is agreed (Founder direction §24). The resolver remains the brain (DR-ZYRA-216); this inventory defines what the HOME built on it may contain.
**Date:** 2026-08-28
**Author:** Fable (product rules — AD-AIOS-105 domain)
**Authority:** Founder "Dashboard = ZYRA home" direction, 2026-08-28 (25 sections), issued after reviewing `ZYRA_DASHBOARD_CURRENT_STATE_HANDOVER_2026-08-28_V1.md` with ChatGPT
**Register:** OA-ZYRA-265
**Data-reality sources:** current-state handover (measured 2026-08-28) · `ZYRA_LEARNING_LOOP_DATA_AUDIT_CURRENT_VERSION_V1.md` · `ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md` (draft rules) · DR-ZYRA-216 · `JOURNEY_SUSPENSION_CURRENT_VERSION_V4.md` · DB schema V1

---

## 0 · The one-sentence contract this inventory serves

> The Dashboard is the user's ZYRA home — a calm, intelligent view of what matters now, where they are, what is changing, who is involved, and what ZYRA can help them understand next. The resolver decides priority; the home presents life. Show the right thing at the right time; the page must breathe.

## 1 · How to read the tables

**Presence:** ALW = always renders · CND = conditional (suppressed when empty — the §19 rule) · HOLD = do not build yet (blocked or premature) · REM = recommend not building.
**Plan:** B = Basic · ONE = ZYRA One only · BOTH = identical · DEPTH = both, One deeper.
**Int:** INFO = information only · TAP = clickable · MIX = some elements tap.
**Weight:** P1 = primary · P2 = secondary · P3 = supporting.
**Exists:** LIVE = in production today · PART = partial/real read exists but module doesn't · MOCK = dev-only mock · NO = nothing.
**FD** = Founder decision required beyond agreeing this row (named in §5/§6).

Levels are the Founder's §20 hierarchy: L1 Right Now · L2 Journey/Search · L3 My ZYRA · L4 Family · L5 Recent movement · L6 ZYRA Intelligence.

## 2 · SEEKER modules

| # | Module | Lvl | Presence | Plan | Int | Weight | Data source | Exists | Real/Mock | Verdict + notes |
|---|---|---|---|---|---|---|---|---|---|---|
| S1 | Header: greeting + salam | — | ALW | BOTH | INFO | P3 | AppState name | LIVE | Real | KEEP |
| S2 | Notification bell + unread badge → full manager | — | ALW | BOTH | TAP | P2 | notifications read | LIVE | Real | KEEP — manager stays the history/manager identity (§6) |
| S3 | **RIGHT NOW** — one resolver-chosen priority (obligation, or calm) | L1 | ALW | BOTH | TAP | P1 | resolver over all sources | LIVE | Real | KEEP — unchanged heart of the page |
| S4 | Right Now: advisory form ("What ZYRA recommends") when NO obligation exists | L1 | CND | DEPTH | TAP | P1 | resolver + (later) confirmed learning | NO | — | **MERGE into S3** — one slot; a second "one thing" (§17 as a separate card) would compete with the first. Every recommendation carries its defensible "why". FD: ratify as the calm-state upgrade |
| S5 | Right Now: refresh-required / partial-failure form | L1 | CND | BOTH | TAP | P1 | sourceHealth | LIVE | Real | KEEP — calm stays prohibited under failure |
| S6 | **YOUR JOURNEY** — adaptive: Active (name, canonical stage, x/8 rail, progress, primary action) | L2 | ALW* | BOTH | TAP | P1 | journey rows + stage map | LIVE | Real | KEEP + enrich (S7–S9). *Adaptive: becomes S10 when nothing live |
| S7 | Journey sub-line: latest completed stage ("You completed Faith & Values") | L2 | CND | BOTH | INFO | P3 | timeline_milestones | PART (read exists, not surfaced) | Real | **NEW — OK.** Milestones are already written server-side |
| S8 | Journey sub-line: NEXT milestone ("Next: Family Compatibility" / "2 stages until Family Review") | L2 | CND | BOTH | INFO | P3 | canonical stage map (order only) | NO | — | **NEW — OK.** Product-safe: the 8-stage map is public product truth; no future content revealed. FD: approve wording pattern |
| S9 | Journey momentum line ("Your Journey progressed twice this week") | L2 | CND | BOTH | INFO | P3 | milestone timestamps | PART | Real | **NEW — OK as a LINE inside S6, not a card.** Guard: never renders a quiet week as failure — absence = silence (dignity rule). No scores, no streaks |
| S10 | **YOUR SEARCH** (replaces S6 when no live Journey): Potentials count · ready-for-discovery state | L2 | CND | BOTH | TAP | P1 | journey rows (potential) + onboarding | LIVE (as journey-kind variants) | Real | KEEP — already how the resolver journey summary behaves; presentation grows per §3 |
| S11 | Search extra: "N new introductions since your last visit" | L2 | HOLD | BOTH | INFO | P3 | requires last-visit bookmark | NO | — | **HOLD — collides with DR-216 gate 2** (no generic `last_seen_at`). Honest alternative today: unread-notification-backed "new" only. FD: either accept unread-backed wording or explicitly amend DR-216 + authorise the bookmark (small migration) |
| S12 | Journey "whose move it is" | L2 | HOLD | BOTH | INFO | P2 | shared-pause state machine | NO | — | HOLD until pause migration authorised/applied/probed (OA-ZYRA-261) |
| S13 | **MY ZYRA snapshot** — compact tiles: Potentials · Saved · Guardian status · (unread) | L3 | ALW | BOTH | MIX | P2 | journey rows · saves count (owner read) · wali_links | PART (all reads exist; module doesn't) | Real | **NEW — OK.** Orientation, not navigation-cards. EXCLUDE a Journey tile (L2 owns Journey — §22 no duplication). Tiles info-first; Potentials/Saved may tap |
| S14 | **YOUR GUARDIAN** stable status ("Dad · Connected" / "Invitation pending · 3 days" / "No Guardian · Add") | L4 | ALW (compact) | BOTH | TAP | P2 | wali_links + invites | PART (reads live; stable state currently kept OFF dashboard by design) | Real | **NEW — OK, and I support it**: Guardian presence is ZYRA's differentiator; home may hold stable state. Requires DR-216 amendment (stable-state class added alongside movement). Small; never a huge card. FD: ratify amendment. Privacy note: relationship label only — no health/sensitive detail |
| S15 | Guardian invitation module (sent/pending, expiry, Cancel) | L4 | CND | BOTH | TAP | P2 | wali_invites + revoke RPC | LIVE | Real | KEEP — becomes the expanded state of S14 when an invitation exists |
| S16 | **RECENTLY** — meaningful movement, capped (≈3), + "View all notifications" footer | L5 | CND | BOTH | TAP | P2 | unread/meaningful notifications + guardian activity + milestones | LIVE (as Worth Knowing/Other-Action rows) | Real | KEEP, renamed/reframed — this is Worth Knowing grown into the §6 shape. Cap stays; inbox feeling stays in the manager |
| S17 | "Since you were last here" return summary | L5 | REM as separate | — | — | — | last-visit bookmark | NO | — | **MERGE into S16** — same content, different window. Two recency sections re-create clutter (§19). The window question is S11's FD |
| S18 | Positive milestone moments ("First Journey started", "Guardian connected") | L5 | CND | BOTH | INFO | P3 | milestones | PART | Real | **MERGE into S16 with celebratory styling** + at the MOMENT it happens it may be the S3 answer once. No trophies/streaks/points — ever |
| S19 | **THIS WEEK ON ZYRA** digest | L5 | HOLD | ONE (later) | INFO | P3 | aggregation layer | NO | — | HOLD — duplicates S16 today (§16 asked for honest assessment: it adds value only once pool/learning data exist; revisit at Learning P3 as a One-tier weekly digest) |
| S20 | **ZYRA HAS NOTICED** — governed insights | L6 | CND | DEPTH (B:1 · ONE:3) | TAP | P2 | Learning Loop engine | MOCK (dev) / honest-empty (prod) | Mock | KEEP AS DESIGNED, INACTIVE — thresholds/wording per Learning Loop V1; Article 9 families solicitor-gated; activates at Learning P3 only. Never decorative filler |
| S21 | Insight response actions (accurate / not relevant / show why / never again) | L6 | CND | DEPTH | TAP | P3 | learning engine | NO | — | KEEP (ships with S20; confirmed-learning-only application per ratified rules) |
| S22 | **DISCOVERY HEALTH** ("12 profiles currently fit your core preferences") | L6 | HOLD | ONE | INFO | P2 | NEW server aggregate RPC | NO | — | HOLD — honestly computable only via a new server-side count over hard requirements; location CANNOT contribute (free-text, no geo); sect/ethnicity axes excluded from any narrowing explanation until Article 9 clearance. "Narrowest around location" is NOT computable today — never claim it. FD: authorise the aggregate RPC design (One-tier candidate; commercially strong) |
| S23 | Preferences at a glance ("You recently changed relocation to Flexible") | L6 | HOLD | BOTH | TAP | P3 | preference change history | NO — latest-state only (data audit) | — | HOLD — no change-history exists; would require event capture (migration). The "ZYRA noticed language matters" variant = S20 priority-drift family (gated). Today's honest version: a plain "Review preferences" target already exists in the resolver |
| S24 | UPCOMING / WAITING ON (deadlines, "decision due in 2 days") | L6 | HOLD | BOTH | INFO | P2 | ratified deadlines | NO | — | HOLD — zero deadline rules ratified (pause deadlines = open Founder decisions, OA-ZYRA-261). The ONE real countdown that exists — invitation expiry — already renders in S15. Genuine "waiting" facts (review open, pause pending) surface via S3/S16 wording without countdowns |
| S25 | Onboarding gate ("profile hidden until setup complete") | L1 | CND | BOTH | TAP | P1 | onboarding progress | LIVE | Real | KEEP — when present it IS the answer |
| S26 | Basic→One upgrade surface on Dashboard | — | HOLD | B | TAP | P3 | entitlements | NO (no Seeker plan read exists at all) | — | HOLD — decide §18 split first; prerequisite build: Seeker entitlement read (client + likely server). Never make Basic feel punished; gate DEPTH of intelligence (S20/S22/S19), not orientation (S13/S14) |

## 3 · GUARDIAN modules

| # | Module | Lvl | Presence | Plan | Int | Weight | Data source | Exists | Real/Mock | Verdict + notes |
|---|---|---|---|---|---|---|---|---|---|---|
| G1 | Header + greeting | — | ALW | BOTH | INFO | P3 | AppState | LIVE | Real | KEEP |
| G2 | **RIGHT NOW (Guardian)** — Family Review / Guardian Gate cards; honest all-clear line | L1 | ALW | BOTH | TAP | P1 | reviews + journey stages | LIVE (as NEEDS YOUR ATTENTION) | Real | KEEP — already Answer-shaped. Multi-Seeker triage order: reviews first, then gates (who needs me first) |
| G3 | **YOUR SEEKERS** — per-ward card: photo, Main/Additional, status line, 8-stage rail, real chips | L2/L3 | ALW | BOTH | TAP | P1 | wali links + journeys | LIVE | Real | KEEP — compact per §23; do not copy Seeker cards |
| G4 | Ward Browse-activity chips (Saved/Considering/Declined) | L3 | HOLD | BOTH | INFO | P3 | needs Guardian RLS read | MOCK (staged dev counts) | Mock | HOLD — the open privacy/RLS Founder decision; the only staged-dishonest element on either dashboard. FD |
| G5 | Guardian invitation module (invite Seeker; pending/cancel) | L4 | CND | BOTH | TAP | P2 | invites | LIVE | Real | KEEP (empty state: big + "Invite your Seeker") |
| G6 | **FAMILY ACTIVITY** — Guardian Network context (introductions, network movement) | L4 | CND | BOTH* | TAP | P2 | GN + wali_suggestions | Dev-preview (GN Rule 44) | Mock/preview | KEEP-PLANNED — goes live with GN launch. *Plan question: Guardian+ (not ZYRA One) is the Guardian-side tier — pricing alignment needed. FD |
| G7 | **RECENTLY (Guardian)** — latest milestone per live Journey | L5 | CND | BOTH | TAP | P2 | timelines | LIVE | Real | KEEP |
| G8 | Additional-Guardian Journey visibility | L2 | HOLD | BOTH | — | — | DR-ZYRA-168 batch (RLS+RPC) | NO | — | HOLD — ruled, ships as its own batch |
| G9 | **GUARDIAN INTELLIGENCE** — family/process insights | L6 | HOLD | Guardian+ (proposed) | TAP | P2 | future learning | NO | — | HOLD — explicitly a separate Founder-approved design per Learning Loop V1 §9.1 (Seeker-only rule stands until then). Tier = Guardian+, not ZYRA One. FD |
| G10 | Guardian "My ZYRA" snapshot (wards count, reviews open, invites) | L3 | CND | BOTH | INFO | P3 | existing reads | PART | Real | NEW — OK, small; only if G3 alone proves insufficient on device. Cheap, optional |
| G11 | Stale-refresh banner + full error/empty states | — | CND | BOTH | TAP | P3 | fetch state | LIVE | Real | KEEP — truthful-failure law |
| G12 | Guardian dashboard onto the shared resolver (architecture alignment) | — | Decision | — | — | — | resolver | NO (own reads today) | — | RECOMMEND: yes, as the implementation vehicle for §23 — same six levels, role-specific adapter (008 already agreed adapters stay role-specific). FD: sequencing |

## 4 · Fable challenges (requested — where the direction would hurt the page)

1. **Three recency mechanisms would rebuild the clutter you removed.** Recently (§6), Since-You-Were-Last-Here (§7) and This Week (§16) are one idea at three time windows. Recommendation: ONE "Recently" section (S16), celebration styling for milestones inside it (S18), and This Week held until it can say something Recently can't (needs the learning/pool layer). Otherwise the home becomes an inbox with extra steps — the exact §19 failure.
2. **Two "one things" = none.** "What ZYRA Recommends" (§17) as a standing section competes with Right Now for the same psychological slot. Recommendation: it is the calm-state FORM of Right Now (S4) — when nothing needs you, the answer may help you; never two priority cards.
3. **"Since your last visit" quietly reverses a decision you ratified this morning.** DR-ZYRA-216 gate 2 rejected a generic `last_seen_at` bookmark (Codex's argument, you approved it). §7 needs exactly that bookmark. Both positions are defensible — but it must be an explicit amendment, not a drift. My lean: unread-backed "new" covers 90% of the value with zero new tracking.
4. **Discovery Health can overpromise.** "Narrowest around location" is not computable (location is free text, deliberately unscored) and preference-narrowing explanations touch Article 9 axes. The honest v1 is a single server-computed eligible-count for One — still commercially strong — with narrowing-attribution deferred to the learning system's gated pool-impact family.
5. **Momentum must never become a scoreboard.** Weekly phrasing ("twice this week") is fine when true, but ZYRA is deliberately slow: the module must render NOTHING in a quiet week — never "no progress this week". Same dignity law as the Timeline. I've written S9 as a conditional line, not a card.
6. **Don't let the snapshot resurrect the four navigation cards.** S13 works only if the Journey tile is excluded (L2 owns it) and tiles stay glanceable. The moment tiles grow buttons and paragraphs, we've rebuilt 2026-08-24.
7. **Guardian intelligence belongs to Guardian+, not ZYRA One.** §18/§23 imply One buys Guardian-side depth; the pricing model sells Guardian+ for the Guardian side (bundled for the Main Wali of a One Seeker). Tier mapping needs deciding before any Guardian-intelligence design, or the paywall will sit on the wrong plan.
8. **Commercial shape of Basic/One (supporting §18, sharpening it):** gate intelligence depth (insights count, trends, Discovery Health, weekly digest, deeper "why"), never orientation, Guardian presence, safety, or truthful state. Basic must remain a complete, honest home — that is also the stronger upsell: One feels like MORE understanding, not unlocked furniture. Prerequisite named in S26.

## 5 · Ratified decisions this inventory would amend (nothing amends silently)

| Decision | What changes if the table above is agreed |
|---|---|
| DR-ZYRA-216 (gates 1–2, content classes) | ADD a stable-state class (S13 My ZYRA, S14 Guardian status) alongside obligations/movement; optionally ADD last-visit bookmark (S11) — explicit override of the gate-2 rejection |
| DR-ZYRA-216 (renderer shape) | Answer → Journey → Actions → Worth Knowing grows to the six-level home; resolver unchanged as brain |
| Learning Loop V1 (unchanged) | S20/S21/S22 stay behind its evidence/consent gates — this inventory adds no new AI permissions |
| Suspension V4 / OA-ZYRA-261 (unchanged) | S12/S24 stay blocked on your deadline + migration decisions |
| Adapter rule "linked ≠ movement" | Unchanged for L5; S14 shows linked state as STABLE status, which is the distinction the rule was protecting |

## 6 · Founder decisions this table needs (beyond row-by-row KEEP/CUT)

1. S4 — Recommends-Next as the calm-state form of Right Now: yes/no.
2. S11/S17 — recency window: unread-backed (no new tracking) OR authorise the last-visit bookmark (DR-216 amendment + small migration).
3. S14 — ratify the stable-state amendment to DR-216 (Guardian status + My ZYRA on the home).
4. S22 — authorise design of the eligible-count aggregate (One tier), with the honesty ceiling stated.
5. S26/§18 — confirm the Basic/One split principle (depth-of-intelligence only) so the entitlement-read build can be scoped.
6. G4 — the Guardian Browse-activity RLS privacy decision (unchanged, still the biggest Guardian unlock).
7. G6/G9 — Guardian-side tier = Guardian+ (pricing alignment).
8. G12 — move the Guardian dashboard onto the shared resolver as the §23 vehicle: yes/no + sequencing.
9. Deadlines (S24) remain with OA-ZYRA-261 — no countdowns until ratified.

## 7 · What happens after you mark up this table

You return KEEP/CHANGE/REMOVE per row (+ the §6 decisions). I file the DR recording the agreed inventory (superseding the named parts of DR-216), update the product spec, and only THEN does visual design resume — with this table as the binding content contract, so Codex designs presentation for an agreed home rather than another beautiful guess. Design remains frozen meanwhile; OA-ZYRA-264's device acceptance of the current build stays open and unaffected.

---

*V1 · 2026-08-28 · Fable. Facts about "exists today" trace to the current-state handover and data audit; nothing here implements anything.*
