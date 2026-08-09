# ZYRA — Badge Standard

**Status:** APPROVED — Founder, 2026-08-06
**Applies to:** every badge, dot or count anywhere in the product

---

## The rule

> **A badge represents outstanding user action.**
>
> It does not simply indicate that something happened. Informational events
> belong in notification history. Historical pages generally should not have
> badges unless they become action surfaces.

Every new feature answers one question:

**"Is the user expected to do something?"**

| | |
|---|---|
| **Yes** | badge |
| **No** | notification history only |

---

## Why this replaced the earlier framing

The first proposal offered a choice between *"something happened"* and
*"something needs you"*. The Founder rejected the framing itself: the second
is not a preference, it is the definition. Stating it as a rule rather than
an option removed most of the edge cases in a paragraph.

**One consequence worth naming, because it changes the engineering:**

The rejected framing needed a `last_seen_at` timestamp per user per
surface — *"how many things changed since you last looked"* is a question
about history, and history needs a bookmark.

**Outstanding action is state, not history.** A pending introduction, a
Family Review awaiting your decision, an unopened Potential Journey — each
is derivable from what is true *now*. Most badges therefore need **no new
schema at all**, and cannot drift out of sync with the thing they count,
because they *are* the thing they count.

A rule that makes the product clearer and the implementation smaller is
usually the right rule.

---

## Bell versus badge

| | Badge | Notification bell |
|---|---|---|
| Answers | *what is still waiting on me* | *what has happened* |
| Nature | state | history |
| Clears when | the action is **resolved** | never — it is a record |

The same event legitimately appears in both. Completing the action removes
the badge; the notification stays in history.

---

## Clearing — badge and list count are two different things

**Amended 2026-08-06.** This section first said a badge clears only when the
item is *resolved*, never on view. That was wrong in practice, and the
Founder's correction is the better model:

> *"A badge should tell me something **new** requires my attention. Once
> I've entered the screen, the alert has done its job. The outstanding work
> doesn't disappear — it remains visible in the list itself."*

| | Counts | Clears when |
|---|---|---|
| **Badge** | **unseen** actionable items | you arrive at the surface |
| **List count** — `INTRODUCTIONS (5)` | **unresolved** actionable items | the item is resolved |

They are complementary, not contradictory. The badge is the *alert*; the
list is the *work*. Arriving discharges the alert. It does not do the work,
and the heading goes on saying so.

**Why the original rule failed.** A Guardian introduces someone and the
Seeker takes three days to decide — entirely reasonable. Under resolve-only
clearing the dot stays lit for three days, which is nagging, and worse,
teaches the user that the dot does not mean *new*. That is the one thing it
must mean.

### Implementation — still no bookmark

Per CLAUDE.md §3d, "unseen" must not become a `last_seen_at` per user per
surface. It does not need to: **unseen is a per-item state**, the same shape
as unresolved.

`wali_suggestions.seen_at` — null means unseen. The dot counts nulls. See 2
introductions, a third arrives, the dot returns, and nothing anywhere holds
a timestamp about the observer.

---

## Aggregation

A parent surface shows the **sum** of its children's outstanding items.

Tapping it lands on the **highest-priority segment with unresolved
actions** — not the last segment visited. Otherwise the badge vanishes
without being answered, which is the worst outcome: the signal is consumed
and the work is not.

---

## Guardians do not receive badges

Extends `ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md` §11:

> *"Guardians get a digest, not a stream… A Guardian receiving live pings is
> surveillance regardless of what the permission model calls it."*

A badge is a ping. The reasoning that governs notifications governs badges.

**This is not an exception to the rule — it is the rule applied.** A badge
represents *outstanding user action*, and almost nothing in a Seeker's
Journey is the Guardian's action. Their Seeker advanced a stage; there is
nothing for the Guardian to do. No outstanding action, no badge. The
governance principle and the badge rule reach the same answer independently,
which is a good sign both are right.

Where a Guardian genuinely does have work of their own — a Family Review
awaiting *their* decision — they get a badge, for the same reason anyone
does. That is their action, not surveillance of their Seeker.

The heading is therefore a summary of the usual outcome, not a carve-out:
**Guardians rarely have outstanding work, so they rarely have badges.**

---

## Applied — as of 2026-08-06

| Surface | Badge? | Why |
|---|---|---|
| **Introductions** | **yes** | A Guardian has put someone forward; the Seeker must decide |
| **Activity** | **no** | Considered, Saved and Passed are records of the user's own decisions. Not an inbox. Nothing arrives unbidden |
| **Journeys** | **yes, narrowly** | Only where the Journey is waiting on the user — see below |
| Notification bell | n/a | History by definition |
| Bottom nav — Connections | aggregate | Sum of the above |

### Journeys — what counts

**Badge:**

- new Potential Journey
- Family Review requires *your* action
- the other party requested a new Journey *(OA-ZYRA-159, unbuilt)*
- the other party ended the Journey
- any future workflow explicitly waiting on the user

**Do not badge:**

- automatic stage progression
- the user's own actions — they were there
- informational milestones

### The one case the rule does not settle cleanly

**The other party paused the Journey.**

V3 §7A gives the received-pause screen exactly two actions: **wait**, or
**end**. Waiting is a legitimate choice that requires doing nothing — so
whether a pause is "outstanding action" depends on whether declining to act
counts as acting.

Not listed as a trigger by the Founder, so **not badged** pending a
decision. Recorded here rather than resolved by an engineer, because the
answer sets a precedent for every future "you may respond or not" state.

### "The other party ended the Journey" — not an exception

This was first written up as the one case that broke the rule: an ending is
an event, so there is nothing standing to derive from, so it needs a flag,
so it must be history.

**Founder, 2026-08-06, and he is right:**

> *"The badge isn't representing the ending. It's representing: you have an
> unread Journey outcome. That's an outstanding acknowledgement rather than
> simply an event… I'd rather keep the rule pure and treat this as another
> form of outstanding item."*

The error was conflating **"needs a column"** with **"is history"**. Needing
storage is not the test. Both patterns store something; the shapes differ:

| | Shape | Scales |
|---|---|---|
| `last_seen_at` | a bookmark against a **timeline**, per user per surface | badly — one per surface, drifts, needs maintaining |
| `acknowledged` | a boolean on **the item** | it is simply the item's state |

*"There exists an ended Journey you have not acknowledged"* is a standing
condition, structurally identical to *"there exists an introduction you have
not resolved"*. Same pattern, different verb.

**So the operational test is sharper than "state versus history":**

> **Is the badge derived from a bookmark against time, or from an item's own
> unresolved state?**
>
> If you find yourself reaching for a bookmark, you have probably mis-framed
> it. Look again for the item that is actually unresolved.

That is more useful than an exceptions list, because it tells you what to do
when you think you have found an exception: you have not — you have not yet
identified the item.

**There are no exceptions to this standard.** If one appears, the framing is
wrong before the rule is.
