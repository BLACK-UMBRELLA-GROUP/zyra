# While you were away

Four things. One is a correction to what I told you earlier today. One needs a decision. Two are finished documents.

---

## 0 · First, a correction

Earlier today I wrote that the two polygamy option lists "don't overlap by a single character, so the lookup never matches, **in either direction**."

**That is right for women and wrong for men.** Both lists contain `"I'm unsure"`.

| | |
|---|---|
| Woman → man | 0 of her 4 keys match. Contributes nothing. *(as I said)* |
| Man → woman | 1 key matches — `"I'm unsure"`. **It scores.** |

6 women answered "I'm unsure". All 72 men hold a light for it (57 yellow, 9 red, 6 green). So **432 pairs are currently scored** on a man's rating of *his own* uncertainty about taking more than one wife, applied as a judgement of *her* uncertainty about being an additional wife.

Two different questions that happen to share a label. For women the bug is a missing signal; for men it's a **wrong** one.

Doesn't change the decision you need to make. Does mean clearing those 144 rows is a correctness fix, not tidying. OA-226 is updated.

**Also extended:** hard requirements use the identical lookup. All 21 in the database sit on gender-neutral questions so nothing is broken today — but a hard requirement on a gendered question would **silently never fire**. A dealbreaker that does nothing is worse than a score that counts nothing.

---

## 1 · The big one: the score can't tell people apart

I re-implemented `score_candidates` in SQL and ran it over **all 10,257 possible pairs**.

| | |
|---|---|
| Lowest score **anyone** gets | **64.3** |
| Highest score **anyone** gets | **86.6** |
| Pairs between 70 and 82 | **93.5%** |
| Standard deviation | 3.25 |

That's the whole range. Everyone is a 76.

### The cause is arithmetic, not preferences

Same method, fewer questions:

| Questions | Range | SD |
|---|---|---|
| 5 | 20–100 | 12.62 |
| 10 | 40–100 | 8.73 |
| 20 | 50–97 | 6.20 |
| 40 | 58–90 | 4.50 |
| **~70 (today)** | **64–87** | **3.25** |

SD × √(questions) = 28.2, 27.6, 27.7, 28.5, 27.2. That's 1/√n exactly.

> **Every question you add to Chapter 3 makes the score worse at telling people apart.** Question 71 doesn't add nuance — it divides the signal by a bigger number.

### Where it bites

**The paid figure.** Compatibility Unlock renders the real score at 44pt after a credit. Best match averages 82.9; #5 is 2.4 lower, #10 is 3.5 lower, #20 is 5 lower. Five unlocks, five credits: 83, 82, 82, 81, 81.

**Deck order.** 2,354 groups of candidates hold an *identical* score, averaging 3.7 people each. Ties break through a comparator returning 0, and Dart's sort isn't documented as stable — so three or four people at every level are ordered by nothing.

### Your call — OA-227

| | | |
|---|---|---|
| **A** | **Score on 15–25 questions.** Keep the rest as profile content. | SD ~6–7, range ~45pts. Needs your editorial judgement on which matter |
| **B** | **Weight questions** instead of counting them | Same judgement + schema change |
| **C** | **Stop showing a percentage.** Bands, or the green/amber/red tallies | Worth doing whatever you pick for the engine |
| **D** | Stretch the scale for display | **Don't.** Manufactures difference that isn't there |

**Sequence: fix OA-226 first**, clear the stale rows, re-measure, then choose. Every number above was measured with those two questions contributing nothing.

**Honest limit:** the 144 Seekers are seeded. The 1/√n law is arithmetic and holds regardless; the constant is measured from generated data. Real preferences correlate, which would widen it somewhat — the mechanism doesn't change, the size might.

---

## 2 · OA-193(e) is answered — the Chapter 2 weight is the wrong lever

| Ch2 weight | Range | SD |
|---|---|---|
| **1 (today)** | 64.9–87.2 | 3.17 |
| 5 | 61.6–89.0 | 3.61 |
| **20** | 51.9–92.7 | **6.57** |

Weighting Chapter 2 at **twenty times** each Chapter 3 question — over half the whole score — still spreads less than simply scoring **20** Chapter 3 questions.

Pick a weight for editorial reasons (sect and language *should* matter more than a lifestyle question). Don't expect it to fix anything, and don't set it before the question count is settled — every number moves when that changes.

**Also worth knowing:** on 2026-08-11 someone recorded "no pair in the seeded population is all-green" as reassurance. It's the same effect seen from the other side. Nobody scores 100 for the same reason nobody scores 40.

---

## 3 · The Notification Specification is written — OA-146 closed

It had been parked pending the ZYRA One tiering discussion. That discussion has since **ratified** the Journey portion (OA-161, 2026-08-06), so the spec reproduces that map rather than re-deriving it.

**One live bug found writing it — OA-231.** `create_notification()` is one unconditional INSERT. It never reads `notification_preferences`. So all ten callers write regardless, and **your Settings toggles gate nothing.**

Bounded today — nothing maps to the marketing/product-updates categories, so no consent is being breached. But Matches & Journeys and Guardian Activity are visible in Settings, persisted append-only for evidential reasons, and ignored. A switch that does nothing is worse than an absent one, because the user believes they've acted.

**One question I couldn't answer for you (§10 D5):** do ZYRA One and Basic differ in *what they're notified about*? The spec assumes **not** — a notification is information about your own account, and rationing it by tier makes the paid tier better informed about their own life. Everything else in the document survives either answer; the event tables don't.

---

## 4 · What's waiting on you

| # | | |
|---|---|---|
| 1 | **OA-226** | Invert Chapter 4's gender gate, or exclude gendered questions? |
| 2 | **OA-227** | A, B or C above |
| 3 | **OA-146 D5** | Do notification events differ by tier? |
| 4 | Still open | OA-221, OA-213, OA-217, OA-219 |

Everything else I found is registered and needs nothing from you: **OA-228** (multi-select answers let the *candidate* set the score's denominator — latent, invisible in seed data), **OA-229** (`initcap(sect)` is the only thing joining two casing conventions neither side states), **OA-230** (the green/amber/red tallies could be real today without waiting on the category decision).

---

## Nothing was committed

No Dart changed. Three documents written and filed:

- `REPORTS/ZYRA_COMPATIBILITY_ENGINE_AUDIT_2026-08-14.md`
- `SYSTEM/DOCUMENTS/ZYRA_NOTIFICATION_SPECIFICATION_CURRENT_VERSION_V1.md`
- `SYSTEM/DOCUMENTS/ZYRA_TRUTHFUL_FAILURE_DESIGN_2026-08-14.md` *(earlier today)*

Register updated: OA-146 closed · OA-226 corrected and widened · OA-193(e) answered · OA-227 to 231 raised.

The Dart batch from earlier today is **still unverified** and should be your first move back at the Mac:

```
cd "/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE" && flutter analyze
```

Then:

```
cd "/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE" && ./run.sh
```
