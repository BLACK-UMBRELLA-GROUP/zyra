# ZYRA — Profile Page: Holistic Review

**Status:** FOR REVIEW — nothing built
**Date:** 2026-08-06 · **Origin:** Founder review, 8 points
**Brief:** *"Profile should be where people feel proud of their profile…
'My profile and how other people see me.'"*

---

## The framing is right, and it makes one thing obvious

Four pages, four responsibilities:

| Page | Owns |
|---|---|
| Profile | my profile, and how others see me |
| Settings | my account and preferences |
| Connections | my interactions |
| Guardians | my Guardian network |

Under that test the current page fails three times: `PUBLIC INFORMATION`
belongs to Settings → Compatibility, `YOUR CONNECTIONS` belongs to
Connections, and the Settings section already moved out this morning.

**§1, §7 and half of §8 are the same change** — delete what other pages own.
That is the cheapest work here and the biggest single improvement.

---

## What exists, and what does not

| Your item | Reality |
|---|---|
| Remove Public Information | ✓ delete only |
| Photo carousel, name, age, bio | ✓ all present |
| Edit Photos | ✓ exists |
| **Preview Profile** | **not built** |
| **Share Profile** | **not built** |
| **Invite Friend** | **not built** — and no referral concept at all |
| **Profile Strength %** | `profile_complete` is a **boolean**. There is no percentage |
| Active Journeys | ✓ readable |
| Guardian Introductions | ✓ readable |
| **Profile Unlocks / Unlock+** | data exists, **but you cannot read it about yourself** |
| **Profile Views** | **nothing tracks views. No table, no events** |

---

## The four that need a decision, not just building

### 1. "92% Complete" has to be defined before it can be shown

`profiles.profile_complete` is a boolean — done or not. A percentage does not
exist and cannot be derived without someone deciding **which fields count
and what each is worth**.

That is a product decision with teeth, because **the number changes
behaviour**. Whatever we weight is what people will rush to fill in. Weight
photos heavily and we get more photos; weight the compatibility answers
heavily and we get better matching and slower onboarding.

**Recommend:** weight it toward what improves *matching*, not what improves
*appearance* — the compatibility answers and About Me above extra photos.
And never show 100% while anything meaningful is unanswered, or the number
stops meaning anything the first time someone hits it.

### 2. Profile Views does not exist, and is not a small feature

No table, no events, nothing. Building it means recording, for every Seeker,
who looked at them and when — the most sensitive behavioural data the
product would hold, on a marriage platform, about people who are often
being watched by family.

It also changes how the product feels. A view counter turns browsing into
something observed, and on a platform whose whole proposition is modesty and
intention, that is a real shift rather than a metric.

**Recommend: leave it out.** If it goes in later it needs its own privacy
decision, its own retention rule, and a line in the Privacy Policy — not a
row on a card.

### 3. "Profile Unlocks" is readable — but not by you

`profile_unlocks` has a SELECT policy of `unlocker_id = auth.uid()`. You can
see the profiles **you** unlocked. Nothing lets you see who unlocked **you**.

That is not an oversight to patch. Showing "8 people unlocked your profile"
is a new disclosure, and it cuts both ways: it is genuinely motivating, and
it is also a number that will make some users feel surveilled or judged, and
a low number is a bad experience nobody asked for.

**Recommend:** if we show it, show it as a **count only, never identities**,
via a purpose-built RPC — and only Unlock+ counts, since that is the one
that signals real intent. I would not show a zero; show nothing until there
is something to say.

### 4. Share and Invite are a referral feature, not two buttons

Neither exists, and there is no referral concept anywhere. "Share Profile"
also needs an answer to *what does the recipient see* — ZYRA profiles are
gated behind sign-in and unlocks, so a shared link either leaks a profile or
lands on a sign-up page.

**Recommend:** **Invite Friend** first, as a plain app-store link — useful,
honest, no new data model. **Share Profile** waits until there is something
safe to share, because the obvious implementation is the one that leaks.

---

## What I would build

```
┌──────────────────────────────┐
│    large photo carousel      │   §5 — the profile IS the page
└──────────────────────────────┘
  Amina, 27 · Birmingham
  Short bio

  [ Edit Photos ]  [ Edit Profile ]     §6 — actions, not data

  ┌────────────────────────────┐
  │  Profile strength   78%    │        §3 — only if defined first
  │  Add two more photos       │
  │  Finish your preferences   │
  │              [ Continue ]  │
  └────────────────────────────┘

  THIS MONTH                            §4 — only what is true today
    Active Journeys           2
    Introductions             5
```

Gone: `PUBLIC INFORMATION`, `YOUR CONNECTIONS`.
Not included: Profile Views, Share Profile, and the unlock counts until the
disclosure question above is answered.

**One deliberate omission from §6.** *Preview Profile* is the best idea in
the brief — "how other people see me" is the page's stated purpose and a
preview is literally that. It is not built, and it is not trivial: it needs
to render the Browse card as a *stranger* sees it, which means honouring
unlocks, gender rules and blocks rather than just showing your own data
back. **Worth doing properly, as its own piece.**

---

## What I need from you

1. **Profile strength** — agree the weighting favours matching over
   appearance? And what counts?
2. **Profile Views** — leave out?
3. **Unlock counts** — show a count of Unlock+ only, or leave out until the
   disclosure is decided?
4. **Preview Profile** — its own piece of work, after this?
