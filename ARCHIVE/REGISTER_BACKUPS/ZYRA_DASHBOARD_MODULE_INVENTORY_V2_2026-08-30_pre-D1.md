# ZYRA Dashboard — Module Inventory ("What can exist, and when")

**Version:** V2
**Status:** CURRENT_VERSION — **FOUNDER-DECIDED CONTENT CONTRACT** (all nine §6 decisions + pushback responses ratified 2026-08-28, recorded as DR-ZYRA-217). **BUILD STATUS 2026-08-29:** Founder GO 2026-08-28 (MESSAGES/011) consumed; Seeker Home CODE COMPLETE (Codex, MESSAGES/012); Fable disk verification PASSED 2026-08-29 (39/39 hashes; boundaries held). Pending: independent Claude architecture pass; Founder device acceptance. This inventory remains the binding content contract for that build and all future Dashboard work.
**Date:** 2026-08-28
**Author:** Fable
**Authority:** Founder decisions message 2026-08-28 (responding to Inventory V1)
**Supersedes:** ZYRA_DASHBOARD_MODULE_INVENTORY_2026-08-28_V1.md (archived)
**Register:** OA-ZYRA-265 · DR-ZYRA-217 (amendments to DR-ZYRA-216 recorded there — nothing amended silently)

---

## 0 · The ratified principle (Founder, verbatim)

> The Dashboard should show enough stable state to feel like home, enough movement to feel alive, and enough intelligence to become more useful over time — without becoming a feed, analytics page or collection of navigation cards.

Resolver = brain. Dashboard = home. Show the right thing at the right time; the page must breathe.

## 1 · The ratified content architecture

**SEEKER HOME:** Header (greeting + notification utility) → RIGHT NOW (one resolver-selected priority; calm form may carry ONE advisory suggestion) → JOURNEY / SEARCH (the emotional centre; adaptive to state) → MY ZYRA (small orientation signals — only useful ones) → FAMILY (stable Guardian state + invitation state when relevant) → RECENTLY (meaningful movement only) → ZYRA INTELLIGENCE (only when ZYRA genuinely has something to say).

**GUARDIAN HOME (sequenced AFTER Seeker — Decision 8):** RIGHT NOW → YOUR SEEKERS → JOURNEYS → FAMILY ACTIVITY → RECENTLY → GUARDIAN INTELLIGENCE. Same philosophy, role-specific information; Seeker cards are not copied.

Not every section appears every time. Suppression is a feature.

## 2 · Legend

**Verdict:** KEEP · MERGE(→row) · HOLD (do not build yet) · REMOVE · DESIGN-ONLY (spec authorised, production blocked).
**Plan:** BASIC (all users — the never-paywalled core) · DEPTH (both plans, premium deeper) · PREMIUM (premium only; Seeker side = ZYRA One, Guardian side = the `guardian_premium` capability per Decision 7) .
**Presence:** ALW · CND (suppressed when empty/zero-noise) · — for held rows.
**Exists:** LIVE / PART / MOCK / NO (as measured in the current-state handover).

## 3 · SEEKER modules — FINAL

| # | Module | Verdict | Plan | Presence | Exists | Ruling notes |
|---|---|---|---|---|---|---|
| S1 | Header greeting | KEEP | BASIC | ALW | LIVE | — |
| S2 | Notification bell + badge → manager | KEEP | BASIC | ALW | LIVE | Manager stays the history/manager identity |
| S3 | **RIGHT NOW** — one resolver-chosen priority | KEEP | BASIC | ALW | LIVE | Never paywalled (Decision 5). Owns the only priority slot |
| S4 | Calm-advisory form of Right Now ("Nothing needs your attention." + optionally ONE defensible suggestion) | **MERGE→S3** (ratified) | DEPTH | CND | NO | Decision 1: advisory appears only in calm state; every suggestion carries its "why"; suggestions sourced from governed intelligence only |
| S5 | Partial-failure form (calm prohibited; Retry) | KEEP | BASIC | CND | LIVE | Truthful-failure law unchanged |
| S6 | **YOUR JOURNEY** (active: name, canonical stage, x/8 rail, progress, one primary action) | KEEP | BASIC | ALW* | LIVE | *Adaptive — becomes S10 when nothing live. The emotional centre |
| S7 | Journey line: latest completed stage | KEEP | BASIC | CND | PART | From real milestones |
| S8 | Journey line: NEXT milestone (stage-map order only) | KEEP | BASIC | CND | NO | Product-safe; no future content invented |
| S9 | Journey momentum line | KEEP (line, not card) | BASIC | CND | PART | Renders NOTHING in a quiet week — dignity rule; no scores/streaks |
| S10 | **YOUR SEARCH** (no live Journey: Potentials count, ready state) | KEEP | BASIC | CND | LIVE | Journey/search truth never paywalled |
| S11 | "N new since your last visit" | **REMOVE (bookmark variant)** | — | — | NO | Decision 2: **unread-backed only, no `last_seen_at`, no migration** — DR-216 gate 2 stands. Honest "new" lives inside S16 |
| S12 | Journey "whose move it is" | HOLD | BASIC | — | NO | Unchanged — blocked on OA-ZYRA-261 migration + deadline decisions |
| S13 | **MY ZYRA snapshot** (orientation tiles) | KEEP (ratified) | BASIC | **CND-intelligent** | PART | **Amended presence rule (Founder):** render only tiles carrying useful information; suppress or replace zero-noise — "Potentials 0 · Saved 0 · Unread 0" must never render as a wall of zeros, while genuinely informative absence ("No Guardian connected · Add") still shows. No Journey tile (S6 owns it) |
| S13a | — Saved tile | KEEP, demoted | BASIC | CND | PART | **Founder caution ratified:** Saved is orientation, never a number to watch grow; P3 supporting; Potentials/Journey/Guardian always outrank it; no growth emphasis, ever |
| S14 | **FAMILY — stable Guardian status** ("Dad · Guardian connected" / "Invitation pending · 3 days remaining" / "No Guardian connected · Add Guardian") | KEEP (ratified — Decision 3, DR-216 amendment recorded) | BASIC | ALW (compact) | PART | Central product difference; compact, never a navigation card; relationship label only |
| S15 | Guardian invitation module (sent/pending, expiry, Cancel) | KEEP | BASIC | CND | LIVE | The expanded state of S14 when an invitation exists; invitation expiry countdown stays — it is real (Decision 9) |
| S16 | **RECENTLY** — meaningful movement + milestone moments (celebratory styling) + unread-backed new activity + "View all notifications" footer | KEEP (absorbs S17/S18) | BASIC | CND | LIVE (as rows) | ONE recency section, capped ≈3; never an inbox |
| S17 | Since-you-were-last-here section | **REMOVE** | — | — | — | Decision 2 / pushback 1 — merged into S16 |
| S18 | Positive milestones section | **MERGE→S16** | BASIC | CND | PART | At the moment it happens, a milestone may be S3's answer once; no trophies/streaks/points |
| S19 | This Week on ZYRA digest | HOLD | PREMIUM (future) | — | NO | Revisit at Learning P3 when it can say something S16 cannot |
| S20 | **ZYRA HAS NOTICED** — governed insights | KEEP-DESIGNED, INACTIVE | DEPTH (B:1 · One:3) | CND | MOCK/empty | Learning Loop V1 gates unchanged; Article 9 families solicitor-gated; never decorative |
| S21 | Insight response actions | KEEP (ships with S20) | DEPTH | CND | NO | Confirmed-learning-only application |
| S22 | **DISCOVERY HEALTH** — honest eligible-count ("14 profiles currently meet your core requirements") | **DESIGN-ONLY (ratified — Decision 4)** | PREMIUM (candidate) | — | NO | Spec authorised NOW; production blocked until: eligibility definition, calculation source, privacy/legal constraints, number stability/explainability, test against real onboarding data. NO narrowing-attribution; never a location-narrowing claim |
| S23 | Preferences at a glance (change history) | HOLD | BASIC | — | NO | No change-history exists; "Review preferences" resolver target remains the honest version; priority-drift = S20 family |
| S24 | Upcoming / Waiting-on with countdowns | HOLD | BASIC | — | NO | Decision 9: no invented countdowns; only ratified deadlines ever render; real waiting facts surface via S3/S16 wording |
| S25 | Onboarding gate | KEEP | BASIC | CND | LIVE | When present it IS the answer |
| S26 | Basic→One upgrade surface on Dashboard | HOLD | BASIC-visible | — | NO | Decision 5 principle ratified (see §5); prerequisite when implementation reaches this stage: build the Seeker entitlement read; never make Basic feel punished |

## 4 · GUARDIAN modules — FINAL

| # | Module | Verdict | Plan | Presence | Exists | Ruling notes |
|---|---|---|---|---|---|---|
| G1 | Header + greeting | KEEP | BASIC | ALW | LIVE | — |
| G2 | RIGHT NOW (Family Review / Guardian Gate; honest all-clear) | KEEP | BASIC | ALW | LIVE | Triage: reviews first, then gates |
| G3 | YOUR SEEKERS (per-ward card, canonical stages, real chips) | KEEP | BASIC | ALW | LIVE | Compact; not Seeker cards |
| G4 | Ward Browse-activity chips (Saved/Considering/Declined) | **HOLD — EXPLICIT FOUNDER PRIVACY REVIEW (Decision 6)** | — | — | MOCK (dev-staged) | Access is NOT assumed. The dedicated privacy proposal is filed separately as `ZYRA_GUARDIAN_BROWSE_ACTIVITY_PRIVACY_PROPOSAL_2026-08-28_DRAFT.md` answering the Founder's eight questions; chips stay clearly dev-only; no RLS path is built |
| G5 | Guardian invitation module + empty-state "+" | KEEP | BASIC | CND | LIVE | — |
| G6 | FAMILY ACTIVITY — Guardian Network context | KEEP-PLANNED | **`guardian_premium` capability** where premium | CND | Dev-preview | Decision 7: gate by entitlement capability, not product name; current source of truth (Pricing V2) maps the capability to Guardian+ — if the commercial model changes later, the mapping changes, not the UI |
| G7 | RECENTLY (Guardian) | KEEP | BASIC | CND | LIVE | — |
| G8 | Additional-Guardian Journey visibility | HOLD | BASIC | — | NO | DR-ZYRA-168 batch, unchanged |
| G9 | GUARDIAN INTELLIGENCE | HOLD | `guardian_premium` | — | NO | Separate Founder-approved design per Learning Loop V1 §9.1; capability-gated per Decision 7 |
| G10 | Guardian My-ZYRA snapshot | KEEP-OPTIONAL | BASIC | CND-intelligent | PART | Only if G3 alone proves insufficient on device; same zero-noise suppression rule as S13 |
| G11 | Truthful failure/stale/empty states | KEEP | BASIC | CND | LIVE | — |
| G12 | Guardian onto the shared resolver | **YES IN PRINCIPLE — SEQUENCED (Decision 8)** | — | — | NO | Order: (1) Seeker content contract final (this doc) → (2) Seeker home designed/tested → (3) Founder confirms the approach on device → (4) Guardian moves onto the shared resolver with its own role-specific adapter. Never both dashboards changing at once |

## 5 · Ratified Basic vs ZYRA One principle (Decision 5)

> **Basic gets a complete, honest and useful home. ZYRA One gets deeper understanding.**

**Never paywalled:** Right Now · Journey/search truth · Guardian presence · important actions · safety · core progress · truthful state.
**One differentiation (when built):** deeper/more insights · historical trends · Discovery Health · recurring compatibility patterns · richer "why" explanations · advanced AI Help · the future weekly intelligence digest.
**Prerequisite at implementation time:** the Seeker entitlement read (none exists in the client today).
**Guardian side:** premium features gate on the `guardian_premium` capability; commercial naming/bundling stays owned by the pricing source of truth.

## 6 · Amendments to DR-ZYRA-216 (recorded in DR-ZYRA-217 — none silent)

1. **ADDED:** a stable-state content class on the home — S13 My ZYRA (intelligent suppression) and S14 Guardian status — alongside obligations and movement.
2. **ADDED:** the calm-advisory form of the Answer (S4-merged): in calm state, Right Now may carry one defensible, governed suggestion.
3. **REAFFIRMED UNCHANGED:** gate 2 — no generic `last_seen_at`/visit bookmark; recency is unread-backed. Explicitly re-decided by the Founder, not drifted.
4. **UNCHANGED:** resolver ranking, no-passive-demotion, truthful failure, notifications-manager reachability, no-migration boundary, pause/deadline blocks (OA-ZYRA-261), learning gates (OA-ZYRA-259).

## 7 · What is now open, and with whom

| Item | Owner |
|---|---|
| Review this V2; give the explicit GO that unfreezes visual design | Founder |
| Guardian Browse-activity privacy proposal (filed separately, draft) — decide | Founder |
| Discovery Health specification (design-only) | Fable to draft when prioritised |
| Seeker home visual design brief to Codex (content contract = this doc) | Fable, ONLY after the GO |
| OA-ZYRA-264 device acceptance of the current build | Founder (unchanged, unaffected) |

---

*V2 · 2026-08-28 · Fable. All verdicts trace to the Founder's decisions message of 2026-08-28; existence facts trace to the current-state handover. Nothing here implements anything.*
