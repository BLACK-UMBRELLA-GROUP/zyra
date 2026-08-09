# ZYRA — Chapter 2 Question Review

**Version:** V1
**Status:** **REVIEW — recommendations only. Nothing changed, no migration written.**
**Date:** 2026-08-01
**Author:** Claude (Opus), Implementation Lead
**Commissioned by:** Founder via ChatGPT — *"before implementing persistence, review every Chapter 2 question and ask whether it still earns its place. If a field doesn't meaningfully improve matching, compatibility, safeguarding or another genuine product objective, I'd rather remove it now. Let's finalise **what** we collect before finalising **where** we store it."*

**Companion:** `ZYRA_ONBOARDING_PERSISTENCE_AUDIT_CURRENT_VERSION_V1.md`

---

## 0. Recommendation in one line

**21 screens → 12.** Cut five, fix one that cannot work as built, and resolve
one blocker before any of it is stored.

---

## 1. The blocker — read this before anything else

**The reference lists are mock, and incomplete.**

`data/mock_reference_lists.dart` — the file's own header says so:

> *"Static reference lists standing in for real searchable country/language/ethnicity datasets, which need a real backend/API to back properly."*

| List | Entries | Reality |
|---|---|---|
| `mockCountries` | 30 | ~195 countries exist |
| `mockLanguages` | 20 | Hundreds |
| `mockEthnicities` | 12 | — |

A Muslim Seeker from Kenya, Kosovo, Uzbekistan, the Philippines or Sri Lanka
**cannot answer** "which country were you born in". There is no "Other" and no
free-text fallback on that picker.

This matters more than it looks. Persisting an answer commits to a **taxonomy**.
If 200 users pick from 30 countries and the list later becomes 195, every stored
value must be re-mapped, and the ones who picked the nearest wrong answer cannot
be recovered. **The reference data must be settled before the column exists**,
not after.

`nationality` has a second problem: it uses `mockCountries`, so the stored value
is *"Pakistan"* where a nationality is *"Pakistani"*. Typed wrong at source.

---

## 2. The structural finding

Chapter 2 is one pattern repeated seven times:

```
  YOUR VALUE  →  YOUR PREFERENCE  →  YOUR FLEXIBILITY
  (a fact)       (what you want)     (would you bend?)
```

Applied to: distance, sect, revert, country of birth, nationality, ethnicity,
language.

**The third step is redundant.** Five of them are word-for-word identical:

> *"Would you be happy for ZYRA to introduce people from outside your preferred
> X if they appear to be a strong match?"*
> — Yes / Maybe, depending on the person / No, I'd prefer to stay within.

That is not a new question. It is **"is this preference hard or soft?"** — and
for matching, *Yes* and *Maybe* mean the same thing: show me these people.
Three options collapse to two the moment anything acts on them.

**The codebase already solves this correctly, once.** The sect matrix
(`TrafficLightQuestionScreen`) carries `_sectHardReq` — a hard-requirement flag
*on the preference itself*. The right pattern exists. The other five preferences
just don't use it.

**Recommendation: fold all five flexibility screens into a hard/soft toggle on
their preference screen.** Five screens removed, no information lost.

---

## 3. The question that cannot work as built

| Step | Question | Stored as |
|---|---|---|
| 1 | Where do you currently live? | **Free text** (`TextField`) |
| 2 | How far would you like your spouse to live from you? | Within 10 / 25 / 50 / 100 miles / Country / World |

**You cannot compute miles from a typed string.** There is no geocoding, no
latitude, no longitude, and no plan for any. A Seeker who answers *"Within 10
miles"* has given an answer ZYRA can never honour.

Worse, free text means *"London"*, *"london"*, *"Greater London"* and *"Sarf
London"* are four different cities. Even exact-match city filtering fails.

Three ways out:

| Option | Cost | Effect |
|---|---|---|
| **A** — city picker backed by real geo data with coordinates | Reference dataset + a lat/long column | Distance works properly |
| **B** — keep the free text, cut the distance question | Nothing | Honest. City still displays; no false promise |
| **C** — coarse buckets: same city / same region / anywhere | Small | Works without coordinates, loses precision |

**Recommendation: B now, A later.** Cutting a question that cannot be honoured
is not a downgrade — it is removing a promise the app cannot keep. The
`location_text` fix (audit §2.1) stands either way, because six screens display
the city and none of them need distance.

---

## 4. Heritage — three questions or two?

Country of birth, nationality and ethnicity are three overlapping answers to
roughly one question. With their preferences and flexibilities they consume
**nine of the twenty-one screens** — 43% of the chapter.

I am **not** recommending a cut, and the reason matters: in this market the
distinctions are real. *Pakistan-born* and *British-born Pakistani* is a
meaningful difference to many families, and ethnicity does not capture it.
Cutting on tidiness grounds would be a Western-defaults mistake.

But 43% of onboarding is a lot, and country of birth and nationality are the
same answer for most people. **Founder decision, not mine.** Options:

| Option | Screens (of 21) |
|---|---|
| Keep all three | 9 |
| Merge country of birth + nationality into "Heritage" | 6 |
| Ethnicity + languages only | 6 |

---

## 5. Question-by-question

Legend: **Keep** · **Fold** (merge into the preference) · **Cut** · **Fix**

| # | Question | Objective it serves | Verdict |
|---|---|---|---|
| 0 | Add your photos (3–6) | Core. Browse does not exist without it | **Keep** |
| 1 | Where do you currently live? | Displayed on every card; six read sites | **Fix** — must be written; picker if §3A |
| 2 | Preferred distance | Cannot be computed | **Cut** (§3) |
| 3 | Distance flexibility | Depends on a cut question | **Cut** |
| 4 | Your Islamic sect | Genuine matching axis. **GDPR Art. 9** | **Keep** |
| 5 | Sects comfortable matching with | Already has a hard-requirement flag | **Keep** — the model for the others |
| 6 | Sect outside flexibility | Duplicates the hard-req flag in #5 | **Fold** |
| 7 | Have you reverted to Islam? | Real, frequently-stated criterion. **Art. 9** | **Keep** |
| 8 | Revert flexibility | Has no preference step to fold into | **Keep** — reword as a preference |
| 9 | Country of birth | Heritage — see §4 | **Decide** |
| 10 | Preferred countries of birth | Heritage | **Decide** |
| 11 | Country flexibility | Identical to #3, #14, #17, #20 | **Fold** |
| 12 | Your nationality | Heritage. Typed wrong (§1) | **Decide + Fix** |
| 13 | Preferred nationalities | Heritage | **Decide** |
| 14 | Nationality flexibility | Identical | **Fold** |
| 15 | Your ethnic background | Strongest of the three heritage axes | **Keep** |
| 16 | Preferred ethnic backgrounds | Widely-used criterion | **Keep** |
| 17 | Ethnicity flexibility | Identical | **Fold** |
| 18 | Languages you speak fluently | Practical; matters for families | **Keep** |
| 19 | Preferred languages | Practical | **Keep** |
| 20 | Language flexibility | Identical | **Fold** |

**Cut 2. Fold 5. Fix 2. Decide 4.**

Keeping all four "Decide" questions: **21 → 14.**
Merging country of birth into nationality: **21 → 12.**

---

## 6. Safeguarding and legal

| Field | Issue |
|---|---|
| Sect (#4), Revert status (#7) | **UK GDPR Article 9** — religious belief, special category. Needs *explicit* consent, not a privacy policy link. Both are currently `PrivacyLevel.unlock`, i.e. purchasable by another user. **A solicitor must confirm that selling access to Article 9 data is lawful.** |
| Ethnicity (#15) | Also Article 9 (racial/ethnic origin). Same question applies. |
| Location (#1) | Free text invites a street address. No validation stops *"14 Mill Lane, Bradford"*. City-only should be enforced. |

**§6 is flagged, not resolved. Not legal advice.**

---

## 7. What I need before writing a migration

1. **Approve or amend §5** — the cut/fold/fix/decide list.
2. **Answer §4** — how many heritage dimensions.
3. **Decide §3** — cut distance, or commit to real geo data.
4. **Resolve §1** — real reference lists, or accept a taxonomy that will need
   re-mapping later. **This one gates everything.**
5. **Confirm §6** with a solicitor before Article 9 fields are stored or sold.

Once 1–4 are settled, the storage design in the audit's §4 can be finalised and
the migration written in one pass — schema, `_createProfile` wiring,
`location_text` fix, decision hydration, and the seeded-profile backfill
together.

---

## 8. Method

Every question read from `chapter2_flow.dart` steps 0–20. Reference lists read
from `data/mock_reference_lists.dart` and counted. Widget types confirmed by
reading each `content:` branch — `_TextField` for location, `_SearchPickButton`
for the pickers, `FlexibilityChoice` for the five flexibility screens,
`TrafficLightQuestionScreen` for the sect matrix. No claim here is taken from a
document.
