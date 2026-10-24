# ZYRA Dashboard — Module Inventory ("What can exist, and when")

**Version:** V3
**Status:** CURRENT_VERSION — **FOUNDER-DECIDED CONTENT CONTRACT.** V2's nine DR-ZYRA-217 decisions remain the content law except where DR-ZYRA-222 (2026-08-30) supersedes: the Seeker presentation is now the **three-tab Dashboard — TODAY · UPDATES · INSIGHTS** (D1), Insights are governed by `ZYRA_INSIGHTS_SYSTEM_CURRENT_VERSION_V1.md`, and Discovery Health is the ruled sole V1 insight candidate (D2/D3). **BUILD STATUS 2026-08-30:** the live app still renders the six-level single-page Home built under MESSAGES/012 (Fable-verified 2026-08-29); the three-tab migration is ruled but NOT yet built — it proceeds under OA-ZYRA-281 only after the Founder approves the Codex implementation contract.
**Date:** 2026-08-30
**Author:** Fable
**Authority:** DR-ZYRA-217 (2026-08-28, superseded in part) · DR-ZYRA-222 (2026-08-30, Founder rulings D1–D6)
**Supersedes:** ZYRA_DASHBOARD_MODULE_INVENTORY_2026-08-30_V2.md (archived)
**Register:** OA-ZYRA-265 (six-level build, complete) · OA-ZYRA-281 (three-tab migration + Insights V1) · DR-ZYRA-216 · DR-ZYRA-217 · DR-ZYRA-222

---

## 0 · The ratified principle (Founder, verbatim — unchanged)

> The Dashboard should show enough stable state to feel like home, enough movement to feel alive, and enough intelligence to become more useful over time — without becoming a feed, analytics page or collection of navigation cards.

Resolver = brain. Dashboard = home. Show the right thing at the right time; the page must breathe. The three tabs do not change this: suppression is still a feature, and every DR-ZYRA-216 gate stands.

## 1 · The ratified presentation and content architecture (DR-ZYRA-222 D1)

**SEEKER DASHBOARD — three tabs:**

| Tab | Owns (source-of-truth class) | Modules |
|---|---|---|
| **TODAY** | State — where things stand (plus the one resolver-chosen priority) | Header/greeting (S1), notification utility (S2), RIGHT NOW incl. calm-advisory and partial-failure forms (S3/S4/S5), JOURNEY / SEARCH (S6–S10), MY ZYRA (S13/S13a), FAMILY (S14/S15), onboarding gate (S25) |
| **UPDATES** | Changes — what happened | RECENTLY stream (S16, absorbing S17/S18 rules): meaningful movement, milestone moments, unread-backed activity, "View all notifications" footer. Served by ONE bounded read projection over existing authoritative timestamped records — no new event store |
| **INSIGHTS** | Derived understanding only | S20/S21 governed insights (honest-empty until real), S22 Discovery Health (sole V1 candidate). **Never state cards.** Governed by `ZYRA_INSIGHTS_SYSTEM_CURRENT_VERSION_V1.md` |

Level-to-tab mapping from the superseded six-level Home: Header + RIGHT NOW + JOURNEY/SEARCH + MY ZYRA + FAMILY → TODAY; RECENTLY → UPDATES; ZYRA INTELLIGENCE → INSIGHTS. All DR-ZYRA-217 content rules survive re-homed (DR-ZYRA-222 Decision 2 map).

**GUARDIAN (unchanged, sequenced):** the Guardian Dashboard is untouched by D1 and keeps DR-ZYRA-217 Decision 8 sequencing. Guardian insight families: zero in V1; **process, never behaviour** is permanent (D6).

Not every section appears every time. Suppression is a feature.

## 2 · Legend (unchanged)

**Verdict:** KEEP · MERGE(→row) · HOLD (do not build yet) · REMOVE · DESIGN-ONLY (spec authorised, production blocked) · V1-CANDIDATE (DR-ZYRA-222: build behind validation gates).
**Plan:** BASIC (all users — the never-paywalled core) · DEPTH (both plans, premium deeper) · PREMIUM (premium only; Seeker side = ZYRA One, Guardian side = the `guardian_premium` capability). **DR-ZYRA-222 note: ALL insight rendering is plan-identical in V1 (no entitlement read exists); DEPTH/PREMIUM markings on insight rows are future-principle only, pending ratification.**
**Presence:** ALW · CND (suppressed when empty/zero-noise) · — for held rows.
**Exists:** LIVE / PART / MOCK / NO (as measured against the current build).

## 3 · SEEKER modules — FINAL (tab assignment per §1)

| # | Module | Verdict | Plan | Presence | Exists | Ruling notes |
|---|---|---|---|---|---|---|
| S1 | Header greeting | KEEP | BASIC | ALW | LIVE | TODAY |
| S2 | Notification bell + badge → manager | KEEP | BASIC | ALW | LIVE | TODAY; manager stays the history/manager identity |
| S3 | **RIGHT NOW** — one resolver-chosen priority | KEEP | BASIC | ALW | LIVE | TODAY. Never paywalled. Owns the only priority slot |
| S4 | Calm-advisory form of Right Now ("Nothing needs your attention." + optionally ONE defensible suggestion) | **MERGE→S3** (ratified) | DEPTH* | CND | NO | TODAY. Advisory only in calm state; every suggestion carries its "why"; suggestions sourced from governed intelligence only. *Plan-identical in V1 |
| S5 | Partial-failure form (calm prohibited; Retry) | KEEP | BASIC | CND | LIVE | TODAY. Truthful-failure law unchanged |
| S6 | **YOUR JOURNEY** (active: name, canonical stage, x/8 rail, progress, one primary action) | KEEP | BASIC | ALW* | LIVE | TODAY. *Adaptive — becomes S10 when nothing live. The emotional centre |
| S7 | Journey line: latest completed stage | KEEP | BASIC | CND | PART | TODAY. From real milestones |
| S8 | Journey line: NEXT milestone (stage-map order only) | KEEP | BASIC | CND | NO | TODAY. Product-safe; no future content invented |
| S9 | Journey momentum line | KEEP (line, not card) | BASIC | CND | PART | TODAY. Renders NOTHING in a quiet week — dignity rule; no scores/streaks |
| S10 | **YOUR SEARCH** (no live Journey: Potentials count, ready state) | KEEP | BASIC | CND | LIVE | TODAY. Journey/search truth never paywalled |
| S11 | "N new since your last visit" | **REMOVE (bookmark variant)** | — | — | NO | Unread-backed only, no `last_seen_at`, no migration — DR-216 gate 2 stands. Honest "new" lives inside S16 |
| S12 | Journey "whose move it is" | HOLD | BASIC | — | NO | Blocked on OA-ZYRA-261 migration + deadline decisions |
| S13 | **MY ZYRA snapshot** (orientation tiles) | KEEP (ratified) | BASIC | **CND-intelligent** | PART | TODAY. Render only tiles carrying useful information; never a wall of zeros; genuinely informative absence still shows. No Journey tile (S6 owns it) |
| S13a | — Saved tile | KEEP, demoted | BASIC | CND | PART | TODAY. Saved is orientation, never a number to watch grow; no growth emphasis, ever |
| S14 | **FAMILY — stable Guardian status** | KEEP (ratified) | BASIC | ALW (compact) | PART | TODAY. Central product difference; compact; relationship label only |
| S15 | Guardian invitation module (sent/pending, expiry, Cancel) | KEEP | BASIC | CND | LIVE | TODAY. Expanded state of S14; invitation expiry countdown is real |
| S16 | **UPDATES stream** (was RECENTLY) — meaningful movement + milestone moments (celebratory styling) + unread-backed new activity + "View all notifications" footer | KEEP (absorbs S17/S18) | BASIC | CND | LIVE (as rows) | UPDATES tab. ONE recency stream, capped ≈3 on entry view; never an inbox; served by the allowlisted read projection |
| S17 | Since-you-were-last-here section | **REMOVE** | — | — | — | Merged into S16 |
| S18 | Positive milestones section | **MERGE→S16** | BASIC | CND | PART | A milestone may be S3's answer once; no trophies/streaks/points |
| S19 | This Week on ZYRA digest | HOLD | PREMIUM (future) | — | NO | Revisit when aggregation exists and it can say something S16 cannot |
| S20 | **Governed insights ("ZYRA has noticed")** | KEEP-DESIGNED, INACTIVE | ALL (V1 identical; depth pending) | CND | Honest-empty | INSIGHTS tab. Governed by `ZYRA_INSIGHTS_SYSTEM_CURRENT_VERSION_V1.md` + DR-ZYRA-222 D3/D4: LEVEL 0 display-only; no Article 9 derivation beyond the ruled Discovery Health exception; INFERENCE/EMERGING never render in V1; never decorative. (Supersedes V2's "solicitor-gated" wording — DR-ZYRA-220) |
| S21 | Insight response actions (helpful / not helpful / hide / why; mute-family second-level) | KEEP (ships with S20) | ALL (V1) | CND | NO | INSIGHTS tab. Writes `insight_feedback`; quarantined from recommendations (D4) |
| S22 | **DISCOVERY HEALTH** — honest eligible-count | **V1 SOLE CANDIDATE (DR-ZYRA-222 D2/D3)** | ALL (V1; depth pending) | CND | NO | INSIGHTS tab. Validation before construction: definition + one-way directionality, verified-only pool, low-count bucketing, differencing invariant (never a one-person change detector), block-exclusion rules, material-change batch recompute, query cost. Article 9 processing per the ruled D3 exception ONLY (risk-accepted; precedent lock absolute). Still binding from DR-217 item 6: NO narrowing attribution; never a location-narrowing claim. If validation fails: honest-empty, no speculative stores |
| S23 | Preferences at a glance (change history) | HOLD | BASIC | — | NO | No change-history exists; "Review preferences" resolver target remains the honest version |
| S24 | Upcoming / Waiting-on with countdowns | HOLD | BASIC | — | NO | No invented countdowns; only ratified deadlines ever render |
| S25 | Onboarding gate | KEEP | BASIC | CND | LIVE | TODAY. When present it IS the answer |
| S26 | Basic→One upgrade surface on Dashboard | HOLD | BASIC-visible | — | NO | Pending entitlement read + DR (see §5); never make Basic feel punished; no upgrade-anxiety insights (NO-list) |

## 4 · GUARDIAN modules — FINAL (unchanged by D1; DR-ZYRA-222 D6 noted)

| # | Module | Verdict | Plan | Presence | Exists | Ruling notes |
|---|---|---|---|---|---|---|
| G1 | Header + greeting | KEEP | BASIC | ALW | LIVE | — |
| G2 | RIGHT NOW (Family Review / Guardian Gate; honest all-clear) | KEEP | BASIC | ALW | LIVE | Triage: reviews first, then gates |
| G3 | YOUR SEEKERS (per-ward card, canonical stages, real chips) | KEEP | BASIC | ALW | LIVE | Compact; not Seeker cards |
| G4 | Ward Browse-activity chips (Saved/Considering/Declined) | **HOLD — EXPLICIT FOUNDER PRIVACY REVIEW** | — | — | MOCK (dev-staged) | Access NOT assumed; proposal filed separately; chips dev-only; no RLS path |
| G5 | Guardian invitation module + empty-state "+" | KEEP | BASIC | CND | LIVE | — |
| G6 | FAMILY ACTIVITY — Guardian Network context | KEEP-PLANNED | **`guardian_premium` capability** where premium | CND | Dev-preview | Gate by entitlement capability, not product name |
| G7 | RECENTLY (Guardian) | KEEP | BASIC | CND | LIVE | — |
| G8 | Additional-Guardian Journey visibility | HOLD | BASIC | — | NO | DR-ZYRA-168 batch, unchanged |
| G9 | GUARDIAN INTELLIGENCE | HOLD | `guardian_premium` | — | NO | **DR-ZYRA-222 D6: zero Guardian insight families in V1; PROCESS, NEVER BEHAVIOUR is permanent.** Own governed design round after Guardian presentation is settled |
| G10 | Guardian My-ZYRA snapshot | KEEP-OPTIONAL | BASIC | CND-intelligent | PART | Same zero-noise suppression rule as S13 |
| G11 | Truthful failure/stale/empty states | KEEP | BASIC | CND | LIVE | — |
| G12 | Guardian onto the shared resolver | **YES IN PRINCIPLE — SEQUENCED** | — | — | NO | Never both dashboards changing at once; Guardian presentation decision comes before any Guardian tab work |

## 5 · Basic vs ZYRA One (updated by DR-ZYRA-222)

> **Basic gets a complete, honest and useful home. ZYRA One gets deeper understanding.**

**Never paywalled:** Right Now · Journey/search truth · Guardian presence · important actions · safety · core progress · truthful state · **verification (DR-ZYRA-221)** · **factual insight content**.
**V1 (DR-ZYRA-222):** ALL insights identical on every plan — no Seeker entitlement read exists, nothing is gateable, and no paid insight promise launches. Discovery Health is NOT One-allocated in V1 (supersedes V2 §5's placement).
**FUTURE ENTITLEMENT PRINCIPLE — PENDING RATIFICATION:** One depth = longer windows · historical trends · recurring patterns · richer "why" · advanced AI Help · future weekly digest — depth, never artificial card counts. Prerequisites: the Seeker entitlement read + its own DR.
**Guardian side:** premium gates on the `guardian_premium` capability; commercial naming stays with the pricing source of truth.

## 6 · Amendment history (none silent)

1–4. **DR-ZYRA-217 (2026-08-28):** stable-state class added (S13/S14); calm-advisory Answer form; gate 2 re-decided (unread-backed, no bookmark); resolver ranking/truthful-failure/notifications-manager/no-migration/pause-deadline/learning gates unchanged.
5. **DR-ZYRA-222 (2026-08-30):** presentation superseded — six-level single page → TODAY · UPDATES · INSIGHTS (map in §1); Insights governance moved to `ZYRA_INSIGHTS_SYSTEM_CURRENT_VERSION_V1.md`; Discovery Health V1 sole candidate under the ruled Article 9 exception (risk-accepted, precedent-locked); insights LEVEL 0 display-only; plan-identical V1; solicitor-gate wording removed (DR-ZYRA-220); Guardian insight families zero in V1 (D6).

## 7 · What is now open, and with whom

| Item | Owner |
|---|---|
| Review the Codex implementation contract (three-tab migration + Insights V1) — approve before any mailbox send | Founder |
| On approval: file contract as 032_FABLE-CODEX; Codex design/validation phase (validation precedes construction) | Fable → Codex |
| Discovery Health validation report (definition, distribution, bucketing/floors, query cost) | Codex → Fable verify |
| Privacy policy + DPIA insights sections (D3 processing + risk-acceptance record) before enablement | Fable draft → Founder sign |
| Guardian Browse-activity privacy proposal — decide | Founder |
| OA-ZYRA-264 device acceptance of the current build | Founder (unchanged) |

---

*V3 · 2026-08-30 · Fable. Presentation and insight rulings trace to DR-ZYRA-222; all other verdicts trace to DR-ZYRA-217 and remain unchanged. Nothing here implements anything.*
