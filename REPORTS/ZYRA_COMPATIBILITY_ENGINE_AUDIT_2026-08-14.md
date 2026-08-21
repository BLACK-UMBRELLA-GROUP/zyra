# ZYRA — Compatibility Engine Audit

**Date:** 2026-08-14
**Scope:** `score_candidates()` · `zyra_light_weight()` · Chapter 2 preference blocks · the three client consumers
**Method:** the two SECURITY DEFINER function bodies read line by line, then their arithmetic re-implemented in plain SQL and run over **all 10,257 viable pairs** in the live database. Every claim below is a measurement, not an inference.
**Nothing was changed.** No Dart, no SQL, no migration. This is a findings document.

---

## The headline

> **The score cannot separate people, and the reason is the number of questions — not anyone's preferences.**

Across every possible pairing in the database:

| | |
|---|---|
| Lowest score anyone gets | **64.3** |
| Highest score anyone gets | **86.6** |
| Mean | 76.1 |
| Standard deviation | **3.25** |
| Pairs scoring between 70 and 82 | **9,597 of 10,257 — 93.5%** |
| Pairs rounding to exactly 76 | 1,296 |

A typical Seeker's whole deck of 71 candidates spans **13.8 points**. The narrowest deck in the database spans 9.5.

---

## 1 · Why: the score is an average of ~70 things, and averages concentrate

The same scoring method, run on progressively fewer questions:

| Questions averaged | Lowest | Highest | Range | SD | % of pairs in 70–82 |
|---|---|---|---|---|---|
| 5 | 20.0 | 100.0 | 80.0 | **12.62** | 57.2% |
| 10 | 40.0 | 100.0 | 60.0 | **8.73** | 61.2% |
| 20 | 50.0 | 97.4 | 47.4 | **6.20** | 67.8% |
| 40 | 57.7 | 89.5 | 31.8 | **4.50** | 78.7% |
| ~70 (today) | 64.3 | 86.6 | 22.3 | **3.25** | 93.5% |

Multiply each SD by the square root of its question count: **28.2, 27.6, 27.7, 28.5, 27.2.**

That is 1/√n to three significant figures. The spread is not being produced by how compatible people are. It is being produced by how many questions get averaged, and it shrinks by a factor of √n as questions are added.

**The consequence is counter-intuitive and worth stating plainly: every question added to Chapter 3 makes the compatibility score worse at telling people apart.** Question 71 does not add nuance. It divides the existing signal by a slightly larger number.

**Robustness check.** The subset above is the questions in `qid` order — arbitrary, but not random. Re-run with two entirely different orderings:

| Subset rule | 5 q | 10 q | 20 q | 40 q |
|---|---|---|---|---|
| `qid` ascending | 28.2 | 27.6 | 27.7 | 28.5 |
| `md5(qid)` | 28.0 | 26.9 | 26.0 | 26.5 |
| `qid` descending | 25.8 | 26.0 | 26.2 | 26.6 |

*(each cell is SD × √n)*

The constant sits between 25.8 and 28.5 however the questions are chosen. The relationship is not an artefact of subset selection.

> **This finding is arithmetic, not data.** The 1/√n law holds whatever the answers are. What *is* data-dependent is the constant — σ₁ ≈ 26–28 per question. Real Seekers' preferences will correlate (someone strict on one religious question is usually strict on the next), which raises σ₁ and would widen the spread somewhat. The mechanism does not change; the magnitude might.

---

## 2 · Where a Seeker actually feels it

### 2a · The paid figure

`profile_unlock_screen.dart:742` renders `Text('${score!.round()}%', … size: 44)` — the real score, at 44pt, after a credit is spent.

| | |
|---|---|
| Average score of a Seeker's **best** match | 82.9 |
| Gap from #1 to #5 | **2.35** |
| Gap from #1 to #10 | 3.48 |
| Gap from #1 to #20 | 4.97 |
| Gap from #1 to last in the deck | 12.82 |

Someone unlocking five different profiles pays five credits to see 83, 82, 82, 81, 81.

The screen is otherwise honest — the category breakdown is correctly marked as sample and the doc comment explaining why is one of the better ones in the codebase. The problem is not that the number is fake. It is that the number is real and nearly constant.

### 2b · Deck order

Browse never shows the score; it uses it to sort (`_applyCompatibility`). Within a single deck:

- **2,354 groups of candidates share an identical score**, averaging **3.7 people per group**.
- Ties resolve through `scored.sort()`, whose comparator returns 0 for equal values. Dart's `List.sort` is **not documented as stable**, so the relative order of tied candidates is unspecified and need not be the same on the next fetch.

Roughly three to four people at every score level are ordered by nothing in particular.

---

## 3 · Correction to OA-ZYRA-226 — `ch3_q26` is worse than "contributes nothing"

Yesterday's brief said the two polygamy vocabularies "don't overlap by a single character, so the lookup never matches, in either direction." **That is right for women and wrong for men.**

The observed option strings:

| | |
|---|---|
| **Female** variant | "I would only marry as the only wife" · "I would consider being an additional wife" · "I would consider being a first wife in a future polygamous marriage" · **"I'm unsure"** |
| **Male** variant | "I only wish to have one wife" · "I'm open to more than one wife in the future" · "I already have more than one wife" · **"I'm unsure"** |

`"I'm unsure"` appears in **both** lists. So:

- **Woman → man:** 0 of her 4 preference keys match any male answer. Contributes nothing. *(As briefed.)*
- **Man → woman:** 1 of his 4 keys matches — `"I'm unsure"`. **It scores.**

Measured:

| | |
|---|---|
| Women whose q26 answer is "I'm unsure" | **6** |
| Men holding a light for "I'm unsure" | **72** (57 yellow · 9 red · 6 green) |
| Pairs currently scoring on this key | **432** |

In those 432 pairs, a man's rating of *his own* uncertainty about taking more than one wife is being applied as a judgement of *her* uncertainty about being an additional wife. Two different propositions that happen to share a label.

A silent zero is a missing signal. This is a **wrong** signal, and it only exists in one direction — so it is also asymmetric between men and women.

**OA-226 should be amended to record this.** It does not change the decision being asked (invert the Chapter 4 gate, or exclude gendered questions) — but it does change the clean-up: clearing the stored preferences is now a correctness fix, not just tidying.

---

## 4 · The same defect on the hard-requirement path — latent, not live

`score_candidates` evaluates `ch4_hard_requirements` by the identical string lookup, before scoring, and excludes the candidate outright on a hit.

Every hard requirement in the database today:

| Gender | Question | Excluded option | n |
|---|---|---|---|
| female | ch3_q1 (marital status) | Currently Married | 3 |
| female | ch3_q1 | Widowed | 4 |
| female | ch3_q1 | Never Married | 2 |
| female | ch3_q2 | Yes, living elsewhere | 1 |
| female | ch3_q52 (smoking) | I both smoke and vape | 3 |
| female | ch3_q52 | I'm trying to quit | 1 |
| male | ch3_q1 | Currently Married | 1 |
| male | ch3_q1 | Widowed | 2 |
| male | ch3_q52 | I'm trying to quit | 4 |

All 21 sit on **gender-neutral** questions, so none is currently affected. **All 21 are also marked red in the same person's own preference matrix** — 21 of 21, no exceptions. The exclusion direction is correct and the UI is not inverted. That suspicion is cleared.

But the exposure is real: **a hard requirement stored under a gendered question would silently never fire.** A dealbreaker that does nothing is a worse failure than a score that counts nothing, because the Seeker has been told it is absolute. Whatever is decided on OA-226 must cover `ch4_hard_requirements`, not only `ch4_preferences`.

---

## 5 · Multi-select answers put the denominator in the candidate's hands

```
FOR v_value IN SELECT jsonb_array_elements_text(v_answer) LOOP
  v_light := v_prefs_for_question ->> v_value;
  IF v_light IS NULL THEN CONTINUE; END IF;
  v_max := v_max + 1; …
```

`v_max` grows **once per selected option**, so a multi-select question weighs as much as the candidate chose to select. Two candidates answering the same question are then scored against different denominators.

The bias has a direction: selecting more can only help if *everything* selected is green. Pick one green option and score 100% on that question; pick three greens and a yellow and score 87.5%. **The more expressive candidate is penalised.**

**Not visible today.** Only `ch3_q37` and `ch3_q97` are multi-select, and all 144 profiles selected exactly 2 on each — so the distortion is uniform and cancels. It appears the moment a real user selects 1, or 5.

*Class: latent bug. This is exactly the kind of thing generated seed data hides — every row identical means every denominator identical.*

---

## 6 · OA-ZYRA-193(e) — the Chapter 2 weight, answered with numbers

`v_ch2_weight INT := 1;` carries the comment *"STILL OPEN — OA-ZYRA-193(e), now answerable."* Here is the answer.

| Ch2 weight | Lowest | Highest | SD | Ch2 as % of denominator |
|---|---|---|---|---|
| **1 (today)** | 64.9 | 87.2 | **3.17** | ~5% |
| 3 | 63.8 | 88.1 | 3.29 | ~14% |
| 5 | 61.6 | 89.0 | 3.61 | ~21% |
| 10 | 57.4 | 90.6 | 4.68 | ~35% |
| 20 | 51.9 | 92.7 | **6.57** | ~51% |

Weighting Chapter 2 at **twenty times** each Chapter 3 question — making it over half the entire score — produces less spread than simply scoring **20 Chapter 3 questions** would (SD 6.20).

**The Chapter 2 weight is the wrong lever.** Any value it can take is a small correction to a denominator of ~70. Pick a weight for editorial reasons — sect and language *should* matter more than a lifestyle question — but do not expect it to fix the spread, and do not tune it before the question count is settled, because every number in this table moves when that changes.

*Method note: this replication covers sect, revert status, country of birth, nationality and ethnicity — 2.76 contributing axes per pair on average. It omits the languages block, which would add roughly 0.9 more (133 of 144 Seekers have a usable non-English language preference). Including it would shift the table slightly further in the same direction and changes no conclusion.*

---

## 7 · Smaller findings

### 7a · `initcap(v_cand.sect)` works by coincidence

`seeker_details.sect` stores lowercase (`sunni` 117 · `shia` 15 · `other` 12). The Chapter 2 matrix stores Title Case (`Sunni` · `Shia` · `Other`, all 144 Seekers). One `initcap()` inside a SECURITY DEFINER function is the only thing joining the two.

It holds because all three values are single words. Add a sect written `Ahl-e-Hadith` and `initcap()` yields `Ahl-E-Hadith`, which will not match the matrix key — and, as with everything else here, the miss is silent. The client and the database have agreed on a casing convention that neither states.

### 7b · Two Chapter 2 axes are near-dormant

| Axis | Reason it rarely contributes |
|---|---|
| **revert** | Only scores when the candidate *is* a revert — 9 of 144 Seekers |
| **languages** | The 2026-08-10 English fix filters `p.value <> 'en'`; 11 of 144 have nothing else listed, so the block dies for them |
| country_of_birth | 102 of 144 skipped it |
| nationality | 48 of 144 skipped it |
| ethnicity | 35 of 144 skipped it |

None of these is a bug. They are the reason Chapter 2 contributes 2.76 axes rather than 6, and worth knowing before weighting it.

### 7c · The green/amber/red tallies could be real today

`profile_unlock_screen` shows three tallies plus six category rows, correctly marked as sample. The categories genuinely cannot be computed — `score_candidates` returns no category detail, and OA-193(d) has not settled what the categories are.

**The tallies are different.** The function already walks every matching light; counting greens, yellows and reds costs three integers and one extra `RETURNS TABLE` column. That would make 3 of the 7 figures on a paid screen real without waiting on OA-193(d).

*Class: MODIFY — small, self-contained, no decision needed.*

---

## 8 · Verified correct

Things checked that turned out fine, recorded so they don't get re-checked:

| Check | Result |
|---|---|
| `zyra_light_weight()` vs the ratified OA-193a scale | Exact — green 1.0 · yellow 0.5 · red 0.0 · anything else 0.0 |
| Hard requirements evaluated before, and independently of, the lights | Correct |
| Hard-requirement semantics (exclusion, not preference) | Correct — 21 of 21 also red in the holder's own matrix |
| `v_max = 0` → `score := NULL` | Correct — "cannot say" is not "nothing matched" |
| Client handling of the three outcomes (absent row / NULL / number) | Correct, and well documented at `zyra_discovery_service.dart:212` |
| English-language filter (2026-08-10 fix) | Live |
| `zyra_can_view_profile` gate per candidate | Present |
| Client `sectionFor` vs the live 10-type CHECK constraint | All 10 handled |
| Data symmetry (male vs female answer counts) | 70.7 vs 69.8 — the ~1 difference is `ch3_q39`, male-visibility, as expected |

---

## 9 · What to do — options, not a recommendation

The engine is **correct**. It computes exactly what it was specified to compute. The finding is that the specification produces a number that cannot do the job the product asks of it. That is a design decision, so it is yours.

| # | Option | Effect | Cost |
|---|---|---|---|
| **A** | **Score on fewer questions.** Choose the 15–25 that carry real matrimonial weight; keep the rest for profile content, not scoring. | SD ~6–7, range ~45 points. Restores a score that means something. | Requires deciding which questions matter — an editorial judgement only you can make. |
| **B** | **Weight questions instead of counting them.** Keep all ~70; give each a coefficient. A weighted mean with a few dominant terms spreads far wider than a flat one. | Similar to A without discarding anything. | Same editorial judgement, plus a schema change and a heavier scorer. |
| **C** | **Stop showing a percentage.** Keep the flat score for ordering; replace the 44pt number with bands, or with the green/amber/red tallies from §7c. | Removes the misleading figure without touching the engine. | The paid unlock needs something else to sell. |
| **D** | **Stretch the scale.** Map the observed 64–87 range onto 0–100 for display. | Cosmetic only. | **Recommend against.** It manufactures difference that isn't there, and the mapping goes stale the moment the question set changes. |

A and C are not alternatives — C is worth doing whatever happens to the engine, because a paid figure with a 5-point working range is a product problem before it is a scoring one.

**Sequencing:** OA-226 first. Both broken questions currently contribute nothing (and one contributes wrongly), so every number in this document was measured with them absent. Fix the gender gate, clear the 144 stale preference rows, re-measure, then decide between A/B/C.

---

## 10 · Limits of this audit

- **The data is generated.** 144 seeded Seekers with machine-made preferences. The 1/√n mechanism is arithmetic and holds regardless; the constant σ₁ ≈ 26–28 is measured from this data and would differ with real users — probably upward, since real preferences correlate. Verified stable across three independent question-subset rules (§1).
- **The scoring was re-implemented in SQL, not executed through the function.** `score_candidates` reads `auth.uid()` and cannot be called for an arbitrary viewer from an audit session. The replication follows the function body statement by statement and reproduces its published behaviour; it omits the languages block, noted in §6.
- **No push/notification, RLS, or performance review** was in scope here.
- **Nothing was verified on device.** Every finding above is from source and live data.
