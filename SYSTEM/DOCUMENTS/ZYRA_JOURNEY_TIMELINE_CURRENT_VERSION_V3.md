---
id: DOC-ZYRA-0220
type: SPEC
status: CURRENT
feature: JOURNEY
purpose: ZYRA — Journey Timeline · Product Specification
links: []
owner: ZYRA chat
---

# ZYRA — Journey Timeline · Product Specification

```
Document:   ZYRA_JOURNEY_TIMELINE_CURRENT_VERSION_V3.md
Date:       2026-08-10
Status:     APPROVED — Founder, 2026-08-10. All seven §15 decisions approved,
            §12 resolved as option C. AS-APPLIED 2026-08-12 stewardship pass: milestones are now WRITTEN — trigger `matches_record_journey_milestone` (migration 20260811102840, dedupe guard 20260811233755) records journey start, each stage completion and endings; the Timeline screen renders them with '08 August 2026' dates as §-specified.
Supersedes: ZYRA_JOURNEY_TIMELINE_2026-08-10_V2.md
Author:     Claude Opus (Architecture & Implementation Lead)
Source:     Founder brief 2026-08-10; Founder reviews of V1 and V2, same day
Authority:  DR-ZYRA-121 (Journey Lifecycle), DR-ZYRA-129 (canonical stage map),
            WALI_ARCHITECTURE V6, ZYRA_ENGINEERING_INVARIANTS V3
```

---

## 0. What changed from V2

Architecture and philosophy are untouched, as instructed. This is an editorial
pass plus one structural answer to your point 7.

| # | Change | Why |
|---|---|---|
| 1 | **"Completed" and "Unlocked" dropped from six titles** | §5.1 — they are project-management words. "Faith & Values Completed" reads like a ticket |
| 2 | **Six milestone sentences rewritten; "You" openers cut from 9 to 5** | §2.3 — and the five that remain are now principled, not leftover |
| 3 | **The three phases became a triad** | §2.3 — "First / Then / Last". Variation from sequence, not from a thesaurus |
| 4 | **Earlier Journeys given an explicit copy rule** | §4.3 — temporal words only, never evaluative |
| 5 | **`milestoneLabel` added to the canonical stage map** | §6 — your point 7, answered structurally rather than by convention |
| 6 | 🔴 **A conflict flagged between your point 7 and this morning's Connections card change** | §12 |

---

## 1. Philosophy

> **The Timeline tells the story of the relationship. It is not an audit log.**

| Principle | What it forbids |
|---|---|
| It is a **story**, not a record | No event exists merely because it was easy to capture |
| It is **read by both people**, forever | No event comfortable for one and painful for the other |
| It **survives failure** | Nothing that makes an ended Journey humiliating to re-read |

Most Journeys will not end in nikah. A Timeline written only for the ones that
do becomes cruel in the majority case — and the majority case is where a
matrimonial product earns or loses its name.

---

## 2. Voice

### 2.1 The standard

| # | Rule | Why |
|---|---|---|
| 1 | **Past tense, always** | A sentence describing what *happened* stays true. One describing what *is* becomes false the day it ends |
| 2 | **"You both", never names, never he/she** | The name is already at the top of the screen. Repeating it every line turns an ended Journey into a haunting |
| 3 | **Under ten words** | A caption, not a description |
| 4 | **No praise, no encouragement, no promises** | "Well done" is the app talking about itself |
| 5 | **State what happened, never what it meant** | Meaning is theirs. The app does not get to tell two people what their relationship was |
| 6 | **Silence where it hurts** | §2.4 |
| 7 | **"You" is reserved for what the two of them did** | §2.2 — new in V3 |

### 2.2 Rule 7 — the answer to the repetition

You were right that nine sentences opening "You…" reads as a template. But the
fix could not be synonyms, because synonyms are the artificial variety you asked
me to avoid.

The variation had to come from the events genuinely being different kinds of
thing. They are:

| Kind of moment | Opens with |
|---|---|
| **The two of them did something** — chose, greeted, met, agreed, married | **"You…"** |
| A stage they moved through | The subject of the stage |
| Something the families did | "Both families…" |
| A threshold the app lifted | The change itself |

So "You" now marks the human acts and nothing else. Five sentences keep it, and
each earns it. That is variation carrying meaning rather than decorating it.

### 2.3 The copy

| Milestone | Supporting sentence |
|---|---|
| **Matched** | You each chose the other. |
| **Journey Started** | And so you began. |
| **Compatibility Reveal** | A first look at what you shared. |
| **Salam Exchange** | You said salaam. |
| **Guardians Connected** | Both families joined you. |
| **Faith & Values** | First, what you believe. |
| **Building a Life** | Then the life you both wanted. |
| **Navigating Life** | Last, the harder questions. |
| **Family Compatibility** | Both families gave their view. |
| **Open Conversation** | From here, you spoke in your own words. |
| **First Meeting** | You met in person. |
| **Families First Met** | Your families met each other. |
| **Proposal Accepted** | You said yes. |
| **Nikah** | You were married. |
| **Custom memory** | *(none — their words are the sentence)* |

**The triad.** *First, what you believe. · Then the life you both wanted. ·
Last, the harder questions.* Three guided discussions in a fixed order, so the
sequence is guaranteed by the product — phase 2 cannot exist above phase 1. It
reads top to bottom as one thought, and it is the stretch that was most
repetitive in V2.

**"And so you began."** Follows *"You each chose the other"* and completes it.
Four words, and the only place the Timeline lets one line lean on the one above.

**Kept exactly as they were**, because they were already the strongest version:
*You said salaam · You said yes · You were married · You talked about the harder
things* (now *Last, the harder questions*, keeping the honesty about difficulty
while joining the triad).

### 2.4 Where the Timeline says nothing

**Journey Paused · Journey Resumed · Journey Ended · New Journey Started carry a
date and nothing else.** Approved by you, and unchanged.

Any sentence under "Journey Ended" is the app editorialising the worst moment in
the relationship. The silence is symmetrical on purpose: a hopeful line on "New
Journey Started" beside a wordless ending would read as the app cheering the
restart and refusing to acknowledge the loss.

> **The Timeline speaks about what two people built, and stays silent about what
> happened to it.**

### 2.5 Empty and closing states

| State | Copy |
|---|---|
| No milestones yet | **Your story starts here.** |
| Ended, viewed later | No banner, no prompt, no "Request New Journey" at the top. A record, not an offer |
| After Nikah | Header becomes **Our Journey** — both first names, and the span of dates |

---

## 3. Inclusion rule

All four must hold:

| # | Test | Fails when |
|---|---|---|
| 1 | Mutual or jointly earned | One person acted alone |
| 2 | Represents forward progress | It records a reversal, refusal or absence |
| 3 | Safe to read whether the Journey succeeds or fails | It would sting, expose or accuse in hindsight |
| 4 | Carries no state the other party is not entitled to | It reveals payment, moderation or safety state |

Tests 1–3 are kindness. **Test 4 is disclosure, and it is the one that breaks by
accident**, because the event that breaks it looks harmless. "Journey Ended" is
safe; "Journey Ended — safety concern" undoes work the database does
deliberately (`zyra_match_ending` downgrades `safety_concern` to
`prefer_not_to_say` for everyone but the person who raised it, held by two CHECK
constraints). **The Timeline never carries `end_reason` in any form.**

Test 3 governs **copy as well as event selection** — §2.1 rule 1.

---

## 4. Earlier Journeys

### 4.1 The three states

| State | Default view | Earlier Journeys |
|---|---|---|
| **Seeking** | Potential Journeys | One quiet line at the bottom of Connections |
| **In a Journey** | The Active Journey only | Same line, one tap |
| **After Nikah** | **Our Journey**, and nothing else | Settings |

### 4.2 The rules

1. **Nothing is deleted, ever** — your ruling of 2026-08-09; the cap is a UI cap.
2. **Always reachable in two taps.**
3. **No counts.** *Earlier Journeys*, never *Earlier Journeys (14)*. A number is
   a score, and it is a score of failures.
4. **No outcome column.** A list showing how each ended is a table of rejections.
5. **After Nikah the others leave the main surface.** When a Journey reaches
   Nikah, this app has done its job. Still showing the fourteen that did not work
   is the product failing to notice it succeeded.

### 4.3 The language rule — new in V3

You asked that moving these away must not read as hiding something shameful.
Made explicit, because one careless string undoes it:

> **Every word for an earlier Journey is temporal. Never evaluative.**

| Use | Never use |
|---|---|
| Earlier Journeys | Past Journeys · Failed · Unsuccessful · Closed · Inactive |
| Earlier | Archive · History · Old |
| *(nothing)* | "Didn't work out" · "Better luck next time" · any consolation |

**No explanatory copy on that screen at all.** A line saying *"These are your
previous Journeys"* is the app being slightly embarrassed on the user's behalf.
Header, list, names, dates. Nothing else.

Each entry: **the person's first name and the span of dates.** Not why it ended,
not how far it got.

**"Earlier" is the whole idea.** It says only that time has passed — which is the
one thing that is true of every Journey in that list, whatever happened.

### 4.4 Multiple attempts with the same person

Unchanged: attempts with **one** person are chapters of **one** story and belong
on one screen — *This Journey* · *Our First Journey*. That is a relationship
having a history. Fifteen different people is not.

---

## 5. Event catalogue

### 5.1 Titles — challenged, and six changed

You asked me to challenge the titles once more. Six lose a word.

| V2 | V3 | Why |
|---|---|---|
| Compatibility Reveal **Completed** | **Compatibility Reveal** | |
| Salam Exchange **Completed** | **Salam Exchange** | |
| Faith & Values **Completed** | **Faith & Values** | |
| Building a Life **Completed** | **Building a Life** | |
| Navigating Life **Completed** | **Navigating Life** | |
| Family Compatibility **Completed** | **Family Compatibility** | |
| Open Conversation **Unlocked** | **Open Conversation** | |
| Nikah **Completed** | **Nikah** | |

**"Completed" is a task-tracker word.** It belongs to software that wants credit
for finishing something. The date already says when, and the sentence beneath
already says it happened, in the past tense. The word was carrying nothing.

*Nikah.* One word, a date, and *"You were married."* That is what the line should
be.

**"Unlocked" is worse** — it is a game word, and it frames a marriage process as
a progression system.

**Kept after challenge:**

| Title | Why it survives |
|---|---|
| **Matched** | One word, already the product's own vocabulary |
| **Journey Started** | "Journey Began" would repeat the sentence beneath it |
| **Guardians Connected** | See §6 — it is the one title that legitimately differs from the stage map |
| **Proposal Accepted** | Cannot shorten to "Proposal": *Sent* and *Declined* are deliberately excluded, so the acceptance is the whole event |
| **First Meeting · Families First Met** | Plain and warm already |
| **Journey Paused · Resumed · Ended · New Journey Started** | Plainness is the point — §2.4 |

### 5.2 The complete permitted set

| Group | Event | Trigger | Source |
|---|---|---|---|
| **Beginning** | Matched | Mutual Consider creates the match | System |
| | Journey Started | Attempt moves to `active` | System |
| | Compatibility Reveal | Both revealed | System |
| | Salam Exchange | Stage passed | System |
| | Guardians Connected | Guardian Gate passed, **both** sides | System |
| **Progress** | Faith & Values | `phase_1` passed | System |
| | Building a Life | `phase_2` passed | System |
| | Navigating Life | `phase_3` passed | System |
| | Family Compatibility | `family_stage` passed | System |
| | Open Conversation | Reached `conversation` | System |
| **Milestones** | First Meeting | Proposed, then confirmed | User |
| | Families First Met | Proposed, then confirmed | User |
| | Proposal Accepted | Proposed, then confirmed | User |
| | Nikah | Proposed, then confirmed | User |
| | Custom memory | Both approve | User |
| **Management** | Journey Paused · Resumed · Ended · New Journey Started | — | System |

**Removed from the original brief:** *Pre-Journey Ritual Completed* — it **is**
the three stages above it, and a fourth row saying the same thing is the one
that drifts. **Renamed:** *Guardian Connected* → *Guardians Connected*, fired on
the Gate, because one person linking their own Guardian fails test 1.

### 5.3 Rejected and deferred

| Idea | Verdict | Reasoning |
|---|---|---|
| First Message / first reply | ❌ Rejected — **agreed** | One person typing. "First reply" quietly records who waited longest |
| Contact Details Shared | ❌ Rejected — **agreed** | Fails test 3 harder than anything proposed. After a bad ending, a permanent record that you gave someone your number is the most uncomfortable row this screen could hold |
| First Voice Call · First Video Call | ⚠️ Deferred | No calling feature, so self-reported and unverifiable. A video milestone also implies the app sanctions unsupervised video contact — a product-position decision far outside this spec |
| Profile Viewed | ❌ Rejected from **both** Timeline and Audit Log | A view log is a surveillance dataset serving no purpose this product has, and creates an Article 15 obligation with nothing offsetting it |

### 5.4 Custom memories — limits change at Nikah

**Before Nikah the Timeline is a courtship record**: two people who may not marry
are writing into a shared, permanent, unmoderated space. Every limit is a safety
limit. **After Nikah it is a family album** and that risk is largely gone.

| | Before Nikah | After Nikah |
|---|---|---|
| Frequency | 1 per calendar month | **Unlimited** |
| Length | ≤ 80 characters | **≤ 300 characters** |
| Approval | Both must approve | **Both must approve — unchanged** |
| Attachments | None | **None yet** — §10.7 |
| Backdating | Not permitted | **Permitted** — a marriage has a past worth recording |

**Mutual approval never relaxes.** It is not a rate limit; it is what stops the
field being a channel for sending someone something they did not agree to
receive. Frequency and length are comfort. Approval is safety.

---

## 6. One product language — your point 7, answered

You asked that the Timeline and the Journey Stage map feel like the same
product. They should not merely *feel* like it — they should be the same strings
from the same file.

Reading the canonical map (`data/zyra_journey_stages.dart`) against §5.2, they
already are, for **seven of eight**:

| Stage value | Stage map label | Timeline title | Same? |
|---|---|---|---|
| `compatibility_reveal` | Compatibility Reveal | Compatibility Reveal | ✅ |
| `salam_exchange` | Salam Exchange | Salam Exchange | ✅ |
| `wali_gate` | **Guardian Gate** | **Guardians Connected** | ❌ |
| `phase_1` | Faith & Values | Faith & Values | ✅ |
| `phase_2` | Building a Life | Building a Life | ✅ |
| `phase_3` | Navigating Life | Navigating Life | ✅ |
| `family_stage` | Family Compatibility | Family Compatibility | ✅ |
| `conversation` | Open Conversation | Open Conversation | ✅ |

Dropping "Completed" in §5.1 is what closed the gap — those seven were only ever
different by that one word.

**The eighth difference is real and should be kept.** A stage label answers *where
are you now* — and while the Gate is open, the Guardians are precisely **not**
connected; that is the point of waiting. A Timeline title answers *what
happened* — and what happened is that they connected. Same stage, two honest
framings.

**So: extend the map, do not fork it.** DR-ZYRA-129 prescribes exactly this —
*"Extend it by adding a FIELD — icons, colours, descriptions, localisation —
never by starting a second mapping."*

```
ZyraJourneyStage
  value           'wali_gate'
  label           'Guardian Gate'        <- you are here
  milestoneLabel  'Guardians Connected'  <- this happened
```

One map, one file, one place to change a word. The supporting sentences in §2.3
live in that same map as a third field. **No Timeline string is ever written at
a call site**, which is the rule that DR-129 exists to enforce and which the
current timeline screen already breaks — see §13.

---

## 7. Event metadata

Current schema is `timeline_milestones (id, timeline_id, milestone_type,
occurred_at, metadata jsonb)` with a 7-value CHECK. It cannot support this spec.
**The table holds zero rows**, so this is a reshape with no migration.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `timeline_id` | uuid | → `timelines` |
| `milestone_type` | text | CHECK against the §5.2 allow-list |
| `occurred_at` | timestamptz | True UTC instant. Internal only |
| **`occurred_on`** | **date** | **Canonical display date. Stamped once, never derived** — §9 |
| `source` | text | `system` \| `user` |
| `created_by` | uuid NULL | NULL for system events |
| `confirmed_by` | uuid NULL | Required before a user event displays |
| `confirmed_at` | timestamptz NULL | |
| `superseded_by` | uuid NULL | Correction chain — §8 |
| `note` | text NULL | Custom memories only |

**`metadata jsonb` is dropped** — on a fixed allow-list it is a place for
undeclared fields to accumulate, and every field here carries a visibility rule.

**Titles and sentences are not stored.** They are presentation, from the map in
§6. Storing them would freeze today's wording into historical rows and guarantee
that improving the copy leaves old Journeys reading the old way forever.

---

## 8. Editing

| Source | Create | Correct | Delete |
|---|---|---|---|
| System | Automatic | ❌ Never | ❌ Never |
| User | Propose → other confirms | Propose → other confirms | ❌ Never |

- An unconfirmed proposal **is not on the Timeline**. It shows to the proposer
  only, as *waiting for {name} to confirm*.
- A correction writes a **new row** and sets `superseded_by` on the old. Nothing
  is updated in place, so the original survives without a history table.
- **Corrections need both people active.** After an ending the Timeline freezes —
  otherwise a correction can be proposed that can never be confirmed, and it
  becomes a way to contact someone who ended the Journey.
- **Verification is dual confirmation and nothing else.** No photographs, no
  documents, no witnesses — that would make the Timeline a moderation surface,
  create a store of nikah documentation ZYRA has no lawful basis to hold, and
  make the app an arbiter of whether a marriage occurred.
- **The Timeline records agreements, never offers.** Proposal Accepted appears;
  Proposal Sent and Proposal Declined never do.

---

## 9. Dates

> **"The actual date should never change."**

A UTC timestamp rendered in the viewer's timezone **does** change.
`2026-08-08T23:30Z` is *8 August* in London and *9 August* in Sydney — two people
would see different dates for the same event forever, and each would be looking
at a bug.

| Rule | |
|---|---|
| Store | `occurred_at timestamptz` — the true instant, internal |
| Store | **`occurred_on date` — computed once at creation from the acting participant's local date, then immutable** |
| Display | `occurred_on`, formatted `08 August 2026` |
| Never display | "Yesterday", "2 days ago", "Last week" — anywhere in the product |
| Never | Derive the display date at render time |

User-created events take the date **entered by the proposer** and confirmed by
the other. A nikah on 16 August recorded on 18 August reads 16 August.

---

## 10. Audit Log, and what nobody had raised

**Default is Audit.** The Shared Timeline is an allow-list; nothing reaches it by
being added elsewhere. The Audit Log is scoped — protection holds, moderator
actions, appeal outcomes, safety endings, Timeline corrections — not a general
activity log (DR-121 item 15 rejects full event sourcing).

### 10.1 🔴 Account deletion destroys the *other* person's history

`delete_own_account` → `profiles` CASCADE → `matches` CASCADE → `timelines`
CASCADE. **If one person deletes their account, the survivor loses the entire
record of their own relationship — including their own nikah date.**

Product failure and legal question at once: the Timeline is *joint* data
(OA-ZYRA-155's MINE/THEIRS/JOINT classification exists for this), so one party's
Article 17 right does not straightforwardly extend to erasing the other's copy.

**Recommendation:** the Timeline survives, with the departed party as a neutral
placeholder and their personal data removed. The events happened; the person is
gone. **Needs legal input** — add to the three existing solicitor questions.

### 10.2 A Timeline will be treated as a nikah record

It will be screenshotted and shown to families, and eventually to someone
wanting proof. ZYRA is not a registrar and this is self-reported, by design.
**One quiet line on any export:** *A personal record, not a legal document.*

### 10.3 "Journey Ended" must never carry a reason

§3, restated because it is the likeliest accidental breach.

### 10.4 What a blocked person sees

**The Timeline stays visible to both.** Blocking closes the channel
(DR-ZYRA-131); the Timeline is history, not a channel. Hiding it deletes
someone's own past as a side effect of another person's action — and the
disappearance would itself reveal the block.

### 10.5 Export contains another living person's data

**Both consent at the time of export.** Consent to the Journey is not consent to
a durable artefact. If the other has deleted their account, export is available
in the anonymised form of §10.1.

### 10.6 Custom memories are a free-text channel

Mutual approval is the control — §5.4. Nothing reaches the other person's
Timeline without them agreeing to it.

### 10.7 Photographs, when they come

The obvious next request after §5.4. Flagged before it is asked: photos add a
moderation surface, storage cost, an Article 15 export obligation and a
CSAM-scanning duty. **Its own decision, not a later polish.**

---

## 11. Visibility — Guardian decision deferred

| Actor | Sees |
|---|---|
| The two Seekers | The full Shared Timeline |
| **Any Guardian** | **Nothing, at launch** |
| Anyone else | Nothing |
| A blocked party | Still sees the Timeline — §10.4 |

The deciding argument is **reversibility**: launching closed and opening later is
a feature Guardians gain; launching open and closing later takes away access
people have had, and every Guardian who saw a Timeline has already seen it.
Choose the option that is cheap to change.

**Reopen when** the Guardian lifecycle settles and OA-ZYRA-162 (per-attempt
Guardian involvement) is built. Recorded as an open question, not a rejection.

Enforced in RLS through a SECURITY DEFINER predicate, never an inline join to
`journey_attempts` — that table has RLS on with zero policies, so any policy
joining it is false for everyone and silently kills the feature.

---

## 12. 🔴 A conflict I need you to resolve

Your point 7 states an existing Founder decision:

> *"For Active Journeys, the Connections card should eventually display the
> current Journey Stage rather than generic text like 'Conversation Open' or 'In
> the Pre-Journey Ritual.'"*

**This morning you instructed the opposite**, and it is built and on your Mac:

> *"WHERE IT SAYS OPEN CONVERSATON.. REMOVE IT AND IT SHOULD BE NAME SURNAME,
> AGE LOCATION"*

The card now shows name, surname, age and location. The stage line is gone. Only
the Family Review chip remains from the stage map.

Both decisions are yours and the later one is today's, so today's stands unless
you say otherwise — but the earlier one was never withdrawn, and a register that
holds both without noticing is how contradiction-audit section 5 happened.

| Option | |
|---|---|
| **A** | Keep as built. Identity on the card; the stage lives inside the Journey and on the Timeline. Point 7's decision is formally superseded |
| **B** | Restore the stage as a third line beneath *age · location*. Both decisions satisfied, card slightly denser |
| **C** | Stage moves onto the **Enter** pill — *Enter · Faith & Values*. Keeps the card clean and the stage visible |

**I would take C.** It puts the stage on the control that leads to it, which is
where it is most useful, and leaves the identity block uncluttered. But this is
copy and hierarchy, which is yours.

---

## 13. Recommended final model

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

zyra_journey_stages.dart   ONE map, three fields:
        label          'you are here'
        milestoneLabel 'this happened'
        sentence       the supporting line

audit_log            everything else. append-only. never user-visible.
```

**Presentation:** one relationship per screen. Attempts as chapters, newest
first. Every row an absolute date. Every milestone one short past-tense
sentence — except pause, resume, end and new-journey, which carry a date and
nothing else.

Default view forward. Earlier Journeys two taps away — no count, no outcomes, no
explanatory copy. After Nikah, this relationship is the app.

---

## 14. Scope

Not an estimate — a scope statement, per the six-layer rule. **Layers 1, 2, 3, 4
and 6 read against the live database 2026-08-10. Layer 5 read only for the
existing timeline screen.**

| Work | Note |
|---|---|
| `timelines` → `UNIQUE (attempt_id)` | **Shared with OA-ZYRA-159 stage 4** — one change, two features |
| `timeline_milestones` reshaped | Populated since 2026-08-11 by the milestones trigger (was empty at V3 writing) |
| `milestoneLabel` + `sentence` fields on the stage map | §6. Additive; no call site changes |
| Milestone emission at 14 system points | Mostly inside existing RPCs |
| Dual-confirmation RPCs | Same shape as Request New Journey |
| RLS predicate | Seeker-only is the simplest this will ever be |
| Timeline screen rebuild | Copy map, three presentation states, chapters |

**Risk named:** the existing timeline screen holds `_labelFor` — a second stage
vocabulary outside the canonical map (`match_created`, `conversation_started`,
`family_stage`, `meeting`, `nikah`). It is the exact defect class DR-ZYRA-129
closed, and it survived that decision because nobody was looking at this screen.
**It must be deleted, not extended.**

---

## 15. Decisions needed from you

| # | Decision | Recommendation |
|---|---|---|
| 1 | The §2.3 copy as its final form | Approve |
| 2 | §5.1 — drop "Completed" and "Unlocked" from eight titles | Approve |
| 3 | §6 — `milestoneLabel` on the canonical map, one product language | Approve |
| 4 | §4.3 — temporal language only for Earlier Journeys | Approve |
| 5 | §12 — **the conflict**: A, B or C | **C** |
| 6 | §11 — Guardians see nothing at launch, revisit after OA-162 | Approve |
| 7 | §10.1 — add account deletion to the solicitor questions | Approve |

---

## 16. The final question, answered honestly

> *If someone scrolls through this Timeline five years after Nikah, does it feel
> like they are reading memories rather than software?*

**Yes — with one reservation I would rather state than hide.**

What earns it: the dates are real dates. The sentences are past tense, so
nothing has quietly become untrue. The endings say nothing. The word "Completed"
is gone. Reading top to bottom, *You each chose the other · And so you began · A
first look at what you shared · You said salaam* is a paragraph, not a log.

**The reservation:** the first five lines are generated the same way for
everybody. Two people who married in 2029 will have the identical opening to two
people who married in 2031. What makes any of it *theirs* is the part they wrote
— the custom memories, First Meeting, Families First Met — and before Nikah they
are allowed one memory a month.

I am not recommending a change. Before Nikah the cap is a safety limit, and
§5.4 already lifts it afterwards. But it is worth naming what carries the
emotional weight here: **the system events are the frame; the couple's own
entries are the picture.** If a future review finds this screen feels generic,
the answer will be to make it easier for two people to add their own moments —
not to write more elaborate sentences for the ones the software noticed.

Every sentence in §2.3 is, in my judgement, the strongest version I can write
under the rules in §2.1. I have no further edits to offer.
