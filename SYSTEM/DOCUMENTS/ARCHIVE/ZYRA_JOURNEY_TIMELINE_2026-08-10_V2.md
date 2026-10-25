# ZYRA — Journey Timeline · Product Specification

```
Document:  ZYRA_JOURNEY_TIMELINE_CURRENT_VERSION_V2.md
Date:      2026-08-10
Status:    DRAFT FOR FOUNDER APPROVAL — nothing implemented
Supersedes: ZYRA_JOURNEY_TIMELINE_2026-08-10_V1.md
Author:    Claude Opus (Architecture & Implementation Lead)
Source:    Founder architecture brief 2026-08-10; Founder review of V1, same day
Authority: DR-ZYRA-121 (Journey Lifecycle), DR-ZYRA-129 (canonical stage map),
           WALI_ARCHITECTURE V6, ZYRA_ENGINEERING_INVARIANTS V3
```

---

## 0. What changed from V1

| # | V1 said | V2 says | Why |
|---|---|---|---|
| 1 | Ended Journeys viewable forever, collapsed under a heading | **Three presentation states. Ended Journeys leave the default view entirely** | §4 — a list of fifteen endings is the audit log you were avoiding, in nicer type |
| 2 | Main Guardian sees Progress events | **Seeker-only for launch. Decision deferred with a stated reopen point** | §7 — start closed; widening later is a gift, narrowing later is a broken promise |
| 3 | Custom memories: 1/month forever | **Limits change at Nikah** | §5.3 — before Nikah it is a courtship with safety implications; after, it is an album |
| 4 | Milestone titles only | **Every milestone carries one supporting sentence, and some deliberately carry none** | §2 — the reason this document exists |
| 5 | — | **A written voice standard** | §2.1 — copy is the part most likely to be rewritten badly later |

Unchanged and confirmed: story not audit log, absolute dates, `occurred_on`,
per-attempt storage, dual confirmation, no scores, no payment state, no
moderation or safety state, First Message rejected, Families First Met kept,
Contact Details Shared rejected.

---

## 1. Philosophy

> **The Timeline tells the story of the relationship. It is not an audit log.**

| Principle | What it forbids |
|---|---|
| It is a **story**, not a record | No event exists merely because it was easy to capture |
| It is **read by both people**, forever | No event comfortable for one and painful for the other |
| It **survives failure** | Nothing that makes an ended Journey humiliating to re-read |

**The third test is the one that governs this document.** Most Journeys will
not end in nikah. A Timeline designed only for the ones that do becomes cruel
in the majority case — and the majority case is where a matrimonial product
earns or loses its name.

---

## 2. Voice — the part V1 was missing

You were right that V1 was an engineering specification wearing a product
title. An event catalogue is a schema. What makes this screen worth building is
what it *sounds* like at two in the morning, three years later.

### 2.1 The voice standard

Six rules. They exist because supporting copy is the easiest thing in this
document for a future session to rewrite badly with good intentions.

| # | Rule | Why |
|---|---|---|
| 1 | **Past tense, always** | A sentence describing what *happened* stays true. A sentence describing what *is* becomes false the moment it ends. "You can now speak freely" is a lie the day after |
| 2 | **"You both", never names, never he/she** | The name is already at the top of the screen. Repeating it on every line turns an ended Journey into a haunting |
| 3 | **Under ten words** | It is a caption, not a description |
| 4 | **No praise, no encouragement, no promises** | "Well done" and "the best is ahead" are the app talking about itself |
| 5 | **State what happened, never what it meant** | Meaning is theirs. The app does not get to tell two people what their relationship was |
| 6 | **Silence where it hurts** | §2.3 |

**Rule 1 is the load-bearing one.** Your own example — *"Open Conversation · You
can now speak freely together"* — is warm and correct today, and reads as a
taunt on an ended Journey. Rewritten to *"From here, you spoke in your own
words"* it is just as warm and remains true forever. Every sentence below has
been through that test: **read it after the Journey failed.**

### 2.2 The copy

| Milestone | Supporting sentence |
|---|---|
| **Matched** | You each chose the other. |
| **Journey Started** | You both decided to begin. |
| **Compatibility Reveal Completed** | You looked at what you already shared. |
| **Salam Exchange Completed** | You said salaam. |
| **Guardians Connected** | Both families joined you. |
| **Faith & Values Completed** | You talked about what you believe. |
| **Building a Life Completed** | You talked about the life you wanted. |
| **Navigating Life Completed** | You talked about the harder things. |
| **Family Compatibility Completed** | Both families gave their view. |
| **Open Conversation Unlocked** | From here, you spoke in your own words. |
| **First Meeting** | You met in person. |
| **Families First Met** | Your families met each other. |
| **Proposal Accepted** | You said yes. |
| **Nikah Completed** | You were married. |
| **Custom memory** | *(none — their words are the sentence)* |

Two worth defending:

- **"You said salaam."** Four words, and no other product in this category
  could write them. It is the moment the specification's abstraction —
  `salam_exchange` — becomes a thing two people did.
- **"You said yes."** Not "A proposal was accepted", which is minutes of a
  meeting. Three words carrying the whole event.

### 2.3 Where the Timeline says nothing

**Journey Paused · Journey Resumed · Journey Ended · New Journey Started carry
a date and nothing else.**

This is a deliberate design choice, not an omission.

Any sentence under "Journey Ended" is the app editorialising the worst moment
in the relationship. *"This chapter closed"* is a greeting card. *"It wasn't
meant to be"* is presumptuous, and religiously loaded in a way that may be
plainly wrong for the person reading it. *"You ended this journey"* is an
accusation with a date on it.

The correct volume is zero.

> **The Timeline speaks about what two people built, and stays silent about
> what happened to it.**

That silence has to be symmetrical to work. "New Journey Started" is genuinely
hopeful and could carry a lovely line — but a hopeful sentence beside a
wordless ending reads as the app cheering the restart and refusing to
acknowledge the loss. So: **all four management events are dates only.**

### 2.4 Empty and closing states

| State | Copy |
|---|---|
| No milestones yet | **Your story starts here.** |
| Journey ended, viewing later | *(no banner, no prompt, no "Request New Journey" button at the top — the screen is a record, not an offer)* |
| After Nikah | Header becomes **Our Journey**, both first names, and the span of dates |

The ended-Journey rule matters. A "Start again?" prompt on top of a closed
Timeline is the product trying to sell into someone's grief.

---

## 3. Inclusion rule

An event appears on the Shared Timeline only if it satisfies **all four**:

| # | Test | Fails when |
|---|---|---|
| 1 | Mutual or jointly earned | One person acted alone |
| 2 | Represents forward progress | It records a reversal, refusal or absence |
| 3 | Safe to read whether the Journey succeeds or fails | It would sting, expose or accuse in hindsight |
| 4 | Carries no state the other party is not entitled to | It reveals payment, moderation or safety state |

Tests 1–3 are about kindness. **Test 4 is about disclosure, and it is the one
that will be broken by accident**, because the event that breaks it looks
harmless. "Journey Ended" is safe. "Journey Ended — safety concern" undoes work
the database does deliberately: `zyra_match_ending` downgrades `safety_concern`
to `prefer_not_to_say` for everyone but the person who raised it, held by two
CHECK constraints. **The Timeline must never carry `end_reason` in any form.**

Test 3 now applies to **copy as well as event selection** — see §2.1 rule 1.

---

## 4. Ended Journeys — the presentation model

You were right to push back. V1's answer was an archive heading, which is
storage thinking wearing a UX hat.

**The problem, stated properly.** Fifteen endings listed together is not fifteen
stories. It is a record of failure with good typography — the exact artefact
this specification exists to avoid. The philosophy already answers it: *the
Timeline tells the story of **the relationship**.* Singular. The moment the
interface lists relationships side by side, it has stopped being a Timeline and
become a history.

### 4.1 Three states

The app's default view depends on where the person is, not on what data exists.

| State | Default view shows | Earlier Journeys |
|---|---|---|
| **Seeking** | Potential Journeys | One quiet line at the bottom of Connections: *Earlier Journeys* |
| **In a Journey** | The Active Journey only | Same line, one tap away |
| **After Nikah** | **Our Journey** — this relationship, and nothing else | Reachable only from Settings |

### 4.2 The rules

1. **Nothing is deleted, ever.** Your ruling of 2026-08-09 stands: the cap is a
   UI cap, never a data-retention cap. DR-121 item 3 preserves all history.
2. **Every ended Journey stays reachable in two taps** — findable by someone
   looking, invisible to someone not.
3. **No counts.** The entry point reads *Earlier Journeys*, never *Earlier
   Journeys (14)*. A number is a score, and it is a score of failures.
4. **Newest first, and no "outcome" column.** A list that shows how each one
   ended is a table of rejections.
5. **After Nikah the others leave the main surface entirely.** When a Journey
   reaches Nikah Completed, this app has done its job. Continuing to show the
   fourteen that did not work is the product failing to notice it succeeded.

Rule 5 is the one I would fight for. It is the difference between an app that
finished and an app that keeps a ledger.

### 4.3 Multiple attempts with the same person

Distinct from the above, and unchanged from V1: attempts with **one** person are
chapters of **one** story and belong on one screen — *This Journey* · *Our First
Journey*. That is the relationship having a history. Fifteen different people is
not.

---

## 5. Event catalogue

### 5.1 Shared Timeline — the complete permitted set

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
| **Milestones** | First Meeting | Proposed, then confirmed | User |
| | **Families First Met** | Proposed, then confirmed | User |
| | Proposal Accepted | Proposed, then confirmed | User |
| | Nikah Completed | Proposed, then confirmed | User |
| | Custom memory | Both approve | User |
| **Management** | Journey Paused · Resumed · Ended · New Journey Started | System | System |

**Removed from the brief:** *Pre-Journey Ritual Completed* (it **is** the three
stages above it — DR-ZYRA-129 — and a fourth row saying the same thing is the
one that drifts). **Renamed:** *Guardian Connected* → *Guardians Connected*,
fired on the Guardian Gate, because one person linking their own Guardian is
that person's admin and fails test 1.

### 5.2 Rejected and deferred

| Idea | Verdict | Reasoning |
|---|---|---|
| First Message / first reply | ❌ Rejected — **you agreed** | One person typing. "First reply" quietly records who waited longest |
| Contact Details Shared | ❌ Rejected — **you agreed** | Fails test 3 hardest of anything proposed. After a bad ending, a permanent record that you gave someone your number is the most uncomfortable row this screen could hold — and an evidentiary artefact exactly where safety matters most |
| First Voice Call | ⚠️ Deferred | ZYRA has no calling feature, so it is self-reported and unverifiable. Revisit if calling is built and can emit it automatically |
| First Video Call | ⚠️ Deferred | As above, plus: a video-call milestone implies the app sanctions unsupervised video contact, which is a product-position decision far outside a timeline spec |
| Profile Viewed | ❌ Rejected from **both** Timeline and Audit Log | A view log is a surveillance dataset serving no purpose this product has, and it creates an Article 15 disclosure obligation with nothing offsetting it |

### 5.3 Custom memories — limits that change at Nikah

You were right, and the reason is sharper than "couples want more".

**Before Nikah, the Timeline is a courtship record.** Two people who may not
marry are writing into a shared, permanent, unmoderated space. Every constraint
is a safety constraint.

**After Nikah, it is a family album.** The relationship is formalised and
public. The risk that made the limits necessary is largely gone.

| | Before Nikah | After Nikah |
|---|---|---|
| Frequency | 1 per calendar month | **Unlimited** |
| Length | ≤ 80 characters | **≤ 300 characters** |
| Approval | Both must approve | **Both must approve** — unchanged |
| Attachments | None | **None yet** — §8.7 |
| Backdating | Not permitted | **Permitted** — a marriage has a past worth recording |

**Mutual approval never relaxes.** It is not a rate limit, it is what stops the
field being a channel for sending someone something they did not agree to
receive. Frequency and length are comfort. Approval is safety. They are
different things and only one of them changes.

---

## 6. Event metadata

Current schema is `timeline_milestones (id, timeline_id, milestone_type,
occurred_at, metadata jsonb)` with a 7-value CHECK — `match_created`,
`conversation_started`, `family_stage`, `meeting`, `nikah`, `journey_ended`,
`journey_restarted`. It cannot support this specification. **The table holds
zero rows**, so this is a reshape with no migration.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `timeline_id` | uuid | → `timelines` |
| `milestone_type` | text | CHECK against the §5.1 allow-list |
| `occurred_at` | timestamptz | True UTC instant. Internal only |
| **`occurred_on`** | **date** | **Canonical display date. Stamped once, never derived** — §9 |
| `source` | text | `system` \| `user` |
| `created_by` | uuid NULL | NULL for system events |
| `confirmed_by` | uuid NULL | Required before a user event is displayed |
| `confirmed_at` | timestamptz NULL | |
| `superseded_by` | uuid NULL | Correction chain — §8 |
| `note` | text NULL | Custom memories only |

**`metadata jsonb` is dropped.** On a fixed allow-list it is a place for
undeclared fields to accumulate, and every field here carries a visibility rule.

**Supporting sentences are not stored.** They are presentation, derived from
`milestone_type` in one place in the client — the same rule as
DR-ZYRA-129's stage map. Storing them would freeze today's wording into
historical rows and guarantee that improving the copy leaves the old Journeys
reading the old way forever.

---

## 7. Visibility — Guardian decision deferred

| Actor | Sees |
|---|---|
| The two Seekers | The full Shared Timeline |
| **Any Guardian** | **Nothing, at launch** |
| Anyone else | Nothing |
| A blocked party | Still sees the Timeline — §10.4 |

### Why deferred rather than decided

You are right that this depends on where the Guardian model settles, and the
lifecycle question is real: a Guardian's formal involvement is heaviest at the
Guardian Gate and in Family Review, and DR-121 item 11 already makes involvement
**per attempt**, so a Guardian is not a permanent fixture of a relationship.

The deciding argument is not what Guardians need. It is **reversibility**:

| Direction | Cost |
|---|---|
| Launch closed → open later | A feature Guardians gain. Costless |
| Launch open → close later | Access people have had, taken away. Reads as a broken promise, and every Guardian who saw a Timeline has already seen it |

**Choose the option that is cheap to change.** Start closed.

This also avoids repeating audit finding 4.5, where Guardians are *told at
onboarding* they can read the conversation when only the Main Guardian can. Do
not imply Timeline access that does not exist.

**Reopen when:** the Guardian lifecycle is settled and OA-ZYRA-162 (per-attempt
Guardian involvement) is built. **Recorded as an open question, not a rejection.**

Enforced in RLS through a SECURITY DEFINER predicate, never an inline join to
`journey_attempts` — that table has RLS on with zero policies, so any policy
joining it evaluates false for everyone and silently kills the feature.

---

## 8. Editing

| Event source | Create | Correct | Delete |
|---|---|---|---|
| System | Automatic | ❌ Never | ❌ Never |
| User | Propose → other confirms | Propose → other confirms | ❌ Never |

- An unconfirmed proposal **is not on the Timeline**. It shows to the proposer
  only, as *waiting for {name} to confirm*.
- A correction writes a **new row** and sets `superseded_by` on the old one.
  Nothing is updated in place, so the original survives without a history table.
  The Timeline renders the surviving row; the Audit Log holds the chain.
- **Corrections require both people to be active participants.** After an
  ending the Timeline freezes — otherwise a correction can be proposed that can
  never be confirmed, and worse, it becomes a way to contact someone who ended
  the Journey.
- **Verification is dual confirmation and nothing else.** No photographs, no
  documents, no witnesses. That would make the Timeline a moderation surface,
  create a store of nikah documentation ZYRA has no lawful basis to hold, and
  make the app an arbiter of whether a marriage occurred. It is not.
- **The Timeline records agreements, never offers.** Proposal Accepted appears;
  Proposal Sent and Proposal Declined never do. This was already right in your
  brief and is now a stated rule.

---

## 9. Dates

> **"The actual date should never change."**

A UTC timestamp rendered in the viewer's local timezone **does** change.
`2026-08-08T23:30Z` is *8 August* in London and *9 August* in Sydney. Two people
in different countries would see different dates for the same event forever, and
each would be looking at a bug.

| Rule | |
|---|---|
| Store | `occurred_at timestamptz` — the true instant, internal |
| Store | **`occurred_on date` — computed once at creation from the acting participant's local date, then immutable** |
| Display | `occurred_on`, formatted `08 August 2026` |
| Never display | "Yesterday", "2 days ago", "Last week" — no relative time anywhere in the product |
| Never | Derive the display date at render time |

For user-created events the date is **entered by the proposer** and confirmed by
the other. A nikah on 16 August recorded on 18 August reads 16 August, because
that is the date that is true.

---

## 10. Audit Log, and what nobody had raised

**Default is Audit.** The Shared Timeline is an allow-list. Nothing reaches it
by being added anywhere else. The Audit Log is scoped — protection holds,
moderator actions, appeal outcomes, safety endings, Timeline corrections — not a
general activity log. DR-121 item 15 rejects full event sourcing explicitly.

### 10.1 🔴 Account deletion destroys the *other* person's history

`delete_own_account` → `auth.users` → `profiles` CASCADE → `matches` CASCADE →
`timelines` CASCADE. **If one person deletes their account, the survivor loses
the whole record of their own relationship — including their own nikah date.**

Product failure and legal question at once: the Timeline is *joint* data
(OA-ZYRA-155's MINE/THEIRS/JOINT classification exists for this), so one party's
Article 17 erasure right does not straightforwardly extend to erasing the
other's copy.

**Recommendation:** the Timeline survives, with the departed party rendered as a
neutral placeholder and their personal data removed. The events happened; the
person is gone. **Needs legal input** — add to the three existing solicitor
questions.

### 10.2 A Timeline will be treated as a nikah record

*"Nikah Completed · 16 August 2026"* will be screenshotted and shown to
families, and eventually to someone wanting proof. ZYRA is not a registrar and
this is self-reported with no verification, by design.

**Recommendation:** one quiet line on any export — *A personal record, not a
legal document.* Cheap now, very expensive once people rely on it.

### 10.3 "Journey Ended" must never carry a reason

§3, restated because it is the likeliest accidental breach.

### 10.4 What a blocked person sees

**The Timeline stays visible to both.** Blocking closes the channel
(DR-ZYRA-131); the Timeline is history, not a channel. Hiding it deletes
someone's own past as a side effect of another person's action — and the
disappearance would itself reveal the block.

### 10.5 Export contains another living person's data

**Both parties consent at the time of export.** Consent to the Journey is not
consent to a durable artefact. If the other has deleted their account, export is
available in the anonymised form of §10.1.

### 10.6 Custom memories are a free-text channel

Mutual approval is the control — §5.3. Nothing reaches the other person's
Timeline without them agreeing to it, so it cannot be used to send them
anything.

### 10.7 Photographs, when they come

The obvious next request after §5.3 is photos in post-Nikah memories. Flagging
before it is asked: photos add a moderation surface, storage cost, an Article 15
export obligation, and a CSAM-scanning duty. **Not a "later polish" item — its
own decision.**

---

## 11. Decisions needed from you

| # | Decision | Recommendation |
|---|---|---|
| 1 | The §2.2 copy, as written | Approve, or redline line by line |
| 2 | **§2.3 — endings carry no sentence at all** | Approve. The strongest opinion in this document |
| 3 | §4 three-state model, incl. **everything else leaving the main surface after Nikah** | Approve |
| 4 | §7 — Guardians see nothing at launch, revisit after OA-162 | Approve |
| 5 | §5.3 — limits relax at Nikah, approval never does | Approve |
| 6 | Drop *Pre-Journey Ritual Completed*; rename to *Guardians Connected* | Approve |
| 7 | Stop recording profile views entirely | Approve |
| 8 | Add §10.1 to the solicitor questions | Approve |

---

## 12. Recommended final model

```
timelines            one per journey_attempt          (UNIQUE attempt_id)
  └── timeline_milestones
        allow-list: 14 system + 4 user + custom memories
        occurred_at   timestamptz  true instant, internal
        occurred_on   date         canonical, stamped once, displayed
        source        system | user
        created_by / confirmed_by  user events only
        superseded_by              correction chain; nothing updated in place
        note          custom memories only

supporting copy      NOT stored. one map in the client, like the stage map.

audit_log            everything else. append-only. never user-visible.
```

**Presentation:** one relationship per screen. Attempts as chapters, newest
first. Every row an absolute date. Every milestone one short past-tense
sentence — except pause, resume, end and new-journey, which carry a date and
nothing else.

**Default view forward.** Earlier Journeys two taps away, no count, no outcomes.
After Nikah, this relationship is the app.

---

## 13. Scope

Not an estimate — a scope statement, per the six-layer rule. **Layers 1, 2, 3, 4
and 6 read against the live database 2026-08-10. Layer 5 read only for the
existing timeline screen.**

| Work | Note |
|---|---|
| `timelines` → `UNIQUE (attempt_id)` | **Shared with OA-ZYRA-159 stage 4** — one change, two features |
| `timeline_milestones` reshaped | Table is empty. No data migration |
| Milestone emission at 14 system points | Mostly inside existing RPCs |
| Dual-confirmation RPCs | Same shape as Request New Journey |
| RLS predicate | Seeker-only is the simplest version this will ever have |
| Timeline screen rebuild | Copy map, three presentation states, chapters |

**Risk named:** the existing screen's `_labelFor` is a second stage vocabulary
living outside the canonical map — `match_created`, `conversation_started`,
`family_stage`, `meeting`, `nikah`. It is the exact defect class DR-ZYRA-129
closed, and it survived that decision because nobody was looking at this screen.
**It must be deleted, not extended.**
