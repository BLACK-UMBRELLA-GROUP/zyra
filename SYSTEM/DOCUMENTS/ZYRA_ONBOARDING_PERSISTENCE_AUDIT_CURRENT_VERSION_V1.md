---
id: DOC-ZYRA-0244
type: REPORT
status: CURRENT
feature: ONBOARDING
purpose: ZYRA — Onboarding Persistence Audit
links: []
owner: ZYRA chat
---

# ZYRA — Onboarding Persistence Audit

**Version:** V1
**Status:** **AUDIT — findings only. Nothing has been changed.**
**Date:** 2026-08-01
**Author:** Claude (Opus), Implementation Lead
**Commissioned by:** Founder via ChatGPT — *"Fix the Chapter 2 persistence gap. This is now the highest priority. If onboarding asks users for information, it must actually be stored correctly."*

**Method:** every field read out of the onboarding source, then traced forward
to a database write and back to a read. Live database queried 2026-08-01.
No claim below is inferred from a document.

---

## 0. The headline

Onboarding asks a Seeker **31 questions**. **27 of the answers are thrown
away** the moment the app closes.

Not stored badly. Not stored in the wrong place. Never written at all.

One correction to my own earlier report to the Founder: I said *"nothing writes
to `onboarding_answers`"*. **That was wrong.** `ZyraOnboardingAnswersService`
exists and writes Chapters 3 and 4 correctly. The table has zero rows because
no real account has ever finished Chapter 4 — an empty table and an unwritten
table look identical from the outside, and I did not check before saying so.

---

## 1. Chapter by chapter

| Chapter | Collects | Written | Read back |
|---|---|---|---|
| **1 — Identity** | first name, gender, date of birth | ✅ `profiles` | ✅ |
| **2 — Background** | 27 fields (§2) | ⚠️ **photos only** | Photos only |
| **3 — Values** | `ch3_answers` | ✅ `onboarding_answers` | ⚠️ never read |
| **4 — Preferences** | `ch4_preferences`, `ch4_hard_requirements` | ✅ `onboarding_answers` | ⚠️ never read |

Chapter 1 is correct. Chapters 3 and 4 are correct on the write side. Chapter 2
is where the loss is.

---

## 2. Chapter 2 in full

`chapter2_flow.dart` holds 27 pieces of answer state (plus 2 UI flags).
`_goToChapter3Transition()` passes **three** of them to `AppState.saveChapter2`,
which writes to memory. `ZyraProfileService._createProfile` then writes exactly
five columns — `id`, `role`, `first_name`, `date_of_birth`, `gender`.

| Field | Passed to AppState | Reaches the database |
|---|---|---|
| `_photos` | ✅ | ✅ Storage + `profile_photos` |
| `_location` | ✅ | ❌ **never written** |
| `_sect` / `_sectOther` | ✅ | ❌ **never written** |
| `_distancePref`, `_distanceFlex` | ❌ | ❌ |
| `_sectMatrix`, `_sectHardReq`, `_sectOutsideFlex` | ❌ | ❌ |
| `_revertStatus`, `_revertFlex` | ❌ | ❌ |
| `_countryOfBirth`, `_countryPrefs`, `_countrySkipped`, `_countryFlex` | ❌ | ❌ |
| `_nationality`, `_nationalityPrefs`, `_nationalitySkipped`, `_nationalityFlex` | ❌ | ❌ |
| `_ethnicity`, `_ethnicityPrefs`, `_ethnicitySkipped`, `_ethnicityFlex` | ❌ | ❌ |
| `_languages`, `_languagePrefs`, `_languageSkipped`, `_languageFlex` | ❌ | ❌ |

**Photos are the only Chapter 2 answer that survives.**

### 2.1 The sharpest instance — `location_text`

`profiles.location_text` is **read in six places** and **written in none**:

```
zyra_discovery_service.dart:123   city: (map['location_text'] ...) ?? '—'
zyra_match_service.dart:86        city: (map['location_text'] ...) ?? '—'
zyra_wali_journey_service.dart    city: (row['location_text'] ...) ?? '—'
zyra_journey_service.dart:114     city: (map['location_text'] ...) ?? '—'
zyra_journey_service.dart:588     city: (profileRow['location_text']...) ?? '—'
zyra_session_router.dart:141      location: row['location_text'] ...
```

So ZYRA asks *"Where do you currently live?"*, and then shows **"—"** on that
person's Browse card, their Connections row, and their Guardian's Journey view.

This has been invisible because **all 26 existing profiles were seeded directly
via SQL**, with `location_text` already populated. Every one of them has a city.
No profile has ever reached the database through onboarding. The first real
signup would have exposed it immediately.

---

## 3. Why this cannot be fixed by adding columns alone

Chapter 2's 27 fields are not one kind of thing. They split cleanly, and the
split determines where each belongs:

**Facts about the Seeker** — location, sect, revert status, country of birth,
nationality, ethnicity, languages. These are **queryable**: matching, filtering
and gender-segregation all need to compare them across users. They must be
**columns**, not JSON — you cannot index or filter Browse on a value buried in
a `jsonb` blob without a scan.

**Preferences about a spouse** — the `*Prefs` lists, the `*Flex` traffic
lights, `_sectMatrix`, `_sectHardReq`, the `*Skipped` flags. These are
structurally identical to what Chapter 4 already stores, and they are only ever
evaluated **for one user at a time**. They belong in `onboarding_answers`
alongside `ch4_preferences`.

`seeker_profile.dart`'s own header already anticipates the first half:

> *"will be replaced by the real Supabase `profiles`/`seeker_details` read model"*

A `seeker_details` table was planned. It was never built.

---

## 4. Proposed shape — **for approval, not built**

| Change | Holds |
|---|---|
| **New `seeker_details` table**, 1:1 with `profiles` | sect, revert status, country of birth, nationality, ethnicity, languages, distance preference |
| **Write `profiles.location_text`** | the existing column, currently never populated |
| **New `onboarding_answers.ch2_preferences` jsonb** | every `*Prefs`, `*Flex`, `*Skipped`, the sect matrix, hard requirements |
| **Extend `_createProfile`** | pass Chapter 2 through instead of dropping it |

Why `seeker_details` rather than widening `profiles`: `profiles` is read on
every Browse card, every Connections row and every Journey view. Adding seven
rarely-read columns to the hottest table in the app makes every one of those
reads wider. It also carries a live hazard — the 2026-08-01 `date_of_birth`
fix replaced the table-level GRANT with an **explicit column list**, so any new
column on `profiles` is invisible to the client until it is added to that list.
A separate table has its own grant and its own RLS.

---

## 5. Dependent features — what is standing on this

Directive 5 asked what should be paused. In severity order:

| Feature | Depends on | State |
|---|---|---|
| **Profile Unlock / Unlock+** | Ch3 + Ch4 answers of **both** users | Cannot produce a real number. Currently shows sample data, marked. **Keep paused.** |
| **`score_candidates()`** | `onboarding_answers` | Real code that has never executed against real data. |
| **Compatibility Reveal** (Pre-Journey Ritual) | same | Same dependency, not yet audited. |
| **City on every profile card** | `location_text` | **Actively wrong today** — shows "—" for any non-seeded user. |
| **Sect / ethnicity / language matching** | Chapter 2 facts | Cannot be built at all. The data does not exist. |
| **200-profile test dataset** | all of the above | Correctly blocked. Seeding now would produce test profiles richer than any real user can create. |

**Recommendation:** nothing new is built on Chapter 2 or on compatibility until
§4 lands. Everything else can proceed.

---

## 6. Also unpersisted — decisions

Raised under directive 2, resolved in part on 2026-08-01:

| State | Before | Now |
|---|---|---|
| Considered | `likes` table | ✅ persisted |
| Saved | `saves` table | ✅ persisted |
| **Declined** | memory only | ✅ **`passes` table, shipped and verified 2026-08-01** |
| **Reset Search** | did not exist | ✅ `zyra_reset_search()`, verified |

`AppState.declined` / `saved` / `outgoingLikes` are still populated only within
a session — the tables are written but never **read back** on launch. So a
restart still shows empty Connections lists. That is the next persistence gap
after Chapter 2, and it is small: one hydration call in `zyra_session_router`.

---

## 7. Open questions for the Founder

1. **Approve the §4 shape** before any migration is written.
2. **Do the 27 Chapter 2 questions all still earn their place?** This audit
   found them by reading code, not by asking whether a 31-question onboarding
   is the right product. Persisting a question is a commitment to it.
3. **What happens to the 26 existing seeded profiles** when `seeker_details`
   exists — backfill with plausible values, or leave them incomplete so the
   incomplete-profile path gets exercised?
4. **Should Chapter 2 write incrementally or at the end?** It currently writes
   once at the chapter boundary. A 27-field chapter abandoned halfway loses
   everything.

---

## 8. What was verified, and how

| Claim | Evidence |
|---|---|
| 27 Chapter 2 fields, 3 passed on | Parsed from `chapter2_flow.dart` source |
| `_createProfile` writes 5 columns | Read directly, `zyra_profile_service.dart:129-144` |
| `location_text` never written | Grepped every `from('profiles')` write in `lib/` |
| Ch3/Ch4 **are** written | `zyra_onboarding_answers_service.dart:33` |
| `onboarding_answers` = 0 rows | Live query |
| All 26 profiles have a location | Live query — they were seeded, not onboarded |
| `passes` / Reset Search work | 8 empirical tests against the live database |
