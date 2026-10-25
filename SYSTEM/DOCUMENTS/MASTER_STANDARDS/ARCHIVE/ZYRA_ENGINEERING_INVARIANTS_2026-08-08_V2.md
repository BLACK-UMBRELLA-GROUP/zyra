# ZYRA — Engineering Invariants

> **ARCHIVED 2026-08-08 — reference only. Superseded by V3, which is the
> source of truth.** V2 holds I1–I7; V3 adds two Founder-directive corollaries
> (deployed system outranks the source file, under I5; explicit grants after
> explicit policy, under I4). Where this document and V3 differ, V3 wins.

**Version:** V2
**Status:** APPROVED — Founder, 2026-08-08
**Supersedes:** V1 (same day; V1 held I1–I4 only)
**Applies to:** every migration, feature and review, in every area

Sibling to the Six-Layer Review Standard, and written for the same reason.
That standard came from three estimation errors of one class; this comes from
design errors of one class. Both exist so the class is recognised next time
instead of rediscovered.

**These outrank feature documents.** Where an invariant and a spec conflict,
the invariant wins and the spec is wrong.

---

## I1 · Permanent behaviour must derive from permanent data

> **Temporary state — blocks, invitations, sessions, toggles, publication
> flags — must never be the sole source of a permanent permission or
> restriction.**

### Where it came from

Two bugs, unrelated areas, five days apart, identical shape:

| | Keyed on (temporary) | Corrected to (permanent) |
|---|---|---|
| **Identity freeze** — gender and DOB frozen after publication | `profile_complete`, which the user may switch off | `first_published_at`, written once and never cleared |
| **Block revocation** — visibility revoked when someone is blocked | a `profile_blocks` row, which the user may delete | `end_reason = 'safety_concern'`, recorded on the match forever |

Both read correctly. Both were undone by a state the user controls.

The first became a loophole: un-publish, change your identity, republish. The
second was caught by its own verification within minutes of being applied —
unblocking silently restored visibility the invariant said must never return.

### The test

For any permanent consequence:

> **Can the user clear the thing this depends on?**

If yes, it is the wrong anchor. Find the fact that cannot be cleared.

### Corollaries

- **A reversible flag is not a fact about the past.** `profile_complete`
  answers *"are they published now"*, never *"were they ever"*.
- **Deletion is a user action.** Any row a user may delete is temporary,
  however permanent its meaning feels.
- **It applies outside the database too.** A reference keyed on a filename
  containing a version number is a permanent link resting on a temporary
  name — now Naming Conventions rule 5.

---

## I2 · A block is a terminal safety boundary

> **Nothing may automatically recreate or restore any relationship,
> visibility, conversation or Journey that existed before a block. Any future
> interaction must begin as an entirely new relationship under the normal
> rules.**

What it does **not** forbid: two people who unblock may find each other
through ordinary Browse and start fresh. They are two eligible users, not a
restored pair. **Ordinary discovery is not restoration.**

---

## I3 · One path, or the paths will drift

> **Where two operations must be indistinguishable, they must share one
> implementation — not two implementations kept in step.**

Ordinary Journey endings and safety endings both run through
`zyra_end_match_internal()`. Two paths would eventually diverge, and **the
divergence would itself be the disclosure** that the whole substitution exists
to prevent.

Generalises: any time correctness depends on two things *looking the same*,
sameness must be structural rather than maintained.

---

## I4 · A rule inside one function applies only to that function's callers

> **Enforce at the layer that cannot be skipped. A rule in application code is
> a convention; a rule in a policy or constraint is an invariant.**

Recorded from the same review cycle:

- The romantic-eligibility rules went into the **RLS `WITH CHECK`**, not only
  the match trigger — a trigger can be disabled for a transaction, and this
  project disabled one twice in one day to run backfills.
- `zyra_can_guardian_link()` began as an inline `EXISTS` inside
  `accept_wali_invite()`. Correct for the only write path that existed;
  invisible to the next one. It is now a predicate plus a `BEFORE` trigger.
- Column-level ownership that RLS cannot express — one column, private for one
  value and joint for five — is enforced by **revoking the column** and
  exposing an accessor, following `profiles.date_of_birth`.

### Corollary — grants are three separate things

`PUBLIC`, `anon` and `authenticated` are independent. Revoking one does not
touch the others, and Supabase's default privileges grant `anon` explicitly.
**Verify every grant change with `has_function_privilege()` or
`information_schema`; never assume a statement did what it reads like.**

This project has been caught by that fact three times.

---

## I5 · A match tells you a string is present, not what it means

> **Before a pattern match drives a decision, read the line it came from. A
> regex reports presence, never meaning.**

### Where it came from

Two errors, same day, both in governance work, both from trusting a match
without reading it:

| | The match | What it actually was |
|---|---|---|
| **Reference audit** | `[A-Za-z0-9_]+\.md` returned fragments like `VERSION_V1.md` | Halves of filenames split across wrapped comment lines. Dismissed as noise — and one of them was a real dangling reference, the one that led to the pricing defect |
| **Next OA identifier** | `OA-ZYRA-\d{3}`, highest match `OA-ZYRA-166` | The register's own `NEXT IDENTIFIER:` line. An ID named *because it was unused*. A reservation read as a record |

The first undercounted the audit and hid a product defect for weeks. The
second would have burned an identifier and left a permanent gap in a governed
register.

### The test

> **What kind of line did this match come from?**

Reserved identifiers, metadata, templates, examples, comments, archived
entries and real records all satisfy the same pattern. Only the surrounding
line distinguishes them.

### Corollaries

- **Counting matches is not measuring.** Both errors were counts that looked
  authoritative because they came from a tool.
- **A match you discard needs the same scrutiny as one you keep.** The audit's
  error was in what it *rejected*.
- **Prefer a tool that shows its evidence.** `zyra_check.py` reports file and
  line for every finding; that is what made the pricing defect findable.

---

## I6 · Tools report; owners decide

> **Governance and engineering tools may discover product, security or
> commercial issues, but they report them rather than resolve them
> automatically. Ownership stays with the appropriate decision maker.**

**Origin:** Founder directive, 2026-08-08.

Applied the day it was written. The reference checker exposed that the upgrade
screen quotes pricing from a superseded spec — four prices and two product
names. Nothing was corrected. Prices are a **commercial** decision, not an
engineering one, and a tool that had "fixed" them would have made a pricing
change with no one accountable for it.

What happened instead: a `⚠ STALE` marker in the source file, a finding
document, and **OA-ZYRA-166** left open pending the Founder's decision.

### Corollary — report in the artefact, not only in a document

A finding recorded only in a report is a finding the next reader of the code
will not see. The `⚠ STALE` marker sits in `upgrade_screen.dart` itself, where
the false claim used to be. **The correction must live where the mistake
lived.**

---

## I7 · A check's scope grows only by approval

> **When an automated check uncovers an issue outside its original purpose,
> treat that as evidence the check is valuable. Record the finding — but do
> not expand the tool's scope automatically. New responsibilities are
> explicitly approved.**

**Origin:** Founder directive, 2026-08-08.

The `DANGLING DOC REF` check exists to answer one question: *does every
document a comment names still exist?* It found a pricing defect. The
temptation is to teach it to compare UI figures against spec figures — and
that is how a focused check becomes a catch-all that nobody trusts or
maintains.

It was not extended. The limit is written into OA-ZYRA-166's `Automation:`
field in plain terms: the check catches the broken reference, not the price
drift. **An unstated limit reads as coverage.**

### Corollary — I7 and I4 are not in tension

I4 says put an approved rule where it cannot be skipped. I7 says a new rule
needs approval before it exists. **I7 governs whether; I4 governs where.**
They apply in that order.

---

## Applying these

Every migration plan states which invariants it touches and how it satisfies
them. A plan that cannot name one is not necessarily wrong — but a plan that
*violates* one needs the invariant changed first, in this document, with the
Founder's approval.

### How an invariant gets admitted

Two routes, and the origin is always recorded:

1. **A mistake made twice.** Once is an error; twice is a class. I1 and I5
   arrived this way.
2. **Founder directive.** A principle set deliberately rather than learned
   from a defect. I6 and I7 arrived this way, both on 2026-08-08.

V1 stated only the first route. It was written before the second was used, and
adding entries under an admission rule that did not cover them would have been
the same quiet drift these invariants exist to prevent.
