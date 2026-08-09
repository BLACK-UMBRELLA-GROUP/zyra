# ZYRA Error & Empty State Language Standard
**ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1**
Last updated: 2026-07-18
Authors: Lead Architect (Claude), for Founder review
Resolves: UX Writing/Summary.md, Approved To-Do List — "Define
approach for error messages (currently not covered)."

---

## Purpose

WARM & FAMILY-ORIENTATED UX WRITING (APP/UX Writing/Summary.md)
defines ZYRA's tone for the happy path — waiting states,
notifications, milestones. It explicitly left one item open:
error messages. This document closes that gap and extends the
same philosophy to the three situations the happy-path guide
doesn't cover: something went wrong, there's nothing here yet,
and something is disabled.

This is a PROPOSED standard, applied across the app in this
build pass, pending Founder review — same status discipline as
DR-ZYRA-079 (compatibility scoring). Not silently treated as
final; flagged for sign-off.

---

## Core Rule

Same test as the happy-path guide: **does this sound like a
person, or like software?** Errors should feel like a calm host
explaining a small hiccup, not a system logging a failure code.

Never show a raw exception, stack trace, or backend error string
to the user. Every error the app can anticipate gets a written,
warm, specific message. Errors it cannot anticipate fall back to
one generic warm message (see "Unknown Errors" below) — never a
blank screen or a red "Error: null".

---

## Category 1 — Field Validation (user hasn't given us enough yet)

These are not failures — the user is mid-thought. Tone should be
gentle, not corrective.

| Situation | Avoid | Use |
|---|---|---|
| Empty required field | "This field is required" | "Let us know your name to continue." |
| Invalid email format | "Invalid email address" | "That email doesn't look quite right — check for typos." |
| Password too short | "Password must be 8+ characters" | "Choose a password with at least 8 characters." |
| Passwords don't match | "Passwords do not match" | "Those two passwords don't match yet." |
| DOB missing / under 18 | "Invalid date of birth" | "You'll need to be 18 or over to continue." |
| Fewer than 3 photos chosen | "Minimum 3 photos required" | "Choose at least 3 photos so others can get to know you." |
| No search results | "No results found" | "No matches for that — try a different spelling." |

Shown inline, beside the field, in Rose Pink (#D4868F) at low
weight — never a modal, never blocking the whole screen.

## Category 2 — Simulated Backend / Auth Errors

Until Supabase is connected (OA-101/OA-102), these are triggered
by mock conditions in the app so the copy and layout exist ahead
of the real integration.

| Situation | Avoid | Use |
|---|---|---|
| Wrong password | "Incorrect password" | "That password doesn't match this account. Try again?" |
| Email not confirmed | "Email not verified" | "Check your inbox to confirm your email before continuing." |
| Account not found | "User not found" | "We can't find an account with that email." |
| Network unreachable | "Network error" / "Failed to fetch" | "Having trouble connecting. Check your connection and try again." |
| Verification (ID/photo) failed | "Verification failed" | "We couldn't confirm this — you can try again, or continue in limited mode for now." |
| Send-message failure | "Message failed to send" | "That didn't send. Tap to try again." |

These appear as a small inline banner or retry affordance next
to the action that triggered them — not a full-screen takeover,
consistent with "never feel like a workflow engine."

## Category 3 — Empty States (nothing here yet, by design)

Distinguish "nothing yet" from "something's wrong" — an empty
state is not an error and should never look like one.

| Screen | Use |
|---|---|
| Browse — no more profiles | "You're all caught up — more members will appear as new people join." |
| Matches — no Journey Queue | "Nothing here yet — when you and someone else Like each other, it'll show up here." |
| Matches — no Active Journeys | "Once you Start a Journey, it continues here." |
| Incoming Potentials (Basic tier tease) | "See who's already interested — available with ZYRA One." |
| Chat — first message | "Say Salam to start your Journey with [Name]." |
| Saved (bookmarked) list — empty | "Anyone you Save privately will appear here." |

## Category 4 — Disabled / Locked States

Explain *why*, don't just grey something out silently.

| Situation | Use |
|---|---|
| Daily Like/Save limit reached (Basic) | "You've used today's Likes — more unlock with ZYRA One, or resets in [time]." |
| Feature is ZYRA One only | "This is part of ZYRA One." (paired with an upgrade path, not a dead tap) |
| Continue button disabled mid-form | Don't disable silently — the nearest unanswered field should be visually indicated so the user knows what's blocking them. |

## Category 5 — Unknown / Unanticipated Errors

Fallback only, for anything not covered above:

> "Something didn't quite work. Please try again — and if it
> keeps happening, let us know."

Never expose the underlying exception. Log it internally
(future: crash/error reporting, not yet wired — see Outstanding
Actions) but the user only ever sees the warm fallback.

---

## Visual Treatment

- Inline field errors: small text directly under the field, Rose
  Pink (#D4868F), no icon, appears/disappears with the field's
  focus state — never a popup.
- Banner-style errors (auth, network, send failure): a soft
  rounded banner near the action, dismissible, using the existing
  glass surface treatment (`GlassIconButton`'s tint/blur system)
  rather than a harsh red block.
- Empty states: centred, low-emphasis icon + one line of copy +
  (where relevant) one CTA — never just blank space, per the
  "never feel like a checklist" principle.

---

## Approved To-Do (carried over, now scoped)

- [x] Define approach for error messages — this document.
- [ ] Founder review and ratification of this standard.
- [ ] Apply consistently across all screens (in progress, this
      build pass — 2026-07-18).
- [ ] Revisit auth error copy once Supabase is actually connected,
      to confirm real error codes map cleanly onto the categories
      above (some backend errors may not fit neatly).

---

*Cross-reference: APP/UX Writing/Summary.md, SYSTEM/OUTSTANDING_
ACTIONS/OUTSTANDING_ACTIONS_V2.md (OA-102 §Basic error handling),
SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md (DR-ZYRA-080)*
