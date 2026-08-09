# ZYRA — Journey Entitlement: Decision Record

**Status:** APPROVED — Founder, 2026-08-06. **Not yet built** (see sequence)
**Supersedes:** the "Parked / On Hold Journey" proposal, rejected same day

---

# The governing principle

> **A user's entitlement is consumed only by actions they intentionally
> take. Another person's actions may release it, never consume it.**

Everything below derives from this. Test future decisions against it rather
than against the individual rules, which are only this principle applied.

**The second sentence is a deliberate addition to the Founder's wording**,
because the one-line version does not survive expiry. Expiry is triggered by
someone *else's* silence — so under "entitlement is determined only by your
own actions", expiry is an exception. Under the asymmetric version it is not:
another party's behaviour can only ever hand a slot back, never take one. The
protection runs one way, which is the whole point of it.

| Event | Whose action | Effect |
|---|---|---|
| Outgoing Consider | mine | **consumes** |
| Incoming like | theirs | nothing |
| Guardian introduction | Guardian's | nothing |
| Mutual match → Potential Journey | mine, previously | **consumes** |
| They decline · block · delete | theirs | **releases** |
| Expiry | their silence | **releases** |

Reducing exceptions by strengthening the principle, rather than by adding
special cases, is why this record has no carve-outs left in it.

## The lifecycle at a glance

```
                    I press CONSIDER
                           │
                           ▼
            ┌──────────────────────────────┐
            │  OUTSTANDING INTEREST        │
            │  state = Active              │  ◀── consumes 1 slot
            └──────────────────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
   they respond                        no response
        │                                     │
        ▼                                     ▼
   ┌─────────┐                    ┌───────────────────────┐
   │ ACCEPTED│                    │ "Keep waiting, or     │
   │         │                    │  withdraw?"           │
   └────┬────┘                    └───────────┬───────────┘
        │                              wait   │   nothing
        ▼                                 │   │
  POTENTIAL JOURNEY                       │   ▼
   (still 1 slot —                        │  EXPIRED
    I initiated it)                       │
        │                                 └──▶ stays Active
        ▼
   ACTIVE JOURNEY   ◀── separate allowance. Paused counts as Active.
        │
        ▼
      ENDED ──────▶ Request New Journey (OA-159) is the path back


  Slot released by ANY of:
    Withdrawn · Declined · Expired · Blocked · Account deleted
    · Accepted into a Journey
```

Only the **Active** box consumes entitlement. Every arrow leaving it hands
the slot back.

---

## The decision

The Journey lifecycle does **not** change. Four states, as users already
understand them:

```
Potential → Active (Paused is a flag on Active) → Ended
```

What changes is the **entitlement**, and it is enforced at the moment a user
expresses interest — not when someone reciprocates.

| | Outstanding interest (Consider + Potential, combined) | Active Journeys |
|---|---|---|
| **ZYRA Basic** | 1 | 1 |
| **ZYRA One** | 5 | 1 — **provisional, see below** |

### The "1 Active Journey" number is deliberately NOT settled

**Founder, 2026-08-06.** The architecture is now solid enough that this has
stopped being a technical question and become a product and religious one.
**Held pending Islamic review.**

> *"Real marriage journeys are rarely synchronous. Families may take weeks
> or months to respond because of travel, illness, exams, work commitments
> or family discussions."*

So whether ZYRA One stays at one, or allows two or three, is open. What is
NOT open is the surrounding architecture — the one-active rule is enforced by
unique partial indexes on `matches`, and raising the number means changing
those indexes to a counted check. That is a known, bounded change, which is
exactly why the number can safely stay open.

**Nothing in this record depends on the answer being 1.**

> **The architecture supports multiple Active Journeys; whether the product
> should permit them is a separate governance decision informed by Islamic
> guidance and product philosophy.**

Recorded so the undecided value is never mistaken for an unfinished design.
The number is policy sitting on top of the architecture, not a gap in it.

Paused still consumes the Active slot, because a paused Journey *is* an
active one — `suspend_journey()` sets `suspended_by` and leaves the status
`'active'`, and `'paused'` was removed from the status CHECK on 2026-08-06
as unreachable.

---

## Why "Parked" was rejected

The proposal was a second, softer kind of ending: set a Journey aside, free
the Active slot, return to it later.

It failed on one question — **what happens to the other person?**

| If A parks the Journey with B | Verdict |
|---|---|
| B stays frozen | One person holding another's marriage prospects while exploring elsewhere. Indefensible |
| B is freed too | Defensible — but then "come back later" is not a promise the product can keep, and Park collapses into End |
| B is not told | Worse than either |

Founder: *"Parked… starts becoming a second type of ending."* Correct. The
only survivable version of Park was End, so the work belongs in making End
read honestly rather than in a fourth state that Family Review, Guardian
visibility, badges and every status-reading policy would have to be taught.

---

## Why the cap sits on Consider, not on Potential

`create_match_on_mutual_like` is a **trigger**, is not plan-gated, and counts
nothing. A Potential Journey is therefore created by **the other person's**
action.

Capping Potential Journeys would mean refusing a match because of a limit
the receiving user holds — punishing the person who reciprocated, who would
never learn why their interest vanished.

**So the limit counts outstanding Considers AND Potential Journeys together,
and is enforced when the user presses Consider.** A reciprocal like is never
blocked.

This also closes the loophole in any Potential-only cap: without counting
pending outgoing Considers, a user could Consider fifty people and collect
fifty Potential Journeys one reciprocation at a time.

---

## Language

Founder: *"I don't think users should ever think in terms of 'Potential
Journey limits.'"*

> **"You currently have the maximum number of ongoing introductions.
> Continue one of your existing introductions before starting another."**

No caps, no quotas, no counters. And **End** needs the same treatment — an
ending should read as *"we're not continuing this Journey at this time"*,
not as failure.

The vocabulary for that already exists and is unused: `end_reason` already
allows `circumstances_changed`, `family_decision`, `marrying_elsewhere` and
`prefer_not_to_say`. The data models the nuance; the UI does not yet.

---

## Approved sequence

| # | Work | Why this order |
|---|---|---|
| 1 | **Finish OA-156** | Seven RPCs still take `p_match_id` — `end_journey`, `suspend_journey`, `resume_journey`, `restart_journey`, `promote_journey_to_active`, `open_family_review`, `resolve_family_review_if_due`. Building on a half-migrated model means migrating the new work twice |
| 2 | **OA-159 Request New Journey** | No longer optional. It is the mechanism that makes "End" mean *stopping for now* rather than *gone forever*. Without it, End is final in practice whatever the copy says |
| 3 | **Entitlement limits at Consider** | Six-layer dependency review **before** implementation |

Founder: *"That sequence keeps the user experience coherent from day one."*

---

## Outstanding Interest — the definition

Every future entitlement check references this and nothing else.

> **Outstanding Interest** = any expression of interest **the user has
> initiated themselves** that has not yet progressed to an Active Journey,
> and has not been withdrawn, declined, expired or ended.

**One word changed from the Founder's draft, deliberately.** The draft read
*"any expression of **mutual** intent"*. Mutual would exclude an outgoing
Consider nobody has reciprocated yet — which is the single most important
thing the limit has to count, and the loophole the whole design exists to
close. "Initiated themselves" carries the intended meaning without
excluding it.

That phrase also does the Guardian work below: an introduction the Seeker
did not initiate is not Outstanding Interest, by definition, rather than by
exception.

### The three concepts — Founder, 2026-08-06

An architectural definition. Every future entitlement question resolves
against this table rather than being argued again.

| | Concept | Consumes entitlement |
|---|---|---|
| 1 | Interest **I initiated** | **yes** |
| 2 | Interest shown **towards me** | no |
| 3 | **Mutual** interest | yes — because (1) is true of me |

- My outgoing Consider → **counts**
- Someone liking me → **does not**
- A Guardian introducing someone to me → **does not**
- A mutual match becoming a Potential Journey → **counts**, because I
  pressed Consider at some point; whether I went first or reciprocated is
  irrelevant, both are my action

**The consequence worth stating out loud:** a mutual match means *both*
parties initiated, so a Potential Journey spends one slot **for each of
them**. On ZYRA Basic, with an allowance of 1, a single Potential Journey is
the user's entire allowance — they cannot Consider anyone else until it
resolves. That is intended, and it is exactly why expiry below is blocking
rather than cosmetic.

---

## What releases a slot

Enumerated so two implementations cannot make different assumptions.

| Event | Releases |
|---|---|
| User withdraws their Consider | ✓ |
| The other user declines | ✓ |
| Consider expires | ✓ |
| Potential Journey is declined | ✓ |
| Potential Journey becomes Active | ✓ — it moves to the Active slot |
| Journey ends | ✓ |
| **The other user blocks, or deletes their account** | ✓ — added; nothing can come of it and holding the slot would punish the wrong person |

**Note on expiry.** No expiry period exists in the schema today. Until one
does, "Consider expires" cannot fire, so on ZYRA Basic a single
unreciprocated Consider holds the only slot indefinitely and the user is
told to "continue an existing introduction" that does not exist. **The
expiry window must be decided before this ships, not after.**

---

## Guardian Introductions do not consume the allowance

**Founder decision, 2026-08-06.** A Guardian introduction sits outside the
entitlement system until the Seeker acts on it.

> *"The Seeker didn't press Consider. The Guardian initiated the
> introduction. It would feel unfair if your father introduced someone and
> one of your available introductions disappeared before you had chosen to
> express any interest yourself."*

The allowance is consumed at the moment the Seeker **expresses interest** in
someone introduced — because that is their action, and identical in kind to
pressing Consider in Browse.

This follows from the definition rather than sitting beside it as a
carve-out: an introduction the Seeker did not initiate is not Outstanding
Interest.

---

## Still open for the entitlement review

1. **Expiry is a PRODUCT decision, not a timeout.** Founder, 2026-08-06:
   *"A Basic user cannot permanently lose their only slot because somebody
   never replies… It should be a deliberate product decision with user
   messaging, not just a timeout hidden in the database."*

   To be designed, not implemented, in the entitlement review:
   - How long before an unreciprocated Consider goes stale
   - Whether the sender is told before it lapses, or only after
   - **Whether the recipient is told at all** — being informed that someone's
     interest in you has expired is a different experience from never
     knowing it existed, and on this platform the second may be kinder
   - Whether it can be renewed, and whether renewing is visible
   - What it is called. "Expired" reads as failure; the same reasoning that
     applies to "End" applies here

   ### Expiry is a lifecycle transition, not a timer

   **Founder, 2026-08-06.** An Outstanding Interest is always in exactly one
   state:

   | State | Consumes entitlement |
   |---|---|
   | **Active** | **yes** |
   | Withdrawn (by sender) | no |
   | Declined (by recipient) | no |
   | Accepted (became a Potential Journey) | no — moves to the Journey |
   | Expired (no response in the agreed period) | no |
   | Blocked | no |
   | Account deleted | no |

   #### BUSINESS RULE — stable

   > **Count Outstanding Interest where state = Active.**

   This is the rule. It should survive any change to how it is stored.

   #### IMPLEMENTATION — to be decided at build time

   No `outstanding_interest` entity exists today. Two candidates:

   | | Keeps one source of truth | Cost |
   |---|---|---|
   | **Derived view** over `likes`, `matches`, `passes`, `profile_blocks` | ✓ cannot drift | more complex to read; expiry needs somewhere to live regardless |
   | **Dedicated table** | ✗ needs a writer per transition | simpler reads, and the natural home for the renewal choice |

   **Deliberately left open.** The business rule above does not change
   whichever is chosen, which is the test of whether the two have been
   separated properly.

   Everything else releases the slot by being a different state, not by a
   separate rule maintained alongside — the same principle as the Badge
   Standard's *"outstanding action is state, not history"*. It is also why
   expiry must not become a timestamp that several call sites compare
   against `now()`, each free to disagree.

   ### Expiry is intentionally quiet

   **Founder, 2026-08-06** — and this settles the question flagged as the
   hardest, in the right direction:

   | | Notified |
   |---|---|
   | **Sender** | **yes** — gently: their introduction has expired and they may express interest elsewhere |
   | **Recipient** | **no** |

   > *"They may never even have opened the app, and telling them someone
   > else's interest quietly lapsed doesn't help either person or the
   > marriage process. It creates unnecessary emotional friction without
   > enabling any action."*

   The test is whether the message enables an action. For the sender it
   does — a slot is free. For the recipient there is nothing to do, and the
   only thing the message reliably delivers is the knowledge that they were
   too slow.

   ### Ask before expiring

   **To design in the review.** Rather than lapsing silently:

   > *"This introduction has been awaiting a response for 21 days. Would you
   > like to keep waiting, or withdraw your interest?"*

   Doing nothing still expires it, so an abandoned account cannot hold a
   slot forever — but a user who is still hopeful is never overruled by a
   clock.

   Open within this: whether choosing to wait restarts the period or
   requires confirming again later, and whether there is a limit on
   renewals. Renewing forever is the abandoned-introduction problem wearing
   a consent form. **Note this needs somewhere to record the choice** —
   which is the same schema question as the state model above, and should be
   answered once for both.
2. **Plan lapse.** A ZYRA One user drops to Basic holding 5 outstanding.
   Nothing may be silently discarded, and they cannot be left permanently
   over the limit either. Likely answer: keep all 5, allow no new ones until
   they fall to 1 — never delete, just stop adding.
