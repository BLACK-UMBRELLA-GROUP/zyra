# ZYRA — Decisions of 2026-08-01 to 2026-08-04

**Version:** V2 — CURRENT
**Status:** RECORD — all items Founder approved and implemented
**Author:** Claude (Opus), Implementation Lead

*Supersedes `ZYRA_DECISIONS_2026-08-04_V1.md` (archived, covered 01–03
August). Sections 1–7 are unchanged from V1; section 8 is new and section 9
is the revised open list.*

Two days of decisions, several of which **reversed earlier ones**. Recorded
in one place because the reversals are the part most likely to be undone by
accident: each superseded decision was itself deliberate, argued in code
comments, and would otherwise look like a mistake to the next reader.

---

## 1. One state per profile — REVERSES 2026-08-01

| | |
|---|---|
| **1 Aug** | Saved was a **bookmark** on its own axis. Saved + Considering was valid and intended. |
| **3 Aug** | Saved, Considering and Declined are **mutually exclusive**. Most recent action wins. |

Founder, on seeing one profile under both CONSIDERED and SAVED: *"a user
can't be both saved and considered, so there's an error there."*

The two-axis model was coherent and the data was never wrong. It lost on
the only ground that matters — shown a person in two places, the Founder
read it as a bug every time. A model that needs explaining before a screen
makes sense is the wrong model.

**Enforced in three layers**, so a client that forgets cannot break it:

- `AppState._clearState()` runs before every transition
- Three database triggers: each insert into `saves`/`likes`/`passes` clears the other two
- `test/decision_model_test.dart` — every ordering asserts exactly one state

**Live data was migrated.** 30 pairs held both a save and a like; resolved
by most recent action. 60 rows became 30, zero conflicts remain.

**Consequences that followed automatically:** a saved profile now leaves
the Browse deck, and the Browse "Saved" badge became unreachable and was
removed.

---

## 2. Compatibility Unlock — renamed, repriced, permanent

Was "Profile Unlock". Full detail in
`APP/Premium/Profile Unlocks/Summary.md`; the short version:

| | |
|---|---|
| Name | Compatibility Unlock / Compatibility Unlock Plus |
| Button, unlocked | "View Compatibility", permanently |
| Price | £1.99 / £7.99 · £2.99 / £9.99 (was £0.99/£2.99 · £1.99/£4.99) |
| ZYRA One | 3 free Unlock Plus credits |
| Permanence | Once per profile per tier. Revisiting never charges again. |

The rename fixed a real inconsistency: `Profile Unlock → View
Compatibility` implied two features. `Compatibility Unlock → View
Compatibility` is one idea stated twice.

Permanence is enforced by a **unique index**, not by client checks — a
double tap on a slow connection would otherwise write twice and, once
payments are real, charge twice.

**Rejected:** a "each unlock is permanent" line beside the price. Founder:
*"the user will know."*

---

## 3. Connections structure

| Journeys tab | |
|---|---|
| Active Journey | Emphasised — full-white label, brighter card |
| **Journey Queue** | Was "Potential Journeys" |
| Paused Journeys | |
| **Ended Journeys** | New section, always visible |

"Potential" suggested uncertainty when these are **confirmed mutual
likes** waiting on the user. "Queue" also carries the
one-Active-Journey-at-a-time rule without stating it.

Ended Journeys previously appeared only once something had ended, so
nobody could discover it existed. Founder's stated purpose: *"gives users
closure instead of a Journey disappearing."*

**IMPORTANT — `matches.status` still uses `'potential'`.** Only the display
name changed. Renaming the status value would break RLS policies, service
queries and the promote RPC. Archived dated documents were also left
unchanged, as historical record.

---

## 4. Blocked Users → Settings

Blocked users never appeared in Connections — `profile_blocks` hides them
both ways through RLS. What was missing was anywhere to **see** them:
blocking was one-way, and `unblock()` existed in the service with no
caller.

So this was not a move. It was the missing half of a feature that shipped
with only its first half.

---

## 5. Limits

| | Was | Now |
|---|---|---|
| Save — ZYRA Basic | 10 | **5** |
| Save — ZYRA One | 50 | **15** |
| Consider — Basic | 25 | 25 (confirmed, not changed) |
| Consider — ZYRA One | unlimited | unlimited |

Founder: *"for ZYRA One Seeker 50 profile saves is a lot."* Agreed — a
shortlist of 50 is a second Browse queue, which contradicts the product's
own argument that you should leave, married, rather than accumulate
options.

Upgrade copy deliberately **does not name** ZYRA One's cap: naming it turns
a benefit into a ceiling.

---

## 6. Reference data — production lists

`mock_reference_lists.dart` held 30 countries, 20 languages, 12
ethnicities. A Seeker from Kenya, Kosovo, Uzbekistan or Sri Lanka could not
answer "which country were you born in".

Replaced with 197 countries (ISO 3166-1, each with a demonym), 184
languages (ISO 639-1) and 29 ethnicities.

**THE RULE THAT CAME WITH IT: store the code, never the label.** Relabel
"Turkey" to "Türkiye" and no user row changes, because the row says `TR`.

This was load-bearing immediately — ISO 639-1 names two of this audience's
most-spoken languages "Panjabi" and "Pushto", spellings nobody would
search for. The labels are corrected while the codes stay canonical. Had
the label been the stored value, fixing them would have orphaned every
affected user.

---

## 7. Persistence closed

| | |
|---|---|
| Declines | `passes` table, RLS, verified |
| Reset Search | `zyra_reset_search()`, clears Declined only |
| Decisions on launch | Hydrated in `ZyraSessionRouter` |
| Gender for first paint | Cached on device — no more purple-to-pink flash |

The gradient flash was **never a build-mode problem**. It was a network
round trip, and a real user on mobile data would have seen it longer than
the Founder did on wifi.

---

## 8. 2026-08-04

### 8.1 Green / Amber / Red moved from Unlock up to Plus

Founder: *"unlock should only be % — no green, yellow or red, so it gives
unlock plus more value."*

Compatibility Unlock is now **one number**. The colour tallies join the
category breakdown in Plus. The two tiers were only £1 apart in substance;
this widens the gap the £2 price difference is meant to represent, and
leaves Unlock as the simplest thing in the app to explain.

### 8.2 The compatibility screen is one page, not two tabs

Was two swipeable tabs matching the Journeys/Activity gesture. Now one
card, two stacked sections: **OVERALL** (Unlock) above **THE DETAIL**
(Plus).

A swipe between two tabs says *these are alternatives, pick one*. Plus is a
**superset** of Unlock, so the gesture taught the wrong relationship and
hid half the offer behind a swipe the user had no reason to make.

Locked-in layout rules, each chosen from mockups:

| Element | Decision |
|---|---|
| Balance | Plain words, top-right of each section header — "5 left" / "none left" |
| The plus | Welded to the word: `Unlock Compatibility+`, no space, so it can never break onto its own line |
| Locked detail | A padlock on every row — the buyer sees the six named categories with every value withheld |
| Unlocked | Open padlock + "Unlocked". The line "revisit any time, free" was **cut** |
| Zero balance | Button disabled, not relabelled |
| Buy | "Buy more unlocks" as a foot text link. Prices and BEST VALUE moved to the buy page |

**Plus unlocks Overall too.** Charging again for a part already bought
would break the permanence rule the unique index exists to enforce.

### 8.3 The 81% / 89% contradiction — resolved

The spec gave 81% under Unlock and 89% under Plus. Same two people; it
cannot be both. It survived because the tabs were never on screen together
— stacking them exposed it in the first mockup.

One overall score, **81%**, with supporting figures derived so the
arithmetic holds: `(62 + 19×0.5)/88 = 81.25%`, categories averaging exactly
81. That weighting is an **assumption**, not a ratified rule; the real
scoring method is still open.

### 8.4 Considered card alignment — a defect, not a design change

Founder: *"the flag for Considered isn't in line with the others."*

It was not the flag. Each move button carried its own trailing 8pt gap
inside the same `if`, so the gap survived whenever its button was the last
one rendered — which happens **only** for Considered:

```
Considered   [Pass][8][Save][8]     <- 8pt of nothing on the end
Saved        [Pass][8][Consider]
Passed       [Save][8][Consider]
```

Rebuilt as a list joined by separators, so a separator can only exist
*between* two buttons.

### 8.5 SAMPLE banner removed — with a standing risk

Founder: *"remove the yellow sample logo."* Done.

**Nothing on the compatibility screen now marks the figures as fake.** The
buy link still refuses honestly, but a screenshot of "81% overall" travels
without a warning. Fine while the build is internal; it becomes a real risk
at the first demo, investor deck or TestFlight. Recorded, not overridden —
it is the Founder's own build.

### 8.6 `location_text` — a write that never existed

`profiles.location_text` is read by three services and was written by
none. Every genuinely-onboarded Seeker rendered an em-dash where their city
belongs.

Hidden for the same reason the `profile_complete` bug was: the seeded dev
profiles have the column filled by hand, so the only profiles anyone looked
at already had a city. Fixed — `ZyraProfileService.saveLocation()`, logged
rather than silent. **No migration needed.**

### 8.7 `onboarding_answers` — verified, not broken

Zero rows, which could have meant either "broken" or "nobody has got
there". Verified against the live database: primary key gives the upsert a
real conflict target, all three RLS policies are correct, the FK is
satisfied by Chapter 1, the call site fires at every category summary, and
a test row carrying all three JSONB structures round-tripped exactly (test
row deleted; table confirmed back to zero).

**Empty because no one has walked Chapter 3 signed in.** The real defect
was `catch (_) {}` — a silent swallow on the only input compatibility will
ever have. Now logged.

### 8.8 A static checker, because `flutter analyze` cannot run here

`tools/zyra_check.py`. Assistant sessions cannot run the real analyzer —
the Flutter SDK and pub.dev are unreachable from the sandbox and the
resolved pub cache lives on the Founder's Mac. Verification had fallen back
to ad-hoc greps, which produced false alarms and missed real breakage.

Catches the five classes that have actually broken this build: broken
imports, calls to methods that no longer exist, named arguments a
constructor does not declare, unused imports, and symbols used without
importing their file.

**It does not replace `flutter analyze`.** A clean run is necessary, not
sufficient.

---

## 9. Chapter 2 persistence and Article 9 consent — BUILT 2026-08-04

Founder approved all five outstanding decisions; implementation followed
the same day. Full record in
`ZYRA_CHAPTER2_PERSISTENCE_PLAN_CURRENT_VERSION_V1.md`.

**Storage (Option C).** `seeker_details` — typed columns for the eight own
attributes, JSONB for the preference block. Attributes are queried *across*
users by the scorer and by matching, so they need indexes; preferences are
only ever read whole for one user, so columns would buy nothing and every
future question would be a migration.

**Codes, never labels — now enforced, not merely intended.** `zyraCodeFor()`
had zero callers until today. CHECK constraints reject `'Pakistan'` for a
country and `'Pakistani'` for an ethnicity outright. Verified: five label
forms rejected, code row accepted. The rule earns its keep immediately —
`TR` renders "Türkiye" and `pa` renders "Punjabi", not ISO's "Panjabi".

**RLS is deliberately stricter than `profiles`.** There is **no** policy
letting one Seeker select this table. That path goes through
`seeker_details_for_unlocked()`, a `SECURITY DEFINER` function that checks
`profile_unlocks` first — the same reasoning that put the once-per-profile
rule in a unique index rather than client code.

Proven against the live database by impersonating four real accounts:

| Actor | Direct select | Via unlock function |
|---|---|---|
| Stranger | 0 rows | 0 rows |
| **Holder of a real unlock** | **0 rows** | 1 row, correct data |
| Owner | own row | — |
| Guardian of that Seeker | their Seeker's row | — |
| Guardian, unrelated Seeker | 0 rows | — |

`has_article9_consent()` defaults to **false** for anyone who never
consented, and on any error — the opposite of how the rest of the codebase
treats a failed read, because the cost of being wrong is asymmetric.

**Consent is append-only.** Withdrawal is a new row, never an update. There
is no UPDATE or DELETE policy, not even for the subject. `policy_version`
records *which wording* was agreed, so the solicitor's revisions cannot
silently inherit old consent.

**The consent screen refuses to proceed on an unrecorded "yes".** Declining
is a real path — it skips to languages (not special-category) and the
chapter completes. A decline that dead-ended would make the consent not
freely given, and therefore not consent.

**Seeded data.** 24 Seekers backfilled deterministically, weighted rather
than uniform: Sunni 16 / Shia 6 / Other 2, four reverts, ethnicities that
repeat. Every profile now shares both a language and an ethnicity with at
least one other, so overlap bugs can actually surface. Their consent rows
carry `policy_version = '2026-08-04-seed'` — greppable, and impossible to
mistake for a genuine agreement.

### 9.1 Guardian scope — CONFIRMED CONSERVATIVE, 2026-08-04

The Founder confirmed the narrow reading, which is what had been built:

> A Guardian should only be able to view **their own Seeker's** Chapter 2
> information. A Guardian should **not** automatically inherit Compatibility
> Unlocks purchased by the Seeker, nor gain access to another person's
> Article 9 data simply because the Seeker has unlocked it. Compatibility
> Unlocks remain personal to the Seeker who purchased them.

Proven against the live database using a Guardian whose Seeker holds three
real unlocks:

| Actor | Action | Result |
|---|---|---|
| Guardian | read their own Seeker's row | 1 row |
| Guardian | read a profile the Seeker **paid to unlock** | **0 rows** |
| Guardian | same, via the unlock function | **0 rows** |
| Guardian | sweep the whole table | 1 row — their Seeker only |
| Seeker | their own purchased unlock | still works |

Shared unlocks, if ever wanted, are a deliberate future feature with their
own review — not something to arrive at by accident.

### 9.2 Scoring EXTENDED, not replaced — 2026-08-04

Founder: *"extend the existing scoring engine to incorporate those
additional attributes rather than creating a second scoring mechanism."*

`score_candidates()` now reads `seeker_details.preferences` in addition to
`onboarding_answers`. The Chapter 3/4 block is **byte-for-byte unchanged**;
Chapter 2 is appended and shares `v_total`/`v_max`, so both chapters land on
one 0–100 scale instead of producing two numbers needing reconciliation.

Two preference shapes, because Chapter 2 asks two kinds of question:

| Shape | Applies to | Scored |
|---|---|---|
| **Matrix** | sect | per-option traffic light, exactly like ch4 |
| **List** | country of birth, nationality, ethnicity, languages | in the preferred list = green; outside it takes the flexibility light |

Languages count as green on **any** shared language — requiring a full match
would score a trilingual candidate worse than a monolingual one.

`skipped` contributes **nothing**, never a default green. Otherwise
declining to answer would raise everyone's score.

A candidate who has not done Chapter 2 contributes nothing rather than being
penalised — scoring absence as a negative would quietly bury every new
joiner.

**Verified with the seeded data** (`onboarding_answers` is empty, so every
point came from Chapter 2 alone — a clean isolation test):

| Candidate | Score |
|---|---|
| Sunni, preferred ethnicity | 100 |
| Sunni, other ethnicity | 90–92 |
| Shia (marked yellow) | 83–85 |
| Other sect (marked red) | 65 |

Hard requirement excludes: 22 of 24 returned, zero red-sect candidates
survived. Backward compatibility holds — a user with neither chapter still
scores everyone 50.0.

**One fixed on the way:** a user who finished Chapter 2 but not Chapter 3
previously fell through the early return and got a flat 50 despite having
told us six things.

**OPEN — needs a Founder decision.** `v_ch2_weight` is set to **1**: one
Chapter 2 attribute counts the same as one Chapter 3 question. But Chapters
3/4 ask ~174 questions and Chapter 2 offers 6 attributes, so at weight 1
Chapter 2 moves the final score by only a few percent. That may understate
sect and ethnicity for this audience. Left at the neutral value rather than
inventing a multiplier — same reasoning as leaving the Guardian scope
narrow. It is a one-line change.

*(Note this understates Chapter 2's real influence: sect carries a hard
requirement, which excludes rather than scores, and no weight applies to an
exclusion.)*

---

## 10. Still open
- **Article 9 solicitor review** of the consent wording, Privacy Policy, Terms and the Compatibility Unlock flow, before public launch. Founder has confirmed this will happen; implementation deliberately did not wait.
- **Payments.** No SDK in the project. Every price is unchargeable.
- **The buy page.** Now owns prices, BEST VALUE, and the free-vs-purchased credit itemisation — three things the spec requires and no screen shows.
- **Compatibility scoring.** Method undefined. When defined, update the worked examples in `APP/Premium/Profile Unlocks/Summary.md` — they assume green=1, amber=0.5, red=0 purely for self-consistency.
- **Matches → Journey → Chat.** Ten `journey_*`/`timeline_*` tables, `matches`, `conversations` and `messages` are **all at zero rows**. The entire path has never executed against real data.
- **Notifications.** Zero rows; the bell is still a placeholder.
- **200 seeded Supabase profiles.** 26 exist. Colour-block versions are behind a dev toggle; real rows need 200 auth accounts.
- **`profiles.bio`** exists and is referenced nowhere. Drop it or use it.
