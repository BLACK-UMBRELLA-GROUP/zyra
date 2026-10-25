---
id: DOC-ZYRA-0212
type: REPORT
status: CURRENT
feature: IDENTITY AND SIGN-IN
purpose: ZYRA — Settings: Holistic Review
links: []
owner: ZYRA chat
---

# ZYRA — Settings: Holistic Review

**Status:** HISTORICAL REVIEW — Settings built; Profile Personalisation added 2026-08-29
**Date:** 2026-08-06 · **Origin:** Founder review, 8 points
**Brief:** *"Settings should feel like the user's control centre… not a
dumping ground, nor a duplicate of pages that already exist."*

> 2026-08-29 current amendment: the older Appearance/Theme gap below is now
> partly closed through a shared Seeker/Guardian **Profile → Personalisation**
> screen. It owns dark background, app-text and haptic choices. Language is
> still not built. Current implementation truth lives in
> `ZYRA_STYLE_DEFAULT_HANDOVER_CURRENT_VERSION_V1.md` §11.

---

## The diagnosis: there is no Settings page

Settings is a **section inside `profile_screen.dart`** — a `SETTINGS` label
followed by seven rows, sitting below the profile card and a list of
Connections counts.

That single fact explains most of the review:

- **§5 account dashboard** — a section cannot have a dashboard. Whatever you
  put at the top would be the top of the *Profile* page.
- **§4 six groups** — nesting six labelled groups inside a page that already
  has profile fields and Connections counts makes it longer, not clearer.
- **§1 Delete Account too prominent** — it is prominent because a flat list
  of seven has no hierarchy to demote anything into.
- **§3 don't duplicate** — the page already does. `Passed`, `Saved` and
  `Considered (Outgoing)` are rendered as rows, which is precisely the
  Connections duplication the principle forbids.

**So the first change is structural, not cosmetic: Settings becomes its own
screen**, reached from Profile. Then the groups, the dashboard and the
nesting all have somewhere to live, and Profile goes back to being a
profile.

---

## Honest inventory

| Your point | Buildable | Note |
|---|---|---|
| 1 Nest Delete Account | ✓ | Needs the screen first |
| 2 Manage onboarding answers | **partly** | Gaps 1 and 3 |
| 3 No duplication | ✓ | And removes duplication already present |
| 4 Group into sections | **partly** | Email and Password do not exist — gap 2 |
| 5 Account summary | ✓ | All four values available |
| 6 Show current values | **partly** | Email yes; Language/Theme are unbuilt |
| 7 Premium onboarding editor | **partly** | Gap 3 |
| 8 Holistic | — | This document |

---

## The three gaps

### Gap 1 — Half the onboarding answers cannot be edited, by design

C-3 locked profile writes down. A Seeker can now update exactly five
columns directly: `first_name`, `surname_line`, `bio`, `location_text`,
`is_active`.

**`gender` and `date_of_birth` are frozen once published.** That was a
deliberate integrity decision, not an oversight: a platform where someone
can change their age or gender after being seen in Browse is a platform
where that will be used to deceive. On a marriage platform with families
involved, that matters more than convenience.

So "revisit and update your onboarding responses" has a hard boundary
through the middle of it. Chapter 1 — the identity answers — is largely
**not** editable and should not become so casually.

**Recommend:** show them, clearly marked as fixed, with a line explaining
why and a route to support for genuine corrections. A field that is simply
absent reads as a bug; a field that is present and explained reads as a
policy. Genuine mistakes do happen and need a human path, not a toggle.

### Gap 2 — Email and Password are not built, and may not apply

Your §4 lists both under Account. Neither exists: there is no
`updateUser`, no `resetPasswordForEmail`, nothing anywhere in the codebase.

More importantly, **ZYRA has OAuth sign-in**. A user who signed in with
Google or Apple has **no password to change**, and their email is owned by
the identity provider — ZYRA cannot change it and should not appear to.

**Recommend:** the Account section reads the user's auth provider and shows
the truth:

| Signed in with | Email row | Password row |
|---|---|---|
| Email + password | shown, editable (re-verify) | Change password |
| Google / Apple | shown, read-only, *"Managed by Google"* | **not shown** |

A "Change Password" row that errors for half the user base is worse than no
row. This is its own piece of work — account security, verification emails,
re-authentication — and I would not fold it into a Settings restructure.

### Gap 3 — The Green / Yellow / Red answers have never been saved

`onboarding_answers` holds `ch3_answers`, `ch4_preferences` and
`ch4_hard_requirements`. **It has zero rows.**

Unlike the three previous cases of this defect, the write path DOES exist —
`ZyraOnboardingAnswersService` upserts from `values_preferences_flow`. So
this is not the missing-write bug again. It is that no account has been
through that flow: the 120 seeded profiles were inserted directly, and real
testing has not reached Chapter 3.

**Consequence for §7:** an editor for these answers is correct code that
cannot be verified against a single real row. I would seed a test account
through the real flow before building on top of it, rather than shipping a
review screen whose reads have never returned anything.

---

## What I would build

### Structure

```
Profile                     ← profile only; Connections rows REMOVED (§3)
  └── Settings              ← new screen

Settings
  ┌──────────────────────────────────┐
  │  Profile     92% complete        │   ← §5 dashboard
  │  Guardian    1 Main · 2 linked   │
  │  Membership  ZYRA One            │
  │  Compatibility  updated 12 Jul   │
  └──────────────────────────────────┘

  ACCOUNT
    Personal information
    Email            shakeel@…          ← §6 current values
    Sign-in          Google             ← honest for OAuth
    Account           →  (Delete Account nested here)   ← §1

  COMPATIBILITY
    About you                           seeker_details, editable
    Your preferences                    ch4_preferences
    Green / Yellow / Red                ch3_answers
    Fixed details        Name, age, gender   ← visible, explained, locked

  PRIVACY
    Profile visibility · Discovery · Blocked users

  NOTIFICATIONS
    Push · Email

  SUPPORT
    Help centre · Contact · Terms · Privacy policy
```

**Appearance is omitted.** Theme and Language do not exist, and §8 says
Settings should not become a dumping ground — an empty section labelled
"future" is exactly that. It goes in when it does something.

### §7 — the onboarding editor

Not a re-run of the flow. A **review screen per chapter**: every question
with its current answer, tap one to change it, one Save. Jumping to a
section, changing one answer and leaving is the whole point.

Two things it must do that a re-run would not:

- **Show what is locked**, in place, with the reason — see gap 1.
- **Say what a change affects.** Editing preferences changes who you are
  matched with. Silently re-scoring someone's matches because they tapped a
  row in Settings is a surprise; saying so first is not.

---

## What I need from you

1. **Settings as its own screen**, with Profile losing the duplicated
   Connections rows — agreed?
2. **Locked fields** (name, age, gender) — show them greyed with an
   explanation, or omit them entirely?
3. **Email / Password** — leave out of this work as its own account-security
   piece, or block Settings on it?
4. **Seed a real account through Chapter 3** before building the editor, so
   it is built against real rows rather than an empty table?

Six-layer dependency review to follow once these are settled.
