---
id: DOC-ZYRA-0146
type: SPEC
status: CURRENT
feature: GENERAL
purpose: ZYRA Learning Loop — Adaptive Dashboard Insights
links: []
owner: ZYRA chat
---

# ZYRA Learning Loop — Adaptive Dashboard Insights

**Version:** V1
**Status:** CURRENT_VERSION — **DRAFT RULES, awaiting Founder ratification. PRODUCTION LEARNING INACTIVE.** Nothing in this document activates any automated personal conclusion.
**Date:** 2026-08-25
**Author:** Fable (Company Operations & Documentation) — product/rules on Founder instruction
**Authority:** Founder directive to Fable + Codex, 2026-08-25 ("ZYRA should gradually learn about the user from their past experiences") — including the correction that **the Seeker Dashboard already exists and is not to be rebuilt**
**Register:** OA-ZYRA-259
**Related documents:** `ZYRA_SEEKER_DASHBOARD_HANDOVER_CURRENT_VERSION_V1.md` · `ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V5.md` · `ZYRA_LEARNING_LOOP_DATA_AUDIT_CURRENT_VERSION_V1.md` · `ZYRA_JOURNEY_ENTITLEMENT_DECISION_CURRENT_VERSION_V1.md` · `ZYRA_JOURNEY_TIMELINE_CURRENT_VERSION_V3.md` (DR-ZYRA-121/129) · `ZYRA_CHAPTER2_QUESTION_REVIEW_CURRENT_VERSION_V1.md` · `ZYRA_LEGAL_RESEARCH_CURRENT_VERSION_V1.md` · `ZYRA_GUARDIAN_VISIBILITY_AND_TRUST_MODEL_V1_DRAFT.md` · `ZYRA_COST_DISCIPLINE_CURRENT_VERSION_V1.md` — moved to the private group folder (7 Nov 2026)

---

## 1 · What this is

ZYRA should not remain static after onboarding. As a Seeker saves, considers,
sets aside, matches, starts/pauses/ends Journeys, progresses through stages,
changes preferences and answers compatibility questions, ZYRA gradually
identifies useful patterns and surfaces them as **calm, personalised
observations with useful next steps inside the existing Seeker Dashboard** —
using the existing card system and visual language.

Target feeling: *"ZYRA is beginning to understand what works for me."*
Never: *"ZYRA is monitoring or judging me."*

This is a **learning layer**, not a new surface. It adds at most one compact
insight section to the Dashboard the Seeker already has (production hub per the
Seeker Dashboard handover; composable as a module in the Dashboard Lab
inventory if a Lab concept is later promoted). It is not an analytics page.

## 2 · Definitions

| Term | Meaning |
|---|---|
| **Evidence event** | One recorded user action or lifecycle event from a permitted source (§4) |
| **Candidate pattern** | A regularity detected across evidence events; internal only, never shown |
| **Insight** | A candidate pattern that has passed the evidence thresholds (§5) and is rendered as Dashboard copy under the wording rules (§6) |
| **Confirmed learning** | An insight the user has explicitly marked accurate; the only class permitted to influence behaviour (§7) |
| **Counterpart** | Another profile/person contributing evidence; never identifiable from any insight |
| **Insight family** | The template class an insight belongs to (§6.3) — suppression and "don't show again" operate at this level |

## 3 · The learning loop

```
User activity (permitted sources only)
      ↓  OBSERVE — silent aggregation, no user-visible effect
Candidate pattern
      ↓  EVIDENCE CHECK — §5 thresholds; below threshold → nothing shown
Dashboard presents the insight carefully (§6 wording, §8 depth)
      ↓  USER RESPONSE — confirm · not relevant · review · show why · never again
Confirmed learning only
      ↓  APPLY — §7; ranking/questions/prompts may improve
Future recommendations improve; hard dealbreakers and explicit
preferences remain authoritative until the user changes them.
```

Insight lifecycle states: `candidate → eligible → shown → confirmed |
dismissed | suppressed | expired`. Expiry is silent (§5.6). The user remains
in control at every arrow: **ZYRA never rewrites a preference because it
noticed a pattern** — it may only invite the user to review one.

## 4 · Permitted data sources

All sources are existing in-app data already held under ZYRA's own schema
(`saves`, `likes`, `passes`, `matches` + `end_reason`, `timeline_milestones`
via the `matches_record_journey_milestone` trigger, `profiles` preference
fields incl. hard/soft requirement flags, compatibility answers, and
aggregate search-pool counts). No new collection is introduced.

| Source | Used for | Allowed |
|---|---|---|
| Saves / outgoing Considers / set-asides | Priority-drift and alignment patterns | ✓ |
| Matches lifecycle (start, pause, end) | Journey-stage patterns | ✓ |
| `end_reason` (user-declared) | Correlational input only — never replayed back as a cause | ✓ cautious |
| Stage completions (`timeline_milestones`) | "Journeys often pause around X" patterns, using DR-ZYRA-129 canonical stage names | ✓ |
| Preference values + hard/soft flags | Pool-impact insights; drift detection | ✓ |
| Compatibility answers (non-special-category axes) | Alignment/difference patterns | ✓ |
| Compatibility axes that are **UK GDPR Article 9** data (sect, revert status, ethnicity; the values instrument's religious-practice content) | Chapter-level alignment insights (e.g. "Faith & Values is your strongest area") | **⛔ GATED — designed here, but inactive until the Article 9 consent basis is solicitor-confirmed** (Legal Research §2A; Chapter 2 Review §6) |
| Aggregate search-pool counts | "This preference narrows your recommendations" | ✓ |

**Never sources, in any phase:** message or conversation content;
Guardian-originated data about the Seeker; any other user's identity, name or
profile as part of an insight; device location or signals; anything outside
the app. A compatibility difference, paused Journey or ended Journey **does
not reveal why** a relationship did not progress, and is never treated as if
it does.

## 5 · Evidence and confidence thresholds

1. **Tier 0 — Insufficient.** Fewer than 3 distinct counterparts contributing
   to a pattern, or all evidence within a single week → **no insight exists**.
   The Dashboard shows the neutral state (§6.4), never a padded conclusion.
2. **Tier 1 — Early pattern (cautious wording).** ≥ 3 distinct counterparts
   AND evidence spanning ≥ 2 distinct weeks → cautious verbs only
   ("appears", "may be worth").
3. **Tier 2 — Established pattern (clearer wording).** ≥ 5 distinct
   counterparts AND ≥ 3 occurrences of the specific dimension AND the pattern
   still holds in the most recent 30 days → firmer verbs
   ("has consistently", "continues to be").
4. **Anonymity floor.** No insight may be shown that a Seeker could map to one
   identifiable person: minimum 3 contributing counterparts, no
   single-counterpart examples, no dates or details that pinpoint an
   individual, and "Show me why" summarises evidence only in aggregate
   ("across several recent compatible profiles over the last six weeks").
5. **Dignity cool-off.** No insight referencing a dimension is shown or
   updated within **7 days** of a Journey ending that contributed to it. The
   Dashboard must never read as commentary on what just happened. (Wording
   inherits the Journey Timeline principle: an ending is not a failure.)
6. **Decay and re-verification.** Evidence is weighted over a rolling 90-day
   window. A shown or confirmed insight is re-verified each window; a pattern
   that no longer holds **retires silently** — the Dashboard never announces
   "you have changed".
7. **Determinism and cost.** v1 scoring is rule-based counting on-device /
   in-query — deterministic, explainable, **$0.00, no AI calls** (Cost
   Discipline V1). Any future AI-worded insight layer is a separate Founder
   decision.
8. **Surface budget.** At most **1** insight card on Basic, up to **3** on
   ZYRA One (§8), ranked by confidence × usefulness × freshness. Expansion
   beyond the card is user-initiated only.

## 6 · Safe wording rules

### 6.1 Observation, never cause

| Allowed vocabulary | Banned vocabulary |
|---|---|
| "appears often in your compatibility differences" | "because of", "the reason was" |
| "has consistently aligned well" | "people rejected you", "you were declined for" |
| "often paused around", "tends to" | "you failed", "went wrong" |
| "narrows your recommendations" | any caps/quotas/counters language (Entitlement Decision — Language) |
| "may be worth reviewing / discussing earlier" | "you should change", "fix your" |

ZYRA may observe *"Relocation was a common area of difference."* It must not
claim *"People rejected you because of relocation"* — no causal explanation is
ever invented, and `end_reason` values are never echoed back as explanations.

### 6.2 Register

Two sentences maximum per insight plus one optional action; calm, British
English; no exclamation marks; no scores or percentages on Basic (One may show
simple trends); never name or describe another person; never pressure
entitlement use.

### 6.3 Insight families (v1 candidate set — wording examples, NOT approved copy)

| Family | Tone | Example shape (Founder examples, pending approval) |
|---|---|---|
| Strongest recurring alignment | Positive | "Faith & Values continues to be your strongest area." |
| Common recurring difference | Reflective | "Relocation appears often in your compatibility differences. This may be worth reviewing before your next Journey." |
| Preference pool-impact | Practical | "Your location preference significantly narrows your recommendations." → Review preference |
| Journey-stage pattern | Reflective | "Your recent Journeys have often paused around Family Compatibility. This may be an area worth discussing earlier." |
| Positive progression correlate | Positive | "Profiles with similar family expectations have progressed further with you." |
| Priority drift | Practical | "Your recent choices suggest language matters more to you than you originally selected." → Review my priorities |

**Balance rule:** the surface must not become a list of problems. When a
reflective insight is shown, a positive/working insight is shown alongside it
whenever one exists at threshold; if none exists, the reflective insight still
shows alone rather than inventing praise.

### 6.4 Insufficient-data state

Honest and calm, e.g. *"ZYRA learns from your journey as it unfolds. There is
not enough here yet for personal insights."* Never a fake insight, never a
progress bar of "learning".

## 7 · Automatic learning vs user confirmation

| Layer | Permitted automatically | Requires explicit user action |
|---|---|---|
| Counting, aggregation, candidate detection, confidence scoring | ✓ (invisible; changes nothing) | — |
| Showing an insight card | ✓ once §5 thresholds pass | — |
| Marking an insight accurate / not relevant / hidden | — | ✓ user response |
| **Any behavioural change** — recommendation ranking, compatibility explanations, Journey question selection, earlier-discussion suggestions, preference-review prompts, ZYRA One intelligence | **⛔ never automatic** | ✓ only from **confirmed** learning, and reversible |
| Editing a preference or dealbreaker | ⛔ never — the system may only open the preference screen for the user | ✓ user edits it themselves |

Response actions (v1): **This feels accurate** (→ confirmed learning) ·
**Not relevant** (→ dismissed; evidence penalty on that family) ·
**Review my preferences** (→ opens existing preference surface; no auto-change) ·
**Show me why** (→ aggregate evidence summary, §5.4) ·
**Don't show this insight again** (→ family suppressed until re-enabled in Settings).

Hard requirements and explicit preferences remain authoritative over every
learning output, always. Confirmed learning is stored as explicit
user-approved facts, listed and revocable in Settings.

## 8 · ZYRA Basic vs ZYRA One

Both tiers receive the **same honesty, the same evidence rules, the same
safety**. One is deeper, not truer. Basic is never made intentionally poor.

| | ZYRA Basic | ZYRA One |
|---|---|---|
| Concurrent insights | 1 (highest-confidence; refreshed weekly) | Up to 3 |
| Strongest compatibility area | ✓ | ✓ with trend over time |
| Preference pool-impact | ✓ basic warning | ✓ with per-preference analysis |
| Journey progress info | ✓ (existing surfaces) | ✓ plus Journey-stage patterns |
| Recurring alignment / difference | Strongest only | Multiple recurring patterns |
| Priority-drift insights | — | ✓ |
| "Show me why" depth | Summary sentence | Fuller aggregate explanation |
| How confirmed learning improves recommendations | — | ✓ transparency panel |

Entitlement gating uses the existing entitlement source; the learning system
never grants, consumes or alters entitlement.

## 9 · Privacy, retention, Guardian visibility

1. **Seeker-only.** v1 insights are visible to the Seeker alone. No Guardian
   surface receives behavioural patterns, compatibility differences,
   preference changes, pool-narrowing reasons or any sensitive personal
   learning — consistent with "guidance, not surveillance" (Guardian
   Visibility & Trust Model draft; Legal Research §3 data-minimisation).
   Any future Guardian-facing intelligence is a **separate Founder-approved
   design** built around the Guardian's legitimate role.
2. **No identification.** §5.4 anonymity floor binds every surface including
   "Show me why".
3. **Retention.** Evidence aggregates: rolling 12 months. Candidate patterns:
   recomputed, not archived. Confirmed learning and suppression choices:
   kept until the user changes them or deletes their account
   (`delete_own_account()` cascade includes all learning data). Specific
   periods restated in the privacy policy when drafted.
4. **Processing location.** Existing Supabase project (AWS eu-west-1) only;
   no new processors introduced by v1.
5. **Data-subject rights.** Insights, confirmed learning and suppressions are
   in scope for access and erasure requests.
6. **Disclosure.** The privacy policy's automated-processing section (Legal
   Research §4.1) must be extended to describe this learning, its user
   controls and its influence on ordering once activated. Confirmation-gated
   application keeps a human decision in the loop (Art. 22 posture).
7. **Article 9 gate.** Insight families derived from sect, revert status,
   ethnicity or religious-practice answers are designed here but **inactive
   until the solicitor confirms the Article 9 consent basis** (Legal Research
   §2A routes; Chapter 2 Review §6). This gate binds Basic and One equally.

## 10 · Contradiction check (Founder-requested)

| Domain | Document | Result |
|---|---|---|
| Compatibility | Chapter 2 Question Review V1 | No contradiction. Dependencies inherited: hard/soft flag consolidation (§2) is assumed by §7; the mock reference-list blocker (§1) limits language/heritage insight quality until real lists exist; Article 9 flag (§6) binds §4/§9.7. |
| Journey | Journey Timeline V3 (DR-ZYRA-121/129) + milestones trigger | No contradiction. Stage insights use the canonical stage map's names; the milestone trigger already records journey start / stage completions / endings, so **no new event capture is required** for stage patterns. Timeline dignity language ("an ending is not failure") binds §5.5/§6. |
| Entitlement | Journey Entitlement Decision V1 | No contradiction. Its language rule (no caps/quotas/counters) is adopted into §6.1; learning never consumes, grants or pressures entitlement (§8). |
| Data protection | Legal Research V1 | No contradiction; two obligations imported — Article 9 gate (§9.7) and automated-processing disclosure (§9.6). Guardian data-minimisation upheld by §9.1. |
| Dashboard | Seeker Dashboard Handover V1 + Dashboard Lab V5 | No contradiction. This system adds one compact section/module to the existing Dashboard card system; it does not select a Lab concept, colour treatment, replace the hub, or add consolidated status claims. |

## 11 · Phasing and activation gates

| Phase | Content | Gate to proceed |
|---|---|---|
| P0 | This rules draft | **Founder ratifies rules + final insight copy** |
| P1 | Codex: historic-data audit; feasibility per family; missing-aggregation list; **mock insight cards** in the existing Dashboard (positive, neutral, insufficient-data, preference-review; Basic vs One) — clearly labelled mock, Lab/dev only | Founder device review of mocks |
| P2 | Deterministic aggregation + internal candidate patterns; **nothing user-visible** | Fable verification vs §5 rules |
| P3 | Seeker-visible insights (non-gated families) | Founder approval; solicitor clearance for any Article 9 family before it joins |
| P4 | Confirmed-learning influence on ranking/questions | Separate Founder approval + privacy-policy disclosure live |

Production learning stays **INACTIVE** until the P3 gate passes. Mock data and
production learning are never mixed (Lab truth-boundary discipline).

## 12 · Open questions for the Founder

1. Placement: production hub card vs the equivalent module in whichever
   current Dashboard Lab concept the Founder eventually promotes — or both,
   one definition.
2. Ratify the §5 thresholds (3/5 counterparts, 2-week span, 90-day window,
   7-day cool-off) or amend the numbers.
3. Approve the §6.3 family set and final copy (current text is example-only).
4. Basic refresh cadence — weekly rotation acceptable?
5. Solicitor engagement timing for the Article 9 gate (also blocks Chapter 2
   §6; one instruction covers both).

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-25 | First rules draft per Founder learning-loop directive (existing-Dashboard correction honoured). Production learning inactive. |
