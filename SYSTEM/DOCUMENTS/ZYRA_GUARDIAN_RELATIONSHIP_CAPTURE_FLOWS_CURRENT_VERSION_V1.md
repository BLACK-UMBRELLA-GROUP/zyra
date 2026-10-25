---
id: DOC-ZYRA-0185
type: SPEC
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA — Guardian Relationship: Where Is It Captured?
links: []
owner: ZYRA chat
---

# ZYRA — Guardian Relationship: Where Is It Captured?

**Status:** DECIDED — Founder, 2026-08-07
**Date:** 2026-08-07

---

# THE RULE

> **The relationship is a statement about the Guardian, so the Guardian
> makes it — once per link, at the point they create that link.**
>
> Previous answers may be pre-filled but must remain editable, because the
> relationship belongs to the LINK, not to the Guardian account.

## Why ownership, not timing

My earlier draft said "at the earliest moment they are present". The Founder
replaced it with ownership, and that is the better rule:

> *"The relationship is a statement about the Guardian. I am her Father. I
> am her Brother. The Seeker never needs to describe another person when
> that person is capable of describing themselves."*

Timing explains *when* the question appears. Ownership explains *why*, and a
rule that carries its own reason survives the people who wrote it. Anyone
reading this in two years can apply it to a flow that does not exist yet.

## One wording note

The Founder's shorter phrasing — *"the person creating the LINK provides the
relationship"* — is exact in Flow A but not in Flow B, where the Guardian
creates the **invitation** and the Seeker's acceptance creates the **link**.
Read literally, Flow B would point at the Seeker, which is the opposite of
the intent.

**The version recorded above avoids that**, because "a statement about the
Guardian" cannot point anywhere else regardless of who clicks last. The
Founder's own reasoning paragraph is the precise one; only the one-line
compression drifts.

## Applied

| Flow | Who is asked | When | Status |
|---|---|---|---|
| **A** Seeker invites Guardian | Guardian | while accepting | **built** |
| **B** Guardian invites Seeker | Guardian | while creating the invite | **to build** |

Flow A already does this. It was arrived at by implementation rather than
decision and happens to be right; the rule now makes it deliberate.

Flow B currently asks nobody, so every link created that way has a null
relationship. One question added to `WaliInviteSeekerScreen`, pre-filled
from the Guardian's last answer and editable — a man who invited his
daughter last month must not silently label his niece "Daughter".

---

---

## The constraint that shapes everything

`wali_links.relationship` is **one column on one row per link**. Both parties
are describing the same fact from opposite ends:

> "I am her father" and "this is my father" are **the same row**.

So there is nothing to reconcile and no merge to design. Option C — both
parties contribute — has nothing to contribute *to*. The only real question
is **who is asked**.

A second constraint, easy to miss: a Guardian linked to two Seekers is
father to one and uncle to the other. The value is per link, so whoever is
asked must be asked **once per link**, not once per account.

---

## Flow A — Seeker invites Guardian

The original flow. Seeker generates a code, shares it, Guardian redeems it.

| # | Capture point | Who | Verdict |
|---|---|---|---|
| A1 | Seeker picks before sending | Seeker | **No** |
| A2 | Seeker picks after acceptance | Seeker | **No** |
| A3 | **Guardian picks while accepting** | Guardian | **Yes — built today** |

**A1 — Seeker picks before sending.** She chooses "Father", then shares the
code however she likes. Whoever redeems it becomes the Guardian, and the
code carries a relationship she asserted about a person who had not yet
arrived. If her brother redeems the code meant for her father, the row says
Father and nobody is asked. **Asserting a fact about someone not present is
the weakest version of this.**

**A2 — Seeker picks after acceptance.** Accurate, because the Guardian now
exists. But it creates a task after the moment of completion: the link is
live, the Guardian is connected, and the Seeker has an unfinished chore
about a person she has just linked. Relationships would sit null for as long
as she ignores it, and null is what the display code has to keep handling.

**A3 — Guardian picks while accepting.** The Guardian is present, has just
identified themselves, and is describing **their own** relationship. Nothing
is null: the link cannot be created without passing through the question.

---

## Flow B — Guardian invites Seeker

Already built end to end. `accept_wali_invite` branches on `inviter_role`,
and `createInvite()` sets it from the caller's role.

| # | Capture point | Who | Verdict |
|---|---|---|---|
| B1 | **Guardian picks before sending** | Guardian | **Yes** |
| B2 | Guardian picks after acceptance | Guardian | No |
| B3 | Seeker picks while accepting | Seeker | Defensible, but see below |

**B1 — Guardian picks before sending.** *"I'm inviting my daughter"* — the
Guardian is describing themselves, before the link exists, and it is true
regardless of who redeems the code, because the RELATIONSHIP TYPE travels
with the sender rather than the recipient. This is not A1: in A1 the Seeker
asserts something about a stranger; in B1 the Guardian asserts something
about themselves.

**B3 — Seeker picks while accepting.** Also honest — she knows he is her
father. But it asks the Seeker to describe someone else while the Guardian,
who could have answered before sending, was not asked.

---

## The standard, and why

> **The relationship is stated by the GUARDIAN, at the earliest moment they
> are present.**
>
> Flow A: while accepting the invite.
> Flow B: while creating the invite.

Three reasons, in order of weight:

1. **It is theirs to state.** A Guardian describing their own relationship is
   giving a fact about themselves. A Seeker describing a Guardian is giving a
   fact about someone else. Where both are available, the first-person one is
   the one to take.
2. **It is never null.** In both flows the question sits on the path the link
   must travel. No backfill task, no null branch in the display code, no
   "Relationship — not recorded" that somebody has to chase.
3. **It survives the Founder's own instinct.** *"The person confirming the
   link should provide the relationship"* — right in Flow A, where the
   Guardian confirms. But in Flow B the Seeker confirms, and asking her to
   describe him puts the second-hand answer in a row the first-hand one
   could have filled. **Guardian-states is the rule that holds in both
   directions; confirmer-states only holds in one.**

### What this changes

| | Today | Under the standard |
|---|---|---|
| Flow A | Guardian picks at acceptance | unchanged — already correct |
| Flow B | **nobody is asked** — relationship is null | Guardian picks before sending |

So the work is **one question added to `WaliInviteSeekerScreen`**, and Flow A
needs nothing. The current implementation was arrived at by accident and
happens to be right; this makes it a decision.

### One case the standard does not cover

**A Guardian with several Seekers, inviting in Flow B.** The relationship is
per link, so the question must be asked per invite — not remembered from the
last one. It can be *prefilled* from their previous answer, but must remain
editable, or a man who invited his daughter last month will silently label
his niece "Daughter".

---

## Awaiting your decision

1. Adopt **Guardian-states, earliest presence**, as above?
2. Or **confirmer-states**, accepting that Flow B then asks the Seeker to
   describe someone else?
