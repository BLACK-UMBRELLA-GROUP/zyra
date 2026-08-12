# ZYRA — Onboarding Redesign: Direction Options

**Document:** ZYRA_ONBOARDING_DIRECTION_OPTIONS_2026-08-10.md
**Status:** **DECIDED 2026-08-10 — Direction B. Stage 1 built and verified.**
**Date:** 2026-08-10
**Author:** Claude (Opus), Implementation Lead
**Prompted by:** `CLAUDE.md` §Open, and NOT yours to close — *"Onboarding redesign direction. Scoring-engine work is ON HOLD pending it."*

**Method:** the six-layer read (schema · RLS · RPC bodies · triggers · client · docs), plus a
dependency trace on every reader of `ch4_preferences` and `ch4_hard_requirements`. All counts
below are parsed from `chapter3_categories.dart` and `score_candidates()` was read out of the
live database on 2026-08-10. Nothing here is taken from a document.

**Companion documents:** `ZYRA_ONBOARDING_UX_REVIEW_2026-08-05_V1.md` (Fable — the H1–H5
proposals this paper prices), `ZYRA_ONBOARDING_PERSISTENCE_AUDIT_CURRENT_VERSION_V1.md`,
`ZYRA_CHAPTER2_QUESTION_REVIEW_CURRENT_VERSION_V1.md`.

---

## 0a. Founder decisions — taken 2026-08-10

| # | Decision | Answer |
|---|---|---|
| 1 | Direction | **B** — A plus the per-option reshape |
| 2 | Lift the scoring-engine hold now? | **Yes** — lifted in `CLAUDE.md` |
| 3 | Reshape Hard Requirements this week? | **Yes** — done, same day |
| 4 | Under tap-to-exclude, is 🟢 an answer on an unseen screen? | **No** — only shown screens are written |
| 5 | Fix the miscounted numbers in the classification doc? | **Yes** — done |

**Built the same day:** migration
`20260810154645_onboarding_b_stage1_hard_requirements_become_per_option`,
22/22 verified, plus the four client files. **Still to build under Direction B:**
H1 tap-to-exclude, H4 `showIf` branching, the quick wins.

**Raised while building, all in the register:** OA-ZYRA-185 (Chapter 2 sect
parity — the shared widget now carries an explicit `HardRequirementScope`),
OA-ZYRA-186 (`anon` SELECT on 29 tables), OA-ZYRA-187 (the guard suite could
not run for two days — fixed, both suites green).

**One correction to §3.3 of this paper, found on closer inspection:** the
classification doc's stated `REQUIRED: 30` was right; it was `OPTIONAL: 40`
(→41), `NONE: 34` (→33) and the total `70` (→71) that were wrong, along with
three category headers. Every one of the 104 per-question classifications
agreed with the code.

---

## 0. Recommendation in one line

**Take Direction B, and lift the scoring-engine hold today** — because the only proposal that
touches the schema is the one currently filed as "small, do it early", and it is free this week
and never free again.

---

## 1. The headline — the hold is on the wrong item

`CLAUDE.md` holds the scoring engine because *"H2 would change the shape of `ch4_preferences`,
which `score_candidates()` reads."*

Traced through all six layers, that is not correct. H2 changes what the **screen** does; it
writes the same `{question → {option → light}}` map the engine already reads. The proposal that
actually moves the schema is **H3**, and H3 moves `ch4_hard_requirements`, not `ch4_preferences`.

| Fable's proposal | `ch4_preferences` | `ch4_hard_requirements` | `score_candidates()` | Verdict |
|---|---|---|---|---|
| **H1** Tap-to-exclude | unchanged *(see §3.1)* | unchanged | no change | **Safe** |
| **H2** Derive-and-confirm | **unchanged** — same map, pre-filled | unchanged | no change | **Safe** |
| **H3** Dealbreakers first | unchanged | **CHANGES — needs per-option** | ~10 lines | **The only schema item** |
| **H4** Conditional branching | fewer keys, same shape | unchanged | already handles absence | **Safe** |
| **H5** Dual-thumb range | narrower, same shape | unchanged | no change | **Safe** |

Evidence for the H4 row, since it is the one that looks risky and isn't: `score_candidates()`
does `IF v_answer IS NULL ... CONTINUE`. A branch-skipped question contributes nothing to either
the numerator or the denominator. Absence is already neutral, not penalised — the engine was
built correctly for branching before branching was proposed.

Evidence for the H2 row: the deviation-from-own-trait signal H2 generates is *additive*. It
belongs in a new sibling key (`ch4_derived`), not inside `ch4_preferences`. Nothing the engine
reads today changes shape.

**Consequence:** four of the five proposals can be built without the engine waiting, and the
engine can start without the onboarding direction being finally settled. The hold as written is
costing more than it protects.

---

## 2. What onboarding actually costs — counted

Parsed from the live data file, per gender, because three questions are gender-conditional.

| | Male | Female |
|---|---:|---:|
| Chapter 3 question screens | 104 | 103 |
| Chapter 4 preference screens | 71 | 70 |
| Category summary screens | 18 | 18 |
| **Chapter 4 traffic-light taps — minimum** | **325** | **320** |
| Continue / advance taps | 175 | 173 |
| **Total deliberate interactions (Ch3 + Ch4)** | **518** | **511** |

Chapter 1 (3 screens) and Chapter 2 (21 screens) sit on top of this.

Two notes on the numbers, both of which matter for how much weight to put on the review:

- The UX review's headline figure of **290** Chapter 4 taps is **12% low**. The counted figure is
  325 (male) / 320 (female). The direction of the review's argument is unaffected; the magnitude
  is worse than stated.
- 325 is a **hard floor, not an average**. `values_preferences_flow.dart:93` requires every option
  of every question to be set before Continue enables. There is no cheaper path — see §3.1.

---

## 3. Three things found while tracing

### 3.1 The Skip that the spec relies on does not exist

`Onboarding Rules & UX.md` §Global Traffic Light Rules specifies:

> *Skip behaviour — If the user selects Skip: Record 🟢 (No Preference) automatically.*

`traffic_light_question_screen.dart` names it in a header comment and **never renders it.** There
is no Skip control anywhere in Chapter 4. The only `Skip` in onboarding is on the Article 9
consent screen and the Chapter 2 pickers.

This changes the review's central argument. Fable framed it as *"two routes to identical data:
skip it (0 taps) or mark four greens (4 taps), and the honest user takes the expensive route."*
There is no 0-tap route. **325 taps is mandatory**, and a user who is genuinely open on every
question has no way to say so except 325 times.

That makes H1 more valuable than the review claims, and it means the fix is not "make skip
discoverable" — it is "build the resting state the spec always intended".

**Design rule this creates, and it is not optional:** under tap-to-exclude, a question's lights
must be written **only once its screen has been shown.** Pre-seeding all 71 questions as green on
entry to Chapter 4 would manufacture a complete set of stated preferences from someone who
answered three — precisely the truthfulness failure the review objects to today, but larger.

### 3.2 A Hard Requirement is per-question, and fires on **any** red

From the live function:

```
IF v_light = 'red' AND COALESCE((v_my_hard ->> v_question)::boolean, FALSE)
THEN v_excluded := TRUE;
```

`ch4_hard_requirements` is `{question_id: bool}`. The client agrees — `_ch4HardRequirement[q.id]`
is one bool per question, and the checkbox appears once *any* option is red.

So on Q1 (Marriage Status: Never Married / Separated / Divorced / Annulled / Widowed / Currently
Married), a Seeker **cannot** express:

> *Currently Married — never. Divorced — I'd rather not, but I'd consider the right person.*

Ticking the box excludes both. Untucking it excludes neither. There is no third position, and the
UI gives no hint that the box reaches further than the option the user was looking at.

**This is not broken today** — `onboarding_answers` has zero rows and no user has ever completed
Chapter 4. It becomes live the day H3 ships, because "what would rule someone out completely?" is
inherently a question about **options**, not topics.

### 3.3 Both "documented mismatches" in the review dissolve

The review flagged two spec-vs-code discrepancies as needing "an explicit pass". Both are
resolved, in the code's favour, at no cost:

| Flagged | Reality |
|---|---|
| *"Spec says 104 Chapter 3 questions, code has 105"* | 105 constructor blocks, **104 unique IDs**. `ch3_q26` (Views on Polygamy) is defined twice with different option lists for men and women; only one is ever visible. **Spec and code agree.** |
| *"Spec says 70 Chapter 4, code generates 72"* | The classification doc's own item list contains **71** questions. Its category headers (Education 8, Faith 13, Technology 2) and its stated total (70) are miscounted; the listed items match the code exactly. **Code is right; four numbers in the doc are wrong.** |

Correcting four numbers in `Chapter 3 Classification — Ch4 Mapping.md` closes this. No code change.

---

## 4. The three directions

### Direction A — Interaction only

**H1 tap-to-exclude · H4 branching · the cheap quick wins** (batch the factual items, category-level
progress, reorder categories concrete-first).

| | |
|---|---|
| Schema change | **None** |
| Engine impact | **None** — hold lifts immediately |
| Effort | ~2–3 days |
| Ch4 taps | 325 → est. 40–60 *(estimate, not a count — depends on real exclusion rates)* |
| Ch3 screens | 104 → est. 80–90 |
| You do **not** get | Dealbreakers-first, the deviation signal, forced-choice priorities |

### Direction B — A, plus reshape the Hard Requirement *(recommended)*

Everything in A, and one migration: `ch4_hard_requirements` becomes per-option.

```
before   {"ch3_q1": true}
after    {"ch3_q1": {"Currently Married": true, "Divorced": false}}
```

| | |
|---|---|
| Schema change | One `jsonb` reshape + ~10 lines in `score_candidates()` |
| Data migration | **Zero rows.** Nothing to backfill |
| Engine impact | One function edit, then the hold lifts |
| Effort | A + ~1 day |
| Unlocks | **H3 dealbreakers-first** — buildable any time after, with no further schema work |

**Why the timing matters, and why this is the only time-sensitive item in the paper.** Today the
reshape is a `jsonb` default change against an empty table. Once real users complete Chapter 4, it
is a backfill that **cannot be done correctly**: from `{"ch3_q1": true}` there is no way to recover
*which* red option the person meant to exclude, so every multi-red hard requirement would have to
be either widened (excluding people they wanted to see) or dropped (showing people they said never).
Neither is acceptable, and no amount of later effort recovers the information.

This is the same zero-row window that made the OA-159 constraint work free on 2026-08-10. It closes
at first real signup.

### Direction C — B, plus derive-and-confirm as a governed piece

Everything in B, and H2: nine category review cards pre-filled from the person's own Chapter 3
answers, adjusted by exception, with the deviation score stored in a new `ch4_derived` key.

| | |
|---|---|
| Schema change | B's reshape, plus one **additive** column/key. `ch4_preferences` still unchanged |
| Engine impact | None until you choose to *score* deviation — that is a separate decision |
| Effort | B + ~1 week, and it needs its own spec and a DR |
| Gains | 71 preference screens → 9 cards; a compatibility signal that does not exist today |
| Risk | It changes what onboarding *is*. Not a change to make between other things |

---

## 5. Recommendation

**Direction B now. C later, on its own, with a decision record.**

Three reasons, in order of weight:

1. **The hard-requirement reshape is free this week and never free again.** Everything else in
   this paper can be done in any order, at any time, at the same cost. This one cannot.
2. **The engine hold is not buying anything.** Four of five proposals leave `ch4_preferences`
   untouched. Holding scoring work behind a decision that does not affect it has cost days
   already.
3. **H1 alone removes ~85% of Chapter 4's tapping for one day's work**, and §3.1 shows the
   situation it fixes is worse than the review documented — there is no escape hatch at all today.

**Not recommended yet, and deliberately:** H5 (dual-thumb ranges) and the forced-choice priorities
screen. Both are good ideas. Both are new question *formats*, which means new specs, new copy, and
a second pass over the classification doc. Neither is time-sensitive. They belong after real users
have walked the flow once.

**Explicitly out of scope of this paper:** the Chapter 2 question review (`21 screens → 12`) and
the `seeker_details` reference-list blocker. Those are settled separately and are not held by this
decision.

---

## 6. Decisions I need from you

| # | Decision | Options | Blocks |
|---|---|---|---|
| **1** | Direction | **A** / **B** / **C** / none yet | Everything below |
| **2** | Lift the scoring-engine hold now? | Yes / keep held | `score_candidates()` work, Profile Unlock, Compatibility Reveal |
| **3** | If B or C — reshape Hard Requirements this week? | Yes / accept it becomes permanent | H3 forever |
| **4** | Under tap-to-exclude, is 🟢 an *answer*? | Yes, an unseen screen still counts as open / **No, only shown screens are written** *(§3.1 rule)* | What a half-finished Chapter 4 means to the engine |
| **5** | Fix the four miscounted numbers in the classification doc? | Yes / leave | Nothing — it is free (§3.3) |

Decision 4 is the one that looks smallest and is not. It decides whether an abandoned Chapter 4
produces silence or a fabricated set of preferences, and the engine cannot tell those apart after
the fact.

---

## 7. Assumptions, risks and dependencies

**Assumptions**

- `onboarding_answers` stays at zero rows until the reshape lands. Verified 2026-08-10; true only
  while there are no real signups.
- Fable's "most people exclude nothing on most questions" holds for this audience. Untested — the
  40–60 tap figure in Direction A is an estimate and is labelled as one. Everything else in this
  paper is counted.
- H2's adjacency rule (own answer green, neighbours green/yellow, distant yellow, **never**
  pre-set red) is accepted as-is. An exclusion staying a deliberate human act is the part of H2
  that must not be traded away for tidiness.

**Risks**

| Risk | Mitigation |
|---|---|
| The reshape window closes at first real signup | Do it before launch, or accept H3 is lost |
| H1 makes abandonment cheaper as well as completion cheaper | Decision 4 — write only what was shown |
| H2 changes the product, not just the screen | Give it its own DR; do not fold it into B |
| Deviation scoring could be worse than the flat map | It is stored, not scored, until proven on real data |

**Dependencies**

- `v_ch2_weight = 1` stays open regardless of this decision. It waits on the 120-profile backfill,
  which is not engine work and is not held by anything here.
- The Article 9 solicitor question (sect, revert status, ethnicity) is untouched by all three
  directions and remains open.
- The Chapter 2 reference-list blocker gates `seeker_details`, not this.

---

## 8. What was verified, and how

| Claim | Evidence |
|---|---|
| 104 unique Ch3 questions, 105 definitions | Balanced-paren parse of `chapter3_categories.dart`; `ch3_q26` duplicated by gender |
| 71 Ch4 screens (male) / 70 (female) | Same parse, filtered by `GenderVisibility` |
| 325 / 320 minimum Ch4 taps | Sum of option counts across visible Ch4 questions |
| Hard requirement is per-question | `score_candidates()` read from the live DB; `_ch4HardRequirement[q.id]` in the client |
| No Skip control exists | Full grep of `SOURCE/lib/screens/onboarding/` |
| Absent answers are neutral, not penalised | `IF v_answer IS NULL ... CONTINUE` in the live function |
| `onboarding_answers` shape and defaults | `information_schema.columns`, live, 2026-08-10 |
| Classification doc headers miscounted | Parsed the doc's own item list and compared to its headers |
| Only `score_candidates()` reads these keys | Every `public` function scanned: `score_candidates()` is the sole reader; `zyra_reset_profile()` touches the table but not these keys. In Dart, `ZyraOnboardingAnswersService` writes and **nothing reads** |

---

*End of Document*
