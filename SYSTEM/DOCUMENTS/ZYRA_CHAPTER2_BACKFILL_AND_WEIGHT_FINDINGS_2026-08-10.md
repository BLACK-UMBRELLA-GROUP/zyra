# ZYRA — Chapter 2 Backfill, and What It Says About `v_ch2_weight`

**Document:** ZYRA_CHAPTER2_BACKFILL_AND_WEIGHT_FINDINGS_2026-08-10.md
**Status:** **Backfill APPLIED. Language fix APPLIED. Chapter 3/4 seeded (synthetic, flagged). Weight still OPEN — see §6a.**
**Date:** 2026-08-10
**Author:** Claude (Opus), Implementation Lead
**Commissioned by:** Founder, 2026-08-10 — *"Match the real UK distribution"*

`CLAUDE.md` has held `v_ch2_weight` open since 2026-08-04 with the instruction
**"Bring numbers, not arguments."** These are the numbers.

---

## 0. The finding in one line

**Don't set the weight yet.** One of Chapter 2's six attributes is a constant —
it scores green on **100% of 10,368 measured pairs** — and raising the weight
would amplify it along with everything else.

---

## 1. What was seeded

120 Seekers had no `seeker_details` row at all; 24 did. All 144 now do.
The existing 24 were left untouched.

**Sources.** Census 2021 (England & Wales) for ethnicity and UK-born share.
The census does not ask denomination, so sect comes from the Techne survey
commissioned by the Institute for the Impact of Faith in Life.

| Attribute | Target | Seeded (the 120) |
|---|---|---|
| Sunni | 83.8% | **84.2%** (101) |
| Shia | 7.5% | **7.5%** (9) |
| Other / non-denominational | 8.7% | **8.3%** (10) |
| Pakistani | ~33% | 34.2% |
| Bangladeshi | ~17% | 17.5% |
| Indian | ~8% | 8.3% |
| Black (Somali + other African) | 10.8% | 10.8% |
| Arab + North African | 7.2% | 7.5% |
| White / European | 5.9% | 5.8% |
| Mixed heritage | 3.7% | 3.3% |
| Born in the UK | 51% | 54.2% *(all 144)* |

**Sect is correlated with heritage, not sprinkled at random.** Every Persian
Seeker is Shia; Arabs are mixed; Bangladeshis are almost entirely Sunni. A flat
84/7.5/8.7 scattered across ethnicities would have produced test data that
agrees with itself and measures nothing.

Storage follows the `zyra_reference_data.dart` rule — **codes, never labels**:
ISO 3166-1 alpha-2 countries, ISO 639-1 languages, ZYRA ethnicity codes. Every
value was checked against the reference lists before insert; all valid.

---

## 2. Chapter 2 measured in isolation

`onboarding_answers` is still empty, so every point below comes from Chapter 2
alone — a clean isolation test.

40 viewers, ~72 candidates each:

| | |
|---|---|
| Mean score | **96.0** |
| Range | 58.3 – 100 |
| Mean spread within one viewer's pool | **11.4 points** |
| Sect hard requirement, when set | excludes **22.3%** of the pool |
| Viewers without one | exclude nobody |

**Chapter 2 barely separates anyone.** Almost every candidate lands in a
four-point band near the top. The hard requirement, by contrast, does real
work — but that is an exclusion, and **no weight applies to an exclusion.**

---

## 3. Why — measured over 10,368 pairs

| Attribute | Scores at all | …of those, green |
|---|---:|---:|
| **Languages** | **100.0%** | **100.0%** |
| Sect | 100.0% | 68.8% |
| Ethnicity | 75.7% | **15.0%** |
| Nationality | 66.7% | 81.0% |
| Country of birth | 29.2% | — |
| Revert status | 6.3% | — |
| **Mean attributes scoring per pair** | **3.78** | |

**English is in 100% of profiles and 100% of preference lists.** The language
rule scores green if *any* preferred language matches, so it returns green
every single time. It adds +2 to the numerator and +2 to the denominator for
every pair alive — it cannot distinguish anybody, and it drags every score
toward 100.

It is **26% of Chapter 2's entire scored mass** (1 of 3.78 attributes), spent
on an attribute with zero discriminating power.

Ethnicity is the opposite: it scores on three quarters of pairs and is green
only 15% of the time. That is the attribute doing the real work.

### What removing the language term would do

Same pairs, same rules, language term dropped:

| | With languages | Without |
|---|---:|---:|
| Mean score | 95.2 | 93.2 |
| **Standard deviation** | **5.95** | **8.54** |
| Lowest score | 50.0 | **25.0** |
| Share scoring 95+ | 57.8% | 48.5% |
| Share scoring exactly 100 | 48.3% | 48.3% |

**43% more spread**, and the floor drops from 50 to 25 — real separation appears
at the bottom of the distribution. The top is unchanged: the 48.3% who score 100
are pairs that genuinely match on everything, and they still do.

---

## 4. The weight arithmetic, since it was asked for

At weight *w*, with Chapter 3/4 fully answered (71 preference questions × 2):

| `v_ch2_weight` | Chapter 2's share of the final score |
|---:|---:|
| **1** (today) | **5.1%** |
| 2 | 9.6% |
| 3 | 13.8% |
| 5 | 21.0% |

The 2026-08-04 note guessed "a few percent". It was right: **about 5%.**

But that is the answer to the wrong question. Raising *w* multiplies a bundle in
which one of 3.78 scoring attributes is a guaranteed green and another
(nationality) is green 81% of the time. **You would be turning up the volume on
noise along with the signal.**

---

## 5. Recommendation

**Fix the language rule first, then set the weight.** Three options, for decision:

| Option | Effect |
|---|---|
| **A** — exclude English from the language match | Scores on heritage language only. The attribute starts meaning something. Simplest change |
| **B** — score on the *proportion* of preferred languages matched | Partial credit; more granular, more code |
| **C** — drop languages from scoring; keep as profile/filter data | Honest about what it is. Loses a genuine signal for the minority who care about heritage language |

I lean **A**. English is a given in this market — it carries no information about
compatibility, and it is the only reason the attribute reads as universal
agreement.

**Then** revisit `v_ch2_weight` with the language term repaired, and preferably
with Chapter 3/4 seeded too — see §6.

**Not recommended:** setting the weight above 1 today. It would move scores
without improving the ordering.

---

## 6. What is still missing

`onboarding_answers` has **zero rows**, so §4's table assumes a fully-answered
Chapter 3/4 rather than measuring one. To close `v_ch2_weight` properly the same
backfill needs doing for Chapter 3/4 — 104 answers and 71 preference maps per
Seeker.

That is a much larger synthetic-data exercise than this one, and it carries a
real risk this backfill did not: Chapter 3 answers are **values**, not
demographics. There is no census for "how involved should your parents be". A
made-up distribution there would be a guess wearing the costume of data, and the
scoring engine tuned against it would be tuned to my imagination.

**Raise before building.** Options are (a) seed Chapter 3/4 from plausible
correlations and label the results clearly as synthetic, (b) wait for real users,
or (c) seed only the subset of Chapter 3 questions that have external reference
points (marriage status, children, education, income) and leave the values
questions empty.

---

## 6a. UPDATE, same day — Chapter 3/4 seeded, and the answer changes shape

Founder chose the **full synthetic seed, clearly labelled**, and the language
fix (**exclude English**). Both are done. What follows supersedes §4's
projection, which assumed a fully-answered Chapter 3/4 rather than measuring one.

**Language fix, measured live** (40 viewers × ~68 candidates, Chapter 2 only):

| | Before | After |
|---|---:|---:|
| Mean score | 96.0 | **94.1** |
| Lowest | 58.3 | 56.3 |
| Spread per viewer | 11.4 | **13.2** (+16%) |

Less than the +43% the simulation suggested, because the live fix only skips
the attribute when the preferred list is English-*only*; where a heritage
language remains, the term still scores — it just has to be earned now.

**Chapter 3/4 seed.** 144 Seekers, ~70 answers and ~70 preference maps each,
10,114 answers in total. 19 Seekers (13%) carry a dealbreaker. Every row is
flagged `is_synthetic`. `ch3_q24` is branched away for the 38 Seekers who said
they want no children, matching the app's own `ShowIf` rule.

Preferences are **assortative** — own answer green, neighbours green/yellow,
distant options yellow, occasional red — because preferring similarity is the
most reliable finding in mate-preference research and is H2's premise.

**The measured weight answer:**

| | |
|---|---:|
| Ch3/4 questions scoring on a typical pair | 66.6 |
| …so Chapter 3/4 supplies this much of `v_max` | **133** |
| Chapter 2 supplies (≈3 attributes × 2 × weight 1) | **6** |
| **Chapter 2's share of the score at weight 1** | **4.3%** |

To make Chapter 2 worth a given share, `weight ≈ share × 133 / (6 × (1 − share))`:

| Desired Chapter 2 influence | Weight |
|---:|---:|
| 5% | 1.2 |
| 10% | 2.5 |
| 20% | 5.5 |
| 30% | 9.5 |

**So the decision is not "what number" — it is "how much should sect and
ethnicity matter relative to 70 questions about values?"** Answer that and the
weight follows from the table.

### The bigger finding, and a warning about it

With both chapters live, scores land between **77 and 100, mean 86.3**, with a
mean spread of only **10.5 points** inside one viewer's pool. Seventy questions
each contributing a little pulls everyone toward the middle — the compatibility
percentage separates people *less* than Chapter 2 did alone.

**Do not act on that yet.** That number is a property of the preference model I
invented, not of your users. I chose the assortative decay; a population that
marks more red would spread out immediately. It is exactly the risk flagged
before seeding: an engine tuned against this data is tuned against my
imagination.

What survives regardless of the model is the arithmetic: 133 versus 6. Chapter 2
*cannot* matter much at weight 1, whatever real users do.

---

## 7. Reproducibility

The seed is deterministic — assignment is by `row_number()` over `profiles.id`,
with no random(). Re-running against a fresh database with the same profile set
produces identical rows. It touches only Seekers with no `seeker_details` row, so
it is safe to re-run: it is a no-op once complete.

Script: `SOURCE/supabase/seed_chapter2_backfill_2026-08-10.sql`.

---

## 8. What was verified, and how

| Claim | Evidence |
|---|---|
| 120 seekers had no details; 144 now do | Live count before and after |
| Distribution matches the sources | Live aggregate query, §1 table |
| Every code valid | Checked against `zyra_reference_data.dart` before insert — 197 countries, 184 languages, 29 ethnicities |
| Chapter 2 score spread | 40 viewers × ~72 candidates through `score_candidates()` |
| Per-attribute behaviour | 10,368 pairs, §3 |
| The with/without-languages comparison | Same 9,654 post-exclusion pairs, scored both ways with the engine's own light values (green 2, yellow 1, red −3) |

---

*Sources for the distribution:*
*Census 2021 England & Wales via [Islam in the United Kingdom](https://en.wikipedia.org/wiki/Islam_in_the_United_Kingdom);*
*denominational split from the Techne survey for the [Institute for the Impact of Faith in Life](https://iifl.org.uk/blogs/britains-diverse-muslims/);*
*[Muslim Council of Britain — 2021 Census First Look](https://mcb.org.uk/resources/2021-census-first-look/).*

*End of Document*
