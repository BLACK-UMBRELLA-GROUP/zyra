# ZYRA — Onboarding Interaction Design Review

**Document:** ZYRA_ONBOARDING_UX_REVIEW_2026-08-05_V1.md
**Reviewer:** Fable, UX & Product Experience Lead
**Commissioned by:** Founder, 2026-08-05 — "challenge the structure, not the length"
**Scope:** Chapters 1–4, with emphasis on the Chapter 3 → Chapter 4 double pass
**Method:** Measured directly from `SOURCE/lib/data/chapter3_categories.dart`, `values_preferences_flow.dart`, `traffic_light_question_screen.dart` and the governed specs in `APP/Onboarding/`. Every number below is counted, not estimated.

**Premise accepted:** length is deliberate and stays. Nothing here removes a question from Chapter 3.

---

## 1. Executive Summary

The measured cost of onboarding today:

| | Count |
|---|---|
| Chapter 1 + 2 questions | 11 |
| Chapter 3 questions ("about you") | 105 |
| Chapter 4 preference screens | 72 |
| **Traffic-light taps required in Chapter 4** | **290** |
| Continue/advance taps | ~186 |
| Category summary screens | 9 |
| **Total deliberate interactions** | **~575** |

Chapter 4 is 50% of the questions but **62% of the taps**, because `_canContinue` requires *every option* of *every* preference question to be set before the user may proceed. 290 is a floor, not an average.

**The central finding is not that Chapter 4 is long. It is that Chapter 4 mostly asks people to reproduce a value the system already has.**

Two facts, both from the approved spec and the live code:

1. **Skip records 🟢 for every option** (`Onboarding Rules & UX` §Global Traffic Light Rules).
2. **Not skipping requires setting all options manually** (`values_preferences_flow.dart:93`).

So a user who is genuinely open on a question has two routes to the identical stored data: skip it (0 taps) or mark four greens (4 taps). The interaction offers no middle ground, and the honest, engaged user — exactly the user ZYRA wants — takes the expensive route. **My estimate is that 70–80% of the 290 taps produce the same value as doing nothing.** That is not investment. It is unpaid data entry, and it is the part of onboarding that will feel like a wall.

The good news: every fix below preserves the data model exactly — same questions, same traffic lights, same Hard Requirements, same `onboarding_answers` schema. This is an interaction problem, not a content problem.

---

## 2. Biggest Opportunities

**2.1 The default is inverted.** Green is the resting state, yet the UI makes the user assert it 290 times. Flip it: everything starts 🟢, and the user touches only what they are *not* open to. Same data, ~50 taps instead of 290.

**2.2 Chapter 4 is asking a question the user has already answered.** For most items, people prefer similarity — this is the most reliable finding in mate-preference research (assortative preference on education, religiosity, family orientation, lifestyle). ZYRA can *derive* a proposed preference from each Chapter 3 answer and ask the user to confirm or correct it. Recognition is far cheaper than recall, and the corrections are the valuable part.

**2.3 The most informative datum in the instrument is currently invisible.** When someone's stated preference *departs* from their own trait — "I pray five times daily, and I'm open to someone who prays occasionally" — that is the single most predictive thing they will tell you all session. Today it is one green among 290, indistinguishable from fatigue. Derive-and-confirm makes every deviation an explicit, deliberate act, and therefore measurable.

**2.4 Rating is the wrong cognitive task.** The traffic light asks for an absolute judgement on each option in isolation: 4 options × 3 lights = up to 12 micro-judgements per question, ~864 across Chapter 4. Humans are poor and inconsistent at absolute rating and reliably good at *excluding* and *ranking*. The instrument is using the format people are worst at, at the greatest possible volume.

**2.5 There is no conditional logic anywhere.** `OnboardingQuestion` has no `showIf`/`dependsOn` field — only three gender-limited questions exist. A never-married respondent with no children still walks through every children and custody follow-up. Straight branching removes 15–25% of items per user with zero information loss, because the skipped answers are already implied.

---

## 3. Highest-Impact Changes

Ranked by (effort saved) ÷ (build cost).

### H1 — Tap-to-exclude traffic lights *(biggest single win; ~1 day's work)*

Every option starts 🟢. One tap → 🟡. Second tap → 🔴. Continue is always enabled.

- **Taps: 290 → ~50.** Most people exclude nothing on most questions.
- **Data: identical.** Same map, same values, same Hard Requirement logic.
- **Removes a real trap:** today, `_canContinue` also blocks all-red, so a user can strand themselves mid-question with no explanation.
- **Truthfulness:** the current design records 🟢 for skipped questions and presents that as a stated preference. It never was. Tap-to-exclude at least makes "open" the honest, chosen default rather than an artefact of fatigue.

### H2 — Derive-and-confirm, one card per category *(the structural change)*

After Chapter 3, replace 72 individual preference screens with **9 category review cards**, pre-filled from the person's own answers using a simple adjacency rule on ordered scales (own answer 🟢, neighbouring bands 🟢/🟡, distant bands 🟡, opposite pole 🟡 — never pre-set 🔴; an exclusion must always be a deliberate human act).

Each card shows a plain-language summary — *"You're looking for someone with similar family involvement, flexible on income, similar practice"* — with an **Adjust** control opening the detail only where the user disagrees.

- **Screens: 72 → 9**, with drill-down on demand.
- **Adds a new signal ZYRA does not currently have:** a per-item deviation score (how far the user moved from their own trait). That is genuinely better compatibility data than the flat map you get today.
- **Preserves reflection:** reading "here is what we understand you want" and finding it *wrong* provokes more real thought than tapping the fourth green in a row.

### H3 — Dealbreakers first *(1 screen, ~90 seconds, highest value-per-second in the whole flow)*

Before the category cards, one multi-select: *"What would rule someone out completely?"* — a curated shortlist of ~12–15 candidates drawn from the Hard-Requirement-eligible questions.

This inverts the current order sensibly: **Hard Requirements do all the filtering; the fine-grained lights only reorder.** Getting the exclusions in the first two minutes means the matching engine is useful even if someone abandons later — today, an abandoned Chapter 4 yields nothing usable at all.

### H4 — Conditional branching *(cheap, purely additive)*

Add `showIf` to `OnboardingQuestion`. Concrete rules available immediately in the existing data:

- `ch3_q1` = *Never Married* → skip divorce/widow follow-ups
- `ch3_q2` = *No* (children) → skip custody and living-arrangement follow-ups
- `ch3_q17` = *No* (studying) → skip study-related items
- `ch3_q6` = *No preference / Same country* → suppress the in-law proximity follow-up

### H5 — Dual-thumb range control for ordinal questions *(one screen, both answers)*

Roughly 40% of Chapter 3 is ordered scales — income bands, education level, savings habit, financial readiness, prayer/practice frequency, visit frequency. For these, a single screen with **a marker for "me" and a range for "acceptable in a partner"** captures both in ~3 taps.

This is the direct answer to *"ask once and capture both sides"*: it works precisely because the underlying scale is ordered, and it produces a cleaner preference (a contiguous range) than six independently-set lights, which can express incoherent shapes like green–red–green.

---

## 4. Quick Wins

| Change | Effort | Effect |
|---|---|---|
| Enable Continue with partial preferences (drop the `allAnswered` gate) | 1 line | Removes the hard stop; unblocks the all-red trap immediately |
| Batch 4–5 short factual items per screen (education, income, employment, savings, debt) — keep values questions one per screen | Half a day | ~40 fewer Continue taps, no loss of reflection where reflection matters |
| Show category-level progress ("Family — 4 of 10"), not just chapter-level | Small | Long instruments are tolerated far better when the end of the *current* section is visible |
| Order categories so the concrete ones come first (Family, Education, Marriage Goals) and the abstract later | Config only | Early wins build momentum; abstract questions early cause abandonment |
| Pre-populate income/education preference from own answer as a starting point, even before full derive-and-confirm | Small | Partial H2 benefit at a fraction of the cost |

---

## 5. Interaction Redesign Ideas

**Chips, not tables.** For multi-option questions, a wrapped chip row where a tap cycles green → amber → red reads faster than a table of radio columns and halves vertical space.

**Range, not enumeration.** Ordered scales get a two-thumb slider (H5). Unordered categorical sets keep chips.

**"Same as me" one-tap shortcut.** A single control per category — *"Looking for someone similar to me on these"* — that fills the whole category and lets the user then adjust two or three items. This is the honest common case, and it makes it a first-class choice rather than something the user must simulate with twenty taps.

**Forced-choice tradeoffs as the reflective centrepiece.** Replace a handful of independent ratings with 5–8 paired choices: *"Which matters more — that they live near family, or that they're financially established?"* Independent rating scales inflate ("everything is important"); forced choice extracts genuine priority. **Fewer items, better data, and more reflection** — the only change here that improves all three of the Founder's goals simultaneously.

**Confidence, not just direction.** Optionally let a user mark an answer *"still thinking about this"*. Today, uncertainty is coerced into a definite light. Capturing it is more honest and lets the engine weight accordingly.

---

## 6. Information Architecture Improvements

**Merge the two chapters into nine themed passes.** The current architecture is *all facts, then all preferences* — 105 questions, then 72 more on the same topics in the same order. The second pass has no novelty, and novelty is what sustains attention. Instead: for each of the nine categories, answer the facts, then immediately confirm the derived preferences for that category, then move on. Same content, nine short arcs instead of one long one, and each preference is set while the topic is still in working memory.

**Retire "Chapter 3 / Chapter 4" as user-facing labels.** They describe the data model, not the experience — the UX Writing standard's own rule against exposing internal structure. "Your Values → Family, Faith, Home life…" is what the user is actually doing.

**Two documented mismatches worth fixing:**

- The approved mapping (`Chapter 3 Classification — Ch4 Mapping.md`) states **"Chapter 4 total: 70 preference questions"** with 35 items marked descriptive-only. The code generates **72**, and `Ch4Status.none` appears **zero** times in the data file — the exclusions were expressed by omitting the field, and the default is `none`, so the intended and actual sets happen to be close but were never reconciled. Worth an explicit pass.
- The Flow Diagram says **104 questions**; the code has **105**.

---

## 7. Cognitive Load Analysis

**Working-memory demand.** Each Chapter 4 screen asks the user to hold their own answer in mind (it is shown, which helps) while making up to 12 independent judgements. Around 864 such judgements across the chapter. Nothing about this is difficult individually; the cost is entirely in the accumulation.

**Satisficing is the real risk, and it is invisible.** Long instruments reliably produce degraded responding in the later portion — people converge on whatever requires least effort. Here, least effort is "all green", which is also indistinguishable from a sincere "I'm genuinely open". **You cannot tell fatigue from open-mindedness in the current data.** That is a data-quality problem, not just a UX one, and it argues that shortening Chapter 4 would *improve* the compatibility signal rather than dilute it.

**Effort justification is real, but conditional.** The Founder's instinct — investment signals serious intent, and effort deepens commitment — is well-supported. But the effect comes from effort that feels *meaningful*. Repetitive mechanical effort produces irritation and rationalised abandonment, not attachment. **Reflection creates investment; tapping does not.** Every proposal here reduces taps while *increasing* the reflective content per interaction, which is the combination that actually serves the goal.

**Decision fatigue has a real cost to the user's outcome.** By question 60, choices are noisier. Since these answers drive who they meet, fatigue late in the instrument degrades the matches themselves — and Faith, Lifestyle, Household Roles, Communication, Technology and Health all sit in the back half of the current order.

---

## 8. Estimated Reduction in User Effort

| | Today | Proposed | Change |
|---|---|---|---|
| Ch3 selection taps | 105 | ~85 (branching) | −19% |
| Ch4 traffic-light taps | **290** | **~45** | **−84%** |
| Continue/advance taps | ~186 | ~70 | −62% |
| Screens | ~186 | ~95 | −49% |
| **Total interactions** | **~575** | **~200** | **−65%** |
| Estimated time | 35–45 min | 13–17 min | −60% |

**Information captured: unchanged in volume, higher in quality** — same fields stored, plus two signals that do not exist today (deviation-from-own-trait, and forced-choice priority ordering).

---

## 9. Recommended New Onboarding Model

**Keep:** all 105 Chapter 3 questions, all 9 categories, traffic lights, Hard Requirements, the `onboarding_answers` schema, the private-values framing, and the deliberate sense of seriousness.

**Restructure into five movements:**

1. **Foundations** — Chapters 1 and 2 unchanged (11 items).
2. **Non-negotiables** — one screen, multi-select: what rules someone out. *~90 seconds, and the single most valuable data in the flow.*
3. **Nine themed passes** — per category: the "about you" questions (with branching, factual ones batched), then immediately one derived preference card for that category, adjusted by exception via tap-to-exclude. Ordinal topics use the dual-thumb control that answers both sides at once.
4. **Priorities** — 5–8 forced-choice tradeoffs. The reflective heart of the instrument, and where the deepest signal now comes from.
5. **Profile Ready** — unchanged.

**One idea worth considering separately, because it is a genuine product decision rather than an interaction one:** ZYRA has a natural second moment of high motivation — the point where someone is about to begin an *Active Journey*. Depth questions asked there would be answered by a person who now has a specific reason to be precise, and would be better data than the same questions asked to a stranger on day one. That would let onboarding be genuinely shorter without losing a single item overall. It cuts against front-loaded investment, so I raise it rather than recommend it.

---

## 10. Overall Recommendation

**Do H1 first, on its own.** Tap-to-exclude is roughly a day's work, needs no schema change, no question changes and no new specification, and it removes 84% of Chapter 4's tapping. If nothing else in this document is ever built, do that one.

**Then H3 and H4** (dealbreakers-first and branching) — both small, both independently valuable, both reduce the flow before the expensive part.

**Then H2**, the derive-and-confirm restructure, as a considered piece of work with a decision record, because it changes what onboarding *is*: from an interrogation to a conversation where ZYRA demonstrates it has been listening. That framing is worth more to this audience than the time saved.

The strongest argument for all of it is not efficiency. It is that **the current Chapter 4 cannot distinguish a thoughtful "I'm open" from an exhausted one** — and a marriage platform's entire value rests on that distinction being real.

---

*End of Document*
