---
id: DOC-ZYRA-0182
type: SPEC
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA — Guardian: Open Topics
links: []
owner: ZYRA chat
---

# ZYRA — Guardian: Open Topics

**Status:** PARKED — raised, not resolved. Nothing here is decided.
**Date:** 2026-08-07

Topics deliberately deferred while building the Guardian section, kept in one
place so they are picked up rather than rediscovered.

---

## 1. Guardian messaging visibility — WHO CAN READ WHAT

**Raised by the Founder, 2026-08-07:**

> *"I think we said earlier Guardians cannot read other Guardians' messages,
> but that's only the private convo two Main Guardians can have. All
> Guardians can read the Seeker-and-Seeker convo and join in on that."*

So there are **at least two distinct conversations**, and the earlier rule
was about one of them only:

| Conversation | Who is in it | Who can read it |
|---|---|---|
| **Seeker ↔ Seeker** | the two Seekers | **all Guardians on both sides** — and they may join in |
| **Main Guardian ↔ Main Guardian** | the two Main Guardians | **only those two.** Not the Seekers, not Additional Guardians |

**Why this matters more than it looks.** The Journey conversation is
currently treated as one thing with one visibility rule. If there are two
conversations with different audiences, that is a structural difference, not
a permission flag — and it lands on:

- **`zyra_attempt_participants()`**, which today answers "who is party to
  this attempt" with a single set. Two conversations need two answers.
- **The Start Journey dialog copy**, which tells the Seeker their Guardian
  can read the conversation. If a second conversation exists that they
  CANNOT read, that sentence is incomplete at the exact moment consent is
  given.
- **Article 15 export** — a Guardian-to-Guardian conversation about a Seeker,
  which the Seeker cannot see, is personal data about them held in a place
  they have no visibility of. That is a live subject-access question and
  belongs with the three already sitting with the solicitor.
- **The Badge Standard** — a Guardian with an unread message from another
  Guardian has outstanding action, which is the one case where a Guardian
  legitimately gets a badge.

**Questions to answer before building:**

1. Is the Main-to-Main conversation per **Journey**, or per **pair of
   families** across Journeys?
2. Can an Additional Guardian ever be promoted INTO an existing Main-to-Main
   conversation? What happens to its history if Main changes?
3. Does the Seeker know the conversation exists, even without reading it?
4. Does it survive the Journey ending?
5. Is it exportable to the Seeker under Article 15? **Solicitor question.**

**Not to be decided by engineering.** Recording it so the Start Journey copy
is not quietly left half-true in the meantime.

---

## 2. Guardian gender governance review

Ordered by the Founder 2026-08-06, still outstanding. Gates the wider
relationship list.

- The male-Guardian model — `createWaliProfile` hardcodes `gender: 'male'`
- Exceptional cases
- Whether male Seekers have Guardians
- Every affected document and implementation

## 3. Islamic validity of the proposed relationship values

Family Friend · Trusted Friend · Cousin · the paternal qualifiers. Needs a
scholar, not a product review. See
`ZYRA_GUARDIAN_RELATIONSHIP_LIST_REVIEW_CURRENT_VERSION_V1.md`.

## 4. Addressed invitations

`wali_invites` has no recipient, so "Invitations received" cannot be real.
Making it real means invites become addressed rather than bearer codes,
which needs a way to find someone — a directory or contact matching — and
that is its own privacy question.

## 5. Guardian photos

Guardian onboarding never asks for one. Whether a Guardian's face should be
visible to a Seeker who unlocks their daughter's profile is unanswered.

## 6. AppState hydration

`surname_line`, `bio`, `created_at` all exist in the database and are all
missing from AppState. Three screens currently carry a "not faked" comment
where they should appear.
