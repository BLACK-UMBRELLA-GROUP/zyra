---
id: DOC-ZYRA-0193
type: REPORT
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA — Guardian Surveillance Audit
links: []
owner: ZYRA chat
---

# ZYRA — Guardian Surveillance Audit

**Status:** FINDINGS — nothing changed, awaiting authorisation
**Date:** 2026-08-08 · Requested by the Founder after Fable's second review

Every finding below was run against the live database and rolled back. The
threat model is a user whose **only** goal is gathering information, who
will never attempt a romantic action.

---

## Verdict on Fable's central claim

**He is right, and the specific mechanism is worse than described.**

The concern was that a Guardian *could* learn things they should not. In
fact a Guardian **already** learns, for free and automatically:

> **Every Guardian of every family their Seeker matches with — name,
> surname, gender, location, bio, age and photographs — from the moment a
> mutual like creates a `potential` match, before any Journey begins, with
> nothing purchased and nobody's consent.**

And the paid feature that is supposed to reveal exactly this returns
**less** than the free route does.

---

## FINDING 1 — Guardian visibility fully bypasses Profile Unlock+

### Measured

Two families. S1 guarded by G1. S2 guarded by G2 and G3. One `potential`
match between S1 and S2. G1 has purchased nothing.

| Probe | Result |
|---|---|
| G1 sees own Seeker | `true` — correct |
| G1 sees the other Seeker | `true` |
| **G1 sees the other family's Guardians** | **`true` — both of them** |
| What is readable | `Khadija / Manchester · Hassan / London` |
| Ages of the other family | 3 rows returned |
| Their photo rows | 4 |
| **Unlocks G1 has paid for** | **0** |
| **`guardians_for_unlocked(S2)` — the paid route** | **0 rows** |

### The inversion

`guardians_for_unlocked()` is correctly gated: it requires a
`paid_plus_single` unlock and returns `first_name, gender, location_text,
is_main, relationship`.

The free route returns **the whole profile row** — first name, surname
line, gender, location, bio, `is_active`, `profile_complete` — plus age via
`ages_for()`, plus the photographs, since `zyra_can_read_photo_object()`
delegates to `zyra_can_view_profile()`, which is `true`.

**The unpaid path is strictly more informative than the paid one.** Unlock+
is not merely bypassed; it is worse than the bypass.

### The mechanism

`zyra_attempt_participant_rows` makes **every active Guardian of either
Seeker** a participant of the attempt. `zyra_can_view_profile()` clause 3
then asks only *"are we both party to one attempt?"* — with **no status
filter**.

So the moment `create_match_on_mutual_like` fires, both families'
entire Guardian sets become mutually visible.

### Why the timing matters most

Two Seekers liking each other is **mutual romantic interest between two
people**. It is being treated as **consent to expose both families'
Guardians to each other**. Nobody agreed to that, and neither Guardian was
asked.

The pattern for fixing it already exists in this schema —
`conversations_select` guards on `(r.role = 'seeker' OR r.attempt_status <>
'potential')`. Clause 3 simply never adopted it.

---

## FINDING 2 — It compounds, and that is the actual attack

One link is a leak. The exposure is **cumulative and unbounded**.

A Guardian to one active Seeker sees the full Guardian roster of every
family that Seeker ever matches with. Over a year of ordinary use that is
dozens of families — names, surnames, locations, faces — acquired without
interaction, without payment, and without ever appearing to those families
as anything other than a name on a Journey.

**The harvesting version:** recruit or create one willing Seeker, become
their Guardian, and have them Like broadly. Every reciprocated like
delivers another family's complete Guardian set. The Seeker controls the
rate; the Guardian collects.

Nothing in the system caps this, logs it, or makes it visible to the people
being catalogued.

**This is the answer to "can they intentionally become a Guardian purely to
gather intelligence?" — yes, and it is the cheapest intelligence-gathering
position in the product.** A Guardian is invited, trusted, gender-unfiltered
and never shown in Browse to the families they can see.

---

## FINDING 3 — Invite tokens are 32-bit and unmetered

```sql
token  DEFAULT upper(encode(gen_random_bytes(4), 'hex'))
```

**Four bytes. 2³² ≈ 4.3 billion.** `preview_wali_invite(token)` is callable
by any authenticated user, returns the inviter's **first name and role**,
and has no rate limit, no attempt log and no lockout.

Guessing one *specific* invite is infeasible. Harvesting *any* valid invite
is not: with N outstanding invites the expected number of guesses is 2³²/N.
At 10,000 live invites that is ~430,000 attempts — minutes at modest
request rates.

And a found token can be **accepted**, not merely previewed — attaching a
stranger as someone's Guardian, or making the attacker Guardian to a
stranger, which by Finding 1 is a surveillance position.

**Fix:** 16 bytes minimum, plus rate limiting on preview and accept. The
column is `text`, so widening is not a migration hazard.

---

## FINDING 4 — Family Network is a 205-line UI shell with no backend

`wali_network_screen.dart` exists; there is no network table, no service,
no graph. **Fable's warning is therefore preventative, and it is correct.**

The reason to take it seriously now: Findings 1 and 2 show the system
*already* leaks family-graph edges implicitly. A feature whose explicit
purpose is exposing family relationships, built on top of a substrate that
leaks them accidentally, is how the accidental leak becomes the intended
product.

**Introduction-only with explicit consent is the right constraint**, and it
should be written down before a line of it exists — otherwise the
enumeration will be designed in rather than left out.

---

## Where I disagree with Fable

### 1. "Surveillance rather than matching" is a false choice

Both reviews framed these as competing priorities. They are the same defect
viewed twice.

Same-gender matching was possible because the write path never asked *may
these two interact*. Guardian surveillance is possible because the read
path never asks *may this person see this*. In both cases a rule existed
only in the query that happened to be written, never as a property of the
system.

`can_match()` fixed the write side. **There is no equivalent on the read
side** — `zyra_can_view_profile()` is not a policy, it is four
independently-grown clauses, and clause 3 is the one nobody re-examined.

The missing piece is not a new concern. It is the same concern, unfinished.

### 2. Photo reuse is not the privacy risk here

Fable warns that reusing a Seeker photo on the Guardian presentation
correlates the two audiences.

That risk is real but **second-order, and mostly already realised**. Under
"one identity, two presentations" the name, surname, age and location are
shared regardless — anyone comparing the two has already correlated them.
The photograph adds little that a first name plus a location does not.

More importantly: **a Guardian with no photograph is worse for the product
than a correlated one.** A faceless Guardian is precisely what a family
vetting their daughter's match should not be reassured by. Trust is the
proposition.

**My recommendation on the Founder's UX question:** offer the existing
photos as a *choice*, do not copy automatically, and do not default to the
Seeker's main photo. The correlation objection is answered by making it
deliberate rather than by making it impossible — and if the Guardian
presentation genuinely needs to be unlinkable, that is a much larger
requirement than photo selection, and the shared name defeats it anyway.

---

## Answering the questions directly

| Question | Answer |
|---|---|
| Discover people earlier than intended? | **Yes.** Full profile of the other Seeker and all their Guardians at `potential`, before any Journey |
| Discover Guardians? | **Yes.** All of them, not just the Main |
| Discover Family Network members? | Not built — but Findings 1 and 2 already leak the edges |
| Infer identities? | **Yes.** Name, surname, location, age, photo |
| Bypass commercial features? | **Yes.** Unlock+ entirely, and the free route reveals more |
| Become a Guardian to gather intelligence? | **Yes, and it is the cheapest position in the product** |

### What held up

Worth recording, so these are known-checked rather than unexamined:

- **`seeker_details` did NOT leak.** 0 rows for the other Seeker. That
  policy requires the reader to be that Seeker's own Guardian.
- **Conversations did NOT leak at `potential`.** 0 rows — the status guard
  works there.
- **`profile_photos` is not an enumeration vector.** Its policy looks wide
  open, but the inner `EXISTS` on `profiles` is itself subject to
  `profiles_select`, so it only ever returns rows the caller could already
  see. 12 users visible, not 144. I expected a hole here and there is not
  one — policy composition saved it, which is fragile but currently correct.
- **`wali_links` does not enumerate.** 11 rows readable of 25.
- **`guardians_for_unlocked` and `seeker_details_for_unlocked`** are both
  properly gated on a real purchase and on blocks in either direction.

---

## What I would fix, in order

**1. Put a status guard on clause 3.** One condition, mirroring what
`conversations_select` already does. Guardians stop being participants for
visibility purposes until an attempt is past `potential`. Smallest change,
closes the "earlier than intended" half immediately.

**2. Split Guardian↔Seeker from Guardian↔Guardian.** These are different
permissions wearing one clause today:

| Who | Sees what | When |
|---|---|---|
| Guardian → other **Seeker** | needed to vet them | Journey started |
| Guardian → other **Main** Guardian | needed for the Main↔Main conversation | the stage that conversation opens |
| **Additional** Guardian → any other Guardian | **never** — no purpose exists |

That third row is the entire finding. There is no feature requiring an
Additional Guardian to know who the other family's Guardians are.

**3. Give the read side its own predicate.** `zyra_can_view_profile()` grew
four clauses over months and nobody re-examined the interaction. The write
side got `can_match()`; the read side deserves the same treatment, with each
clause named, justified, and tested independently.

**4. Widen invite tokens and rate-limit preview and accept.**

**5. Write the Family Network constraint down before building it.**

None of it is attempted here.
