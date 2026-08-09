# ZYRA — Chapter 2 Persistence Implementation Plan

**Status:** APPROVED AND IMPLEMENTED — Founder approved 2026-08-04
**Written:** 2026-08-04
**Author:** Opus session

## Implementation record

All five Founder decisions were given on 2026-08-04 and are built.

| § | Decision | Built |
|---|---|---|
| 3 | **Option C** — typed columns for attributes, JSONB for preferences | `seeker_details` |
| 4.2 | Guardian visibility | policy `seeker_details_select_guardian` — **narrow reading only, see below** |
| 5 | Consent and persistence together; solicitor reviews wording pre-launch | `consents` + `Article9ConsentScreen` |
| — | `profiles.bio` left in place | untouched |
| — | Seeded profiles backfilled | 24 Seekers, deterministic |

**Migrations applied:** `article9_consents_log`,
`seeker_details_typed_attributes_jsonb_preferences`,
`seed_chapter2_details_for_dev_profiles`.

**New code:** `zyra_consent_service.dart`,
`zyra_seeker_details_service.dart`, `article9_consent_screen.dart`; Chapter
2 wired at both the consent gate and the chapter-end write.

### One thing deliberately NOT inferred

The approval reads *"a linked Guardian should be able to view the same
Compatibility Unlock information that the Seeker is permitted to view."*
That supports two readings:

- **(a)** the Guardian sees **their own Seeker's** details — implemented
- **(b)** the Guardian also **inherits the Seeker's unlocks**, seeing the
  details of **third parties** the Seeker paid to unlock — *not*
  implemented

(b) grants a Guardian access to a fourth party's Article 9 data. That is a
materially larger privacy surface and not something to infer from an
ambiguous sentence, so only (a) is live. (b) is a one-line addition to
`seeker_details_for_unlocked()` — **please confirm which you meant.**

---

## 1. The problem, stated precisely

Chapter 2 asks nineteen questions. It persists **one** of them.

`Chapter2Flow._goToChapter3Transition()` calls `AppState.saveChapter2()`,
which assigns three instance fields and calls `notifyListeners()`. That is
the entire write path. Close the app and everything is gone.

Verified against the live database 2026-08-04:

| Evidence | Finding |
|---|---|
| `profiles` columns | 12 total. None hold sect, revert status, country of birth, nationality, ethnicity, languages, or any preference. |
| `profiles.location_text` | Read by 3 services, **written by 0** — fixed 2026-08-04, see §7. |
| `profiles.bio` | Exists. Zero references anywhere in `lib/`. Dead column. |
| `onboarding_answers` | 0 rows. Chapter **3/4** only — Chapter 2 has no equivalent. |
| `zyraCodeFor()` | Defined in the reference data, **never called**. The ratified "store the code, never the label" rule has never been exercised. |

### Why this blocks everything premium

Compatibility Unlock compares one Seeker's preferences against another's
answers. Roughly half those answers are Chapter 2's — sect, ethnicity,
languages, nationality. With no storage there is no score, so the
Compatibility Unlock screen shipped 2026-08-04 has nothing real to sell
and its figures remain sample data.

---

## 2. Full field inventory

Taken from `_Chapter2FlowState`, with the privacy level each question
declares on screen.

### Own attributes — describe the Seeker

| Field | Type | Privacy | Reference list |
|---|---|---|---|
| `_photos` | `List<String>` | public | — (already persisted via `profile_photos`) |
| `_location` | `String?` | public | free text |
| `_sect` (+ `_sectOther`) | `String?` | unlock | fixed: Sunni / Shia / Other |
| `_revertStatus` | `String?` | unlock | Yes / No |
| `_countryOfBirth` | `String?` | unlock | `zyraCountries` |
| `_nationality` | `String?` | unlock | `zyraCountries.nationality` |
| `_ethnicity` | `String?` | unlock | `zyraEthnicities` |
| `_languages` | `List<String>` | unlock | `zyraLanguages` |

### Preferences — describe who they want

| Field | Type | Notes |
|---|---|---|
| `_distancePref` | `String?` | `zyraLocationPreferences` |
| `_distanceFlex` | `TrafficLight?` | |
| `_sectMatrix` | `Map<String, TrafficLight>` | per-option traffic light |
| `_sectHardReq` | `bool` | |
| `_sectOutsideFlex` | `TrafficLight?` | |
| `_revertFlex` | `TrafficLight?` | |
| `_countryPrefs` | `List<String>` | + `_countrySkipped`, `_countryFlex` |
| `_nationalityPrefs` | `List<String>` | + `_nationalitySkipped`, `_nationalityFlex` |
| `_ethnicityPrefs` | `List<String>` | + `_ethnicitySkipped`, `_ethnicityFlex` |
| `_languagePrefs` | `List<String>` | + `_languageSkipped`, `_languageFlex` |

**Thirty-one values. One persists.**

---

## 3. THE DECISION THIS PLAN NEEDS FROM YOU

Everything below branches on one choice.

### Option A — one `seeker_details` table, typed columns

```
seeker_details
  user_id            uuid PK -> profiles(id) ON DELETE CASCADE
  sect               text        -- code, not label
  sect_other         text
  revert_status      boolean
  country_of_birth   text        -- ISO 3166-1 alpha-2
  nationality        text        -- ISO 3166-1 alpha-2
  ethnicity          text        -- reference code
  languages          text[]      -- ISO 639-1
  preferences        jsonb       -- the traffic-light block
  updated_at         timestamptz
```

**For:** matching can be done in SQL. `where ethnicity = any($1)` uses an
index; a JSONB containment query on 200,000 rows does not. Scoring will be
the hottest query in the product.
**Against:** every future question is a migration.

### Option B — extend `onboarding_answers` with a `ch2_answers jsonb`

**For:** one migration, ever. Symmetrical with Chapters 3/4. Fastest to
ship.
**Against:** every attribute you will ever filter or score on is trapped in
a JSONB blob. Also puts Article 9 data in the same row as everything else,
which makes a targeted deletion request harder to honour.

### Option C — hybrid *(my recommendation)*

Typed columns for the eight **own attributes** (§2, first table) — those
are what scoring reads and what a Compatibility Unlock exposes. JSONB for
the **preferences** block, which is only ever read whole, for one user, to
compute their own score.

**For:** indexable where it matters, flexible where it doesn't. Article 9
fields sit in named columns you can point a solicitor at, grant on, and
drop individually.
**Against:** two storage idioms in one table. Mitigated by the split being
principled — attributes are queried across users, preferences never are.

---

## 4. Non-negotiables, whichever option you pick

### 4.1 Store the code, never the label

Ratified rule, currently unexercised — `zyraCodeFor()` has zero callers.

Storing `'Pakistani'` means the day the display string changes to
`'Pakistani (Pakistan)'`, every stored row silently stops matching. Store
`'PK'`; render the label at read time.

This applies to country of birth, nationality, ethnicity and languages.
Sect is a fixed three-value list and can be a CHECK constraint.

### 4.2 RLS must be stricter than `profiles`

`profiles` is readable by anyone when `is_active AND profile_complete`.
`seeker_details` must **not** inherit that. Chapter 2 marks these fields
`PrivacyLevel.unlock`, which means another user sees them only after
paying — so the row must be:

- readable by its owner
- readable by a linked Guardian (confirm: **should a Guardian see sect and
  ethnicity? I have assumed yes and flagged it**)
- readable by another Seeker **only** via a `SECURITY DEFINER` function
  that first checks `profile_unlocks`

Never a blanket select policy. The unlock check belongs in the database,
not the client, for the same reason the once-per-profile rule does.

### 4.3 `_sectOther` is free text from a user

It reaches `_sectOptions` and renders. Length-cap it and treat it as
untrusted on the way in.

---

## 5. Article 9 — must be resolved before any of this ships

Four Chapter 2 fields are **special-category data** under UK GDPR
Article 9:

| Field | Article 9 category |
|---|---|
| `_sect` | religious belief |
| `_revertStatus` | religious belief |
| `_ethnicity` | racial or ethnic origin |
| `_countryOfBirth` / `_nationality` | can infer ethnic origin |

Article 9 processing requires a lawful basis beyond ordinary consent —
for a commercial product, realistically **explicit consent**, freely
given, specific, and separately recorded.

**Today the app collects all four with no consent step of any kind.**

Building storage without the consent gate makes the position worse, not
better: it moves the data from a transient in-memory object into a durable
record. So the consent step should land in the **same** release, not after.

### The question only a solicitor can answer

Compatibility Unlock lets one user **pay** for access to another's
compatibility, computed from Article 9 data. Whether that constitutes
lawful processing — and whether the "we never show the actual answers,
only a score" design is sufficient mitigation — is a legal question.

**I am not a lawyer and this is not legal advice.** It needs a solicitor
before launch, and the answer may change the product.

---

## 6. Proposed sequence

Nothing starts until §3 and §5 are answered.

| # | Step | Depends on |
|---|---|---|
| 1 | Article 9 consent screen + `consents` table | §5 answered |
| 2 | Migration: table/columns per §3 | §3 answered |
| 3 | RLS policies + `SECURITY DEFINER` unlock reader | 2 |
| 4 | `ZyraSeekerDetailsService` — write path, logged not silent | 2 |
| 5 | Wire `_goToChapter3Transition()` to call it | 4 |
| 6 | Hydrate on launch, so re-entering Chapter 2 shows saved answers | 4 |
| 7 | Backfill the 26 seeded profiles with plausible values | 2 |
| 8 | Verify: write, kill app, relaunch, confirm answers survive | 5,6 |

Steps 1–3 touch the database and need explicit approval each. Steps 4–8
are code and follow automatically once the schema exists.

---

## 7. Already fixed, 2026-08-04 — needed no migration

`profiles.location_text` existed, was read by three services, and was
written by nothing. Every genuinely-onboarded Seeker rendered an em-dash
where their city belongs.

It stayed hidden for the same reason the `profile_complete` bug did: the
seeded dev profiles have the column filled in by hand, so the only
profiles anyone looked at already had a city.

- `ZyraProfileService.saveLocation()` — targeted `update`, logs on failure
- Called fire-and-forget from `_goToChapter3Transition()`

This is now the **only** Chapter 2 answer that reaches Postgres.

---

## 8. Open questions for the Founder

1. **§3 — A, B or C?** I recommend C.
2. **§4.2 — should a linked Guardian see sect, ethnicity and revert
   status?** I have assumed yes. It is a privacy decision, not a technical
   one.
3. **§5 — will you take the Article 9 question to a solicitor before this
   ships?** If the answer is "later", I would still build the consent step
   now and hold the storage.
4. **Should `profiles.bio` be dropped?** Nothing references it.
5. **Backfill values for the 26 seeded profiles — realistic spread, or
   left null?** Null is honest but leaves scoring untestable.
