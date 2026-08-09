# ZYRA — Guardian Relationship: Six-Layer Dependency Review

**Status:** IMPLEMENTED — Founder-approved 2026-08-06, built same day
**Date:** 2026-08-06 · **Standard:** `SIX_LAYER_REVIEW_STANDARD_CURRENT_VERSION_V1.md`
**Scope:** Guardian **relationship** only. Guardian **gender** is explicitly
out of scope — separate governance review.

**Enum decision:** code `uncle`, label **"Paternal Uncle"** (Founder,
2026-08-06). V6 and Guardian onboarding both display "Paternal Uncle" and
neither needed changing, because the code is not the label.

---

## What the estimate got wrong — measured, not remembered

Per the Six-Layer Standard, the review's own numbers are checked against
what implementation actually required.

| Layer | Review said | Actually | Why |
|---|---|---|---|
| Schema | 1 column | 1 column | ✓ |
| RLS | 0 policy changes | 0 | ✓ — the first layer this standard has ever got exactly right |
| RPCs | **4** change | **3** | `zyra_dev_set_guardian_suggestions` writes `wali_suggestions` and only READS `wali_id`. Counted from a grep for the table name; corrected by reading the body |
| Triggers | 0 | 0 | ✓ |
| Client | 9 files | 9 files | ✓ |
| Docs | 3 | **4** | `ZYRA_DATABASE_SCHEMA` was also missing `is_main`, added 2026-08-01 and never documented |

**The direction reversed.** Every prior estimate under-counted (15→19
policies, 1→4 patterns, 9→9+11). This one over-counted RPCs and
under-counted docs. The common cause is unchanged and worth stating plainly:
**a grep for a table name finds everything that mentions it, not everything
that depends on it.** Reading the eleven RPC bodies is what separated the
three that write from the eight that only read — and reading them is also
what caught the schema document being wrong about a different column
entirely.

### Three things implementation found that the review did not

1. **`accept_wali_invite` and `guardians_for_unlocked` both needed DROP,
   not CREATE OR REPLACE** — one gains a parameter, the other a return
   column, and neither is a "replace". **Dropping a function discards its
   grants.** Both were re-granted explicitly and the ACLs verified identical
   to their pre-change state. The review did not flag this; it should have,
   and the standard's RPC layer now needs a "does the signature change?"
   question.
2. **The old dev fixture read `'Paternal uncle'`** — lowercase *u*, a label
   where a code belongs. It would have matched nothing. Nobody noticed
   because until today those fixtures were the only source of a relationship
   anywhere in the app.
3. **`_RelationshipOption` had to be duplicated**, not shared. The original
   is library-private to `wali_onboarding_flow.dart`, and onboarding is
   ringfenced by the Founder's instruction. Noted in the code for whenever
   onboarding is next opened on its own merits.

### Verified after implementation

| Check | Result |
|---|---|
| Column, CHECK, ownership comment | present, all 7 codes |
| `guardians_for_unlocked` return type | gained `relationship`, appended |
| Function ACLs after DROP/CREATE | identical to before |
| Caller **with** a Plus unlock | sees `Abdul/father`, `Hassan/uncle` |
| Caller **without** an unlock | 0 rows via RPC, 0 direct, no value visible |
| CHECK rejects a display label | `'Paternal uncle'` refused, rows unchanged |
| Live links backfilled | **none** — 16 links, still null, as instructed |

`flutter analyze` is the Founder's to run; the sandbox has no Flutter
toolchain. The repo's own static checker reports clean.

### Revised on first sight of it — display format

The plan said city was **replaced**. Built that way, then shown to the
Founder, who said: *"I thought we said it should say Abdul - area -
relationship."*

Both are now shown: **`Abdul · Father · Birmingham`**. Parts that are
missing are skipped rather than leaving empty separators, so a link with no
relationship yet degrades to `Abdul · Birmingham` — the old line.

**That fallback is the part that mattered.** The replace-only version
dropped to a bare name when relationship was null, and since nothing
backfills relationship, fifteen of sixteen links displayed LESS than they
had the day before. A first build can be correct against the plan and still
be a regression on screen; this one was.

This also closes the data-minimisation question below: `location_text` is
displayed, so disclosing it is deliberate.

### Still open

Nothing on this feature. Two items belong to other work:

- **Guardian gender governance review** (Founder-ordered, separate) —
  seeded data contains a female Guardian, "Khadija", while
  `createWaliProfile` still hardcodes `gender: 'male'`. Evidence for that
  review, not a defect to fix here.
- **`NOT NULL` on `relationship`** once every real link has been asked.
  Test-account links are seeded; real ones are deliberately untouched.

---

## Headline: the question is already being asked

`wali_onboarding_flow.dart` step 2 asks every Guardian their relationship,
with a fixed list:

```dart
static const _relationships =
  ['Father', 'Grandfather', 'Brother', 'Paternal Uncle', 'Other'];
```

The answer goes to `AppState.waliRelationship` — **in memory only** — and is
displayed back to the Guardian on their own profile as *"Relationship:
Father"*.

**It is never written to the database.**

This is the third instance of the same defect class: `profile_complete`
(July), `location_text` (2026-08-04), and now this. A value collected, shown
on screen, and never persisted — invisible because the only accounts anyone
looked at had it set in memory during that session.

**Consequence for the plan.** The proposal said "add a question at Guardian
acceptance." That is no longer the right shape. **The capture exists; the
write does not.**

### But onboarding is the wrong place to store it

A Guardian can be linked to several Seekers, and the relationship differs
per Seeker — father to a daughter, uncle to a niece. One value on the
Guardian's profile cannot express that.

**Relationship belongs on `wali_links`, per link** — as the Founder
specified. The onboarding answer becomes a sensible **default**, prefilled
at acceptance, not the stored truth.

### Enum reconciliation

| Onboarding today | Founder-approved | WALI_ARCHITECTURE V6 |
|---|---|---|
| Father | father | Father |
| Grandfather | grandfather | *(not listed)* |
| Brother | brother | Brother |
| **Paternal Uncle** | **uncle** | **Paternal Uncle** |
| Other | other | "other eligible male guardian" |
| — | legal_guardian | exceptional cases, deferred |
| — | family_representative | exceptional cases, deferred |

**One decision needed:** V6 and the existing UI both say **Paternal**
Uncle — specific, and religiously meaningful. The approved enum says
`uncle`. Recommend `paternal_uncle`, matching the ratified document and the
question users already answer.

---

## Layer 1 — Schema

| Object | Change |
|---|---|
| `wali_links` | **+ `relationship text`**, CHECK-constrained, nullable |
| `wali_invites` | none — relationship is per *link*, not per *invite* |
| `wali_suggestions` | none |
| `profiles` | none — **gender out of scope** |

Nullable is forced, not chosen: two live rows exist whose relationship is
genuinely unknown. Founder: do not guess or backfill.

---

## Layer 2 — RLS · 13 policies read `wali_links`

`wali_links_select/insert/update` · `wali_invites` ×3 ·
`wali_suggestions` ×3 · `matches_select` ·
`seeker_details_select_guardian` · plus the Journey policies reaching it
through `zyra_attempt_participant_rows`.

**No policy changes.** None enumerate columns, so a new column inherits the
existing row-level rules. Verified by reading all thirteen — not assumed
from the count.

---

## Layer 3 — RPCs · 11 read `wali_links`

| RPC | Change | Why |
|---|---|---|
| `accept_wali_invite` | **YES** | Writes the link. Must accept and store relationship |
| `guardians_for_unlocked` | **YES** | Add `relationship` to the return type |
| `zyra_dev_set_guardians_on_decided` | **YES** | Dev seeder — would create relationship-less links |
| `zyra_dev_set_guardian_suggestions` | **YES** | Same |
| `reopen_family_review` | no | reads `is_main` only |
| `resolve_family_review_if_due` | no | reads `is_main` only |
| `wali_review_decision` | no | reads `is_main` only |
| `wali_has_wali_one` | no | reads `wali_id` only |
| `zyra_attempt_summary_for_guardian` | no | reads `wali_id` only |
| `zyra_can_view_profile` | no | reads `wali_id` only |
| `auto_designate_main_wali` *(trigger)* | no | reads `is_main` only |

**Role and relationship stay separate throughout** — every "no" above reads
`is_main` or `wali_id`, never both concepts as one.

---

## Layer 4 — Triggers

`auto_designate_main_wali` — sets `is_main` on the first active link. Reads
role, not relationship. **No change.**

---

## Layer 5 — Client · 21 files matched, **9 genuinely affected**

### Must change

| File | Why |
|---|---|
| `zyra_wali_link_service.dart` | `WaliLinkedPerson` model; `fetchLinkedPeople` does not select relationship; accept path must send it |
| `zyra_guardian_info_service.dart` | `GuardianInfo` + **`displayLine`** — the `firstName · city` format Founder wants replaced |
| `accept_wali_invite_screen.dart` | Capture point — prefilled from the onboarding answer |
| `profile_unlock_screen.dart` | Renders `g.displayLine`; city → relationship |
| `seeker_wali_tab.dart` | **Already renders `person.relationship`** — currently always null for real Guardians |
| `wali_profile_screen.dart` | Shows the Guardian their own relationship from `AppState` |
| `app_state.dart` | `waliRelationship`, `saveWaliOnboarding` — becomes a default rather than truth |
| `zyra_dev_scenario.dart` | `fakeGuardians` hardcode 'Father' / 'Brother' / 'Paternal uncle' — must match the enum exactly, or dev data will not round-trip |
| `wali_onboarding_flow.dart` | `_relationships` list must become the shared reference list |

### Matched but NOT affected — checked, not assumed

`help_content.dart`, `journey_questions.dart`, `wali_onboarding_flow` *(prose
use of the word)*, `browse_screen.dart`, `connections_screen.dart`,
`zyra_auth.dart`, `zyra_journey_service.dart`, `zyra_wali_journey_service.dart`,
`wali_seekers_screen.dart`, `wali_dashboard_screen.dart` *(render `firstName`
only)*, `developer_access_screen.dart` *(seeds `waliRelationship: 'Father'`
into AppState — harmless, but will drift once the DB is authoritative)*.

---

## Layer 6 — Documentation

| Document | Action |
|---|---|
| `WALI_ARCHITECTURE_CURRENT_VERSION_V6` | Source of the eligible list. **Enum must match it**, including *Paternal* Uncle |
| `ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1` | Add the column |
| `ZYRA_JOURNEY_FIELD_CLASSIFICATION_V2` | New column needs an OWNERSHIP comment in its own migration |
| `WALI_REQUIREMENT_AND_ACCESS_POLICY_V1` | **Untouched** — its open questions are the separate governance review |

---

## Dependency review — what points at this

| Question | Answer |
|---|---|
| Which **RPCs** consume it? | 4 change, 7 unaffected — enumerated above |
| Which **client code**? | 9 of 21 matched files |
| Which **documentation**? | 3 updated, 1 deliberately not |
| Which **policies, views, grants**? | 13 policies read `wali_links`; **none change** |
| Which **approved-but-unbuilt** architecture? | Family Review (OA-162) shows Guardians per attempt — will want relationship. Request New Journey (OA-159) does not |
| Anything else? | **`AppState.waliRelationship` is a second store for the same fact.** After this it must become a prefill default, or the two will disagree |

### Two risks worth stating

**1. Two sources of truth, temporarily.** `AppState.waliRelationship` (per
Guardian) and `wali_links.relationship` (per link) will both exist. The
first must be demoted to a default at the same time the second is
introduced, or a Guardian linked to two Seekers will see one answer on their
profile and a different one on a Seeker's screen.

**2. Dev fixtures must match the enum exactly.** `fakeGuardians` uses
`'Paternal uncle'` — lowercase *u*, and a label rather than a code. Under
**store the code, never the label** these become `paternal_uncle`. If they
are not updated together, dev Guardians will render blank and look like the
feature is broken.

---

## Ready to build once you confirm

1. **`uncle` or `paternal_uncle`?** Recommend the latter — matches V6 and
   the question Guardians already answer.
2. **Confirm the onboarding answer becomes a prefill default**, with the
   per-link value authoritative.
