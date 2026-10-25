# ZYRA — Journey Timeline · Product Specification

```
Document:  ZYRA_JOURNEY_TIMELINE_CURRENT_VERSION_V1.md
Date:      2026-08-10
Status:    DRAFT FOR FOUNDER APPROVAL — nothing implemented
Author:    Claude Opus (Architecture & Implementation Lead)
Source:    Founder architecture brief, 2026-08-10
Authority: DR-ZYRA-121 (Journey Lifecycle), DR-ZYRA-129 (canonical stage map),
           WALI_ARCHITECTURE V6, ZYRA_ENGINEERING_INVARIANTS V3
```

---

## 0. Read this part if you read nothing else

- **Your brief is adopted essentially whole.** The philosophy, the three-part
  inclusion test, the Timeline/Audit split and the absolute-dates rule are all
  correct and are specified below as written.
- **Four things in the brief need your decision before this can be built** —
  §11. Two are redundancies inside your own event list, one is a rule that
  contradicts an approved decision, and one is a technical consequence of the
  date rule that changes the schema.
- **Six things nobody has raised yet** — §10. The most serious: if one person
  deletes their account, today's schema **destroys the other person's copy of
  their own relationship history**. That is both a product failure and an
  Article 15 problem.
- **Your decision 2 also unblocks OA-ZYRA-159 stage 4**, which is currently
  parked on exactly this question. One answer settles both.
- Nothing here is built. `timeline_milestones` holds **zero rows**, so this is
  a specification against an empty table — the cheapest possible moment.

---

## 1. Philosophy

> **The Timeline tells the story of the relationship. It is not an audit log.**

Adopted from the brief without amendment. Three consequences follow, and they
should be treated as binding rather than aspirational:

| Principle | What it forbids |
|---|---|
| The Timeline is a **story**, not a record | No event exists merely because it was easy to capture |
| It is **read by both people**, forever | No event that is comfortable for one and painful for the other |
| It **survives failure** | Nothing that would make an ended Journey humiliating to re-read |

**The test that matters most is the third.** Most Journeys will not end in
nikah. A Timeline designed only for the ones that do is a Timeline that becomes
cruel in the majority case — and the majority case is where a matrimonial
product earns or loses its reputation.

---

## 2. Inclusion rule

An event appears on the Shared Timeline only if it satisfies **all three**:

| # | Test | Fails when |
|---|---|---|
| 1 | **Mutual or jointly earned** | One person acted alone |
| 2 | **Represents forward progress** | It records a reversal, refusal or absence |
| 3 | **Safe to read whether the Journey succeeds or fails** | It would sting, expose or accuse in hindsight |

Anything failing any test goes to the Audit Log.

**A fourth test is implied by the brief and should be made explicit:**

| 4 | **Carries no state the other party is not entitled to** | It reveals payment, moderation or safety state |

Tests 1–3 are about kindness. Test 4 is about disclosure, and it is the one
that will be broken by accident — because the event that breaks it usually
looks harmless. "Journey Ended" is safe; "Journey Ended — safety concern" is a
disclosure the database already works hard to prevent (`zyra_match_ending`
downgrades `safety_concern` to `prefer_not_to_say` for everyone but the person
who raised it, backed by two CHECK constraints). **The Timeline must never
carry `end_reason` in any form.**

---

## 3. Event catalogue

### 3.1 Shared Timeline — the complete permitted set

| Group | Event | Trigger | Source |
|---|---|---|---|
| **Beginning** | Matched | Mutual Consider creates the match | System |
| | Journey Started | Attempt moves to `active` | System |
| | Compatibility Reveal Completed | Both revealed | System |
| | Salam Exchange Completed | Stage passed | System |
| | Guardians Connected | Guardian Gate passed — **both** sides | System |
| **Progress** | Faith & Values Completed | `phase_1` passed | System |
| | Building a Life Completed | `phase_2` passed | System |
| | Navigating Life Completed | `phase_3` passed | System |
| | Family Compatibility Completed | `family_stage` passed | System |
| | Open Conversation Unlocked | Reached `conversation` | System |
| **Milestones** | First Meeting | Proposed by one, confirmed by other | User |
| | Proposal Accepted | Proposed by one, confirmed by other | User |
| | Nikah Completed | Proposed by one, confirmed by other | User |
| **Management** | Journey Paused | Pause recorded | System |
| | Journey Resumed | Resume recorded | System |
| | Journey Ended | Attempt ends — **no reason, ever** | System |
| | New Journey Started | Attempt n+1 begins | System |

**Nineteen events. Deliberately small.** Every addition costs more than it
appears to: each one is a row two people will read after a Journey has failed.

### 3.2 Removed from the brief, with reasons

| Proposed | Verdict | Why |
|---|---|---|
| **Pre-Journey Ritual Completed** | ❌ Remove | It IS the three events above it. The Pre-Journey Ritual is `compatibility_reveal` + `salam_exchange` + `wali_gate` (DR-ZYRA-129). Keeping all four means the Timeline says the same thing twice, and the fourth row is the one that will drift |
| **Guardian Connected** (singular) | ✏️ Renamed to **Guardians Connected** | One person linking their Guardian is that person's admin — it fails test 1. The Guardian *Gate* passing requires a Main Guardian on **both** sides (live behaviour, `zyra_advance_stage`), which is jointly earned |

### 3.3 The "additional ideas", assessed

| Idea | Verdict | Reasoning against the three tests |
|---|---|---|
| **Families First Met** | ✅ **Include** | Passes all three, and it is arguably the most meaningful event in the whole catalogue for this product. In a marriage process the families meeting *is* the milestone. Same dual-confirmation as First Meeting |
| **First Voice Call** | ⚠️ **Defer** | Passes 1–3, but ZYRA has no calling feature — so it is self-reported, unverifiable, and adds a third "did we do the thing" prompt. Revisit if calling is ever built and can emit it automatically |
| **First Video Call** | ⚠️ **Defer** | As above. Also: a video-call milestone implies the app sanctions unsupervised video contact, which is a product-position question well outside a timeline spec |
| **Contact Details Shared** | ❌ **Reject** | Fails test 3. If the Journey later ends badly, a permanent record that you gave someone your number is the single most uncomfortable row this Timeline could hold. It also creates an evidentiary artefact in exactly the situation where safety matters most. Belongs in the Audit Log, if anywhere |
| **Couple-approved custom memories** | ✅ **Include, with a hard cap** | Passes all three when both approve — it is the only event type that lets the Timeline be *theirs*. Cap at **one per calendar month per Journey**, free text ≤ 80 characters, no attachments. Without a cap it becomes a chat log with extra steps, and attachments make it a moderation surface |
| **Timeline export after Nikah ("Our Journey")** | ✅ **Include, gated** | Genuinely lovely and clearly wanted. But it exports **another living person's data**, so it needs that person's consent at export time — not their consent implied by having been in the Journey. See §10.5 |

---

## 4. Audit Log — the other half

Everything in the brief's exclusion list, plus everything not in §3.1. Stated
as a rule rather than a list, because a list will fall behind:

> **Default is Audit. The Shared Timeline is an allow-list of exactly nineteen
> event types plus the two user-authored additions. Nothing reaches the Timeline
> by being added to the Audit Log.**

| Property | Shared Timeline | Audit Log |
|---|---|---|
| Visible to | Participants (§6) | Nobody in-product |
| Curated | Yes — allow-list | No — everything |
| Retention | Permanent | Per retention policy |
| Mutability | System events immutable; user events correctable | Append-only, never corrected |
| Purpose | The story | Investigation, moderation, legal |

**Scoped, not comprehensive** — DR-ZYRA-121 item 15 explicitly rejects full
event sourcing as over-engineering. The Audit Log is protection holds,
moderator actions, appeal outcomes, safety endings, and the Timeline
corrections in §7. It is **not** a general activity log, and "Profile Viewed"
should not be captured anywhere: a view log is a surveillance dataset that
serves no purpose this product has, and creates a disclosure obligation under
Article 15 that nothing offsets.

**This is a correction to the brief.** The brief lists "Views" under the Audit
Log. Recommend: do not record profile views at all.

---

## 5. Event metadata

Current schema is `timeline_milestones (id, timeline_id, milestone_type,
occurred_at, metadata jsonb)` with a 7-value CHECK. It cannot support this
spec. Required shape:

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `timeline_id` | uuid | → `timelines` |
| `milestone_type` | text | CHECK against the §3.1 allow-list |
| `occurred_at` | timestamptz | Full UTC instant. Internal |
| **`occurred_on`** | **date** | **The canonical display date. Stamped once, never derived** — see §8 |
| `source` | text | `system` \| `user` |
| `created_by` | uuid NULL | NULL for system events |
| `confirmed_by` | uuid NULL | Required for user events before display |
| `confirmed_at` | timestamptz NULL | |
| `superseded_by` | uuid NULL | Correction chain — §7 |
| `note` | text NULL | Custom memories only, ≤ 80 chars |

`metadata jsonb` should be **dropped**. A jsonb column on a
nineteen-event allow-list is a place for undeclared fields to accumulate, and
every field that matters here has a visibility rule attached to it.

---

## 6. Visibility

| Actor | Sees |
|---|---|
| The two Seekers | The full Shared Timeline |
| Main Guardian | **Progress events only** — Beginning + Progress groups |
| Non-Main Guardian | Nothing |
| Anyone else | Nothing |
| A blocked party | **Still sees the Timeline** — see §10.4 |

Enforced in RLS via a SECURITY DEFINER predicate, never by an inline join to
`journey_attempts` — that table has RLS on with zero policies, so any policy
joining it evaluates false for everyone and silently kills the feature.

---

## 7. Editing

| Event source | Create | Correct | Delete |
|---|---|---|---|
| System | Automatic | ❌ Never | ❌ Never |
| User | Propose → other confirms | Propose → other confirms | ❌ Never |

- A proposed-but-unconfirmed event **is not on the Timeline**. It appears to
  the proposer only, as *"waiting for {name} to confirm"*.
- A correction creates a **new row** and sets `superseded_by` on the old one.
  The Timeline renders only the surviving row; the Audit Log retains the chain.
  Nothing is ever updated in place, so the original value survives without a
  separate history table.
- **Corrections are only possible while both people are active participants.**
  After an ending, the Timeline freezes. Otherwise a correction can be proposed
  that can never be confirmed, leaving a permanently pending row — and worse,
  it becomes a way to contact someone who has ended the Journey.

---

## 8. Dates

Adopted from the brief and made precise, because the brief's rule has a
consequence it does not state:

> **"The actual date should never change."**

A UTC timestamp rendered in the viewer's local timezone **does** change. A
milestone stamped `2026-08-08T23:30Z` is *8 August* in London and *9 August* in
Sydney. Two people in different countries would see different dates for the
same event, forever, and each would be looking at a bug.

**Therefore:**

| Rule | |
|---|---|
| Store | `occurred_at timestamptz` — the true instant, internal only |
| Store | **`occurred_on date` — computed ONCE at creation, from the acting participant's local date, then immutable** |
| Display | `occurred_on`, formatted `08 August 2026` |
| Never display | "Yesterday", "2 days ago", "Last week" — no relative text anywhere |
| Never | Derive the display date from `occurred_at` at render time |

For user-created events the date is **entered by the proposer** and confirmed
by the other — a nikah on 16 August that is recorded on 18 August reads 16
August, because that is the date that is true.

---

## 9. Architecture decisions — recommendations

### D1 · Should Guardians see the Timeline?

**Recommendation: Main Guardian sees Progress events only. Not the full
Timeline.**

The Beginning and Progress groups are the process — a Guardian is a real
participant in it, gates it, and votes in Family Review. Showing them is
consistent with what a Guardian is for.

The Milestones group is different. First Meeting, Families First Met and custom
memories are the couple's account of their own relationship. On 2026-08-08 this
project measured a Guardian arrangement producing a **six-person mutual-
visibility clique, gender-blind, four of whom had appointed nobody**, and
closed it by making clause 3 Seeker-only and `is_main` a real privilege
boundary. Handing every Guardian the couple's memories would walk that back.

**Non-Main Guardians see nothing**, consistent with `messages_select`. Note
audit finding 4.5: Guardians are currently *told at onboarding* they can read
the conversation when only Main can — do not repeat that pattern by implying
Timeline access that does not exist.

### D2 · Per relationship, or per Journey attempt?

**Recommendation: stored per attempt, presented as one relationship.**

This is the only answer that satisfies both your philosophy and DR-ZYRA-121.

| | |
|---|---|
| **Storage** | `timelines.attempt_id`, one timeline per attempt. Satisfies DR-121 item 2 — "each attempt carries its own timeline" — and OA-159's "never a resurrection… a new attempt starts fresh" |
| **Presentation** | The screen shows every attempt for the pair, newest first, under headings: *This Journey* · *Our First Journey* |
| **Result** | A fresh start is genuinely fresh — the new attempt does not inherit the old conversation or the old Guardian's involvement (OA-162) — while the story of the relationship is still legible |

**This also unblocks OA-ZYRA-159 stage 4.** That work is parked precisely
because `timelines` and `conversations` both hold `UNIQUE (match_id)`, capping
them at one per pair forever. Answering D2 this way requires moving both to
`UNIQUE (attempt_id)` — the six-touch-point change already scoped. **One
decision, two problems solved.**

### D3 · Salam Exchange and First Message — one milestone or two?

**Recommendation: two milestones, and "First Message" is not one of them.**

Keep **Salam Exchange Completed** (a ritual stage, jointly completed) and
**Open Conversation Unlocked** (the structure lifting). Both are joint.

A first message is one person typing. It fails test 1 until the other replies —
and "first reply" as a milestone quietly records who spoke first and how long
the other took, which fails test 3. The unlock is already the joint event; the
message adds nothing the unlock does not say.

### D4 · How are offline milestones verified?

**Recommendation: dual confirmation and nothing else. No evidence, ever.**

Propose → the other confirms → it appears. Same consent shape as Request New
Journey, for the same reason: an event about two people should not be
assertable by one.

**Explicitly reject** photo, document or witness verification. It would turn
the Timeline into a moderation surface, create a store of nikah documentation
ZYRA has no lawful basis to hold, and make the app an arbiter of whether a
marriage occurred. It is not.

Unconfirmed proposals do not expire — unlike a Journey request there is no
pressure and no harm in one sitting. They are simply invisible until confirmed.

Note your own list is already right about this: **Proposal Accepted** is on the
Timeline while **Proposal Sent** and **Proposal Declined** are internal. Only
the mutual positive outcome surfaces. That is the correct instinct and it
should be stated as a rule: *the Timeline records agreements, never offers.*

### D5 · Do ended Journeys stay viewable?

**Recommendation: viewable forever. Archived is a UI state, never a data
state.**

This follows your own ruling of 2026-08-09 — *"The cap is purely a UI cap, not
a data-retention cap. I never want Journey history deleted automatically"* —
and DR-121 item 3, which preserves all Journey history.

Older Journeys collapse under *Earlier Journeys* in the UI. Nothing is deleted
by time. Erasure happens only on an explicit Article 17 request, which is a
separate, deliberate path — see §10.1.

### D6 · What has not been considered?

Six things. §10.

---

## 10. Not yet considered

### 10.1 🔴 Account deletion destroys the *other* person's history

`delete_own_account` → `auth.users` → `profiles` CASCADE → `matches` CASCADE →
`timelines` CASCADE. **If one person deletes their account, the surviving
person loses the entire record of their own relationship**, including their own
nikah date.

This is a product failure and a legal question at once: the Timeline is *joint*
data (OA-ZYRA-155's MINE/THEIRS/JOINT classification exists for this), so one
party's Article 17 erasure right does not straightforwardly extend to erasing
the other's copy.

**Recommendation:** on deletion, the Timeline survives with the departed party
rendered as a neutral placeholder, and their personal data removed from it. The
events happened; the person is gone. This needs legal input before it is built
and should be added to the three existing solicitor questions.

### 10.2 A Timeline will be treated as a nikah record

*"Nikah Completed · 16 August 2026"* in an app will be screenshotted and shown
to families, and eventually to someone who wants proof. ZYRA is not a registrar
and this is self-reported by two people with no verification by design (D4).

**Recommendation:** an explicit, quiet line on any nikah export — *"A personal
record, not a legal document."* Cheap now; very expensive to retrofit once
people are relying on it.

### 10.3 "Journey Ended" must never carry a reason

Covered in §2, restated here because it is the most likely accidental breach.
The database goes to real lengths to conceal safety endings. A Timeline that
records *why* a Journey ended undoes that in one column.

### 10.4 What does a blocked person see?

**Recommendation: the Timeline stays visible to both.** Blocking closes the
channel (DR-ZYRA-131); the Timeline is history, not a channel. Hiding it would
delete someone's own past as a side effect of the other person's action — and
the disappearance would itself reveal the block, which the block model works to
avoid.

### 10.5 Export contains another living person's data

The "Our Journey" export is a portability artefact about two people.

**Recommendation:** export requires **both** parties to consent at the time of
export. Consent to the Journey is not consent to a durable artefact. If the
other party has deleted their account, export is available in the anonymised
form of §10.1.

### 10.6 Custom memories are an unmoderated free-text channel

Any free-text field two people can write into is a messaging channel and a
harassment surface.

**Recommendation:** the §3.3 cap — one per month, ≤ 80 characters, no
attachments, **both must approve before it appears**. Mutual approval is what
makes it safe: nothing reaches the other person's Timeline without them
agreeing to it, so it cannot be used to send them anything.

---

## 11. Decisions needed from you

| # | Decision | Recommendation |
|---|---|---|
| 1 | Remove **Pre-Journey Ritual Completed** as a duplicate of its three constituent stages? | Remove |
| 2 | Rename **Guardian Connected** → **Guardians Connected**, fired on the Guardian Gate rather than on an individual link? | Rename |
| 3 | **Stop recording profile views entirely**, rather than logging them internally? | Stop |
| 4 | Adopt **`occurred_on`** as a stored date so the displayed date is identical for both people forever? | Adopt |
| 5 | D1–D5 above, as recommended? | As recommended |
| 6 | Add §10.1 (deletion) to the solicitor questions? | Add |

---

## 12. Recommended final model

```
timelines            one per journey_attempt        (UNIQUE attempt_id)
  └── timeline_milestones
        allow-list of 19 system + 2 user event types
        occurred_at  timestamptz   true instant, internal
        occurred_on  date          canonical, stamped once, displayed
        source       system | user
        created_by / confirmed_by  user events only
        superseded_by              correction chain, nothing updated in place

audit_log            everything else. append-only. never user-visible.
```

**Presentation:** one screen, newest attempt first, each attempt a titled
section. System events immutable. User events proposed and confirmed. Every row
shows an absolute date. No relative time anywhere in the product.

---

## 13. What this costs

Not an estimate — a scope statement, per the six-layer rule. **Layers 1, 2, 3,
4 and 6 were read against the live database on 2026-08-10. Layer 5 (client) was
read only for the existing timeline screen.**

| Work | Note |
|---|---|
| `timelines` → `UNIQUE (attempt_id)` | Shared with OA-159 stage 4 |
| `timeline_milestones` reshaped | Table is **empty** — no data migration |
| Milestone emission at 9 system points | Mostly inside existing RPCs |
| Dual-confirmation RPCs | Same shape as Request New Journey |
| RLS + Guardian predicate | Must not join `journey_attempts` inline |
| Timeline screen rebuild | Existing screen is a flat list with its own hardcoded label map — that map must go, per DR-ZYRA-129 |

**Risk named:** the existing screen's `_labelFor` is a second stage vocabulary
living outside the canonical map. It is exactly the defect class DR-ZYRA-129
was written to close, and it survived that decision because nobody was looking
at this screen. It must be deleted, not extended.
