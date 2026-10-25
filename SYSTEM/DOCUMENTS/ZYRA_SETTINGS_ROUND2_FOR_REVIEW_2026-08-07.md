---
id: DOC-ZYRA-0213
type: REPORT
status: DRAFT
feature: IDENTITY AND SIGN-IN
purpose: ZYRA — Settings Round 2: Six Proposals for Review
links: []
owner: ZYRA chat
---

# ZYRA — Settings Round 2: Six Proposals for Review

**Status:** FOR DISCUSSION — nothing built, nothing decided
**Date:** 2026-08-07 · **For:** ChatGPT review, then Founder confirmation

Six items raised by the Founder. Each is checked against what actually
exists in the codebase and against Apple/Google requirements, because three
of them turn out to be constrained by things outside our choosing.

---

## 1. Notifications — TWO axes, and only one is ours

We built `notification_preferences` yesterday: five categories, append-only,
consent-evidenced. That covers **which** notifications a user wants.

It does **not** cover whether the OS will deliver any of them. That is a
separate permission, granted once, and **the app cannot re-grant it**. Once a
user denies notifications at the OS level, the only thing an app may do is
send them to system Settings.

So the section has two rows that look similar and behave completely
differently:

| | Owner | If off |
|---|---|---|
| **Allow notifications** | iOS / Android | We can only offer "Open Settings" |
| **What you're notified about** | ZYRA | Our five categories |

**Requirements that constrain this:**

- **Apple 4.5.4** — push must be optional. The app must work fully without
  it. No feature may be gated behind granting notifications.
- **Apple 5.1.1** — permission must be requested in context, with a purpose
  string. Asking on first launch, before the user knows what ZYRA is, is a
  common rejection reason.
- **Marketing pushes need separate consent** — which our categories already
  record, and which UK PECR requires anyway.

**Proposal:** the Notifications screen shows the OS state at the top, with a
button to system Settings when it is off, and greys the five categories with
a line explaining they cannot fire until notifications are allowed. Ask for
permission the first time something notifiable happens — a first match —
never at launch.

**Open question for review:** is a first match the right moment, or should we
ask when the first Guardian links, which happens earlier?

---

## 2. Language — the honest answer is that it does not exist

**There is no localisation in ZYRA.** Every string is hardcoded English,
inline, across roughly a hundred files. There is no ARB file, no
`intl` setup, no `Localizations` delegate.

A Language row today would be a picker with one option.

**What it actually takes:** extracting every user-facing string into
resource files, wiring `flutter_localizations`, then translating. The
extraction is mechanical but large; the translation is a real cost per
language and needs a native speaker per target, not machine output —
particularly here, where religious vocabulary carries meaning that
translation tools flatten.

**Proposal: leave it out until a language is actually being added.** This is
the same rule that kept Theme off the page — an empty section labelled
"future" is the dumping ground the Founder's own §8 warned against.

**Worth deciding early though:** which languages, because it changes the
extraction. Urdu, Arabic and Bengali are the obvious candidates for this
audience — and **Arabic and Urdu are right-to-left**, which is a layout
change on every screen, not a string swap. Better known now than after
another hundred screens.

---

## 3. Restore Purchases — NOT optional, it is required

**Apple Guideline 3.1.1** requires any app selling non-consumable purchases
or auto-renewable subscriptions to provide a Restore mechanism. An app
without one is rejected.

So the Founder's instinct ("I think so") is right, and stronger than he put
it: **this is a submission requirement, not a nice-to-have.**

**But it cannot be built yet.** Payments are unbuilt — the app currently says
*"Payments are not built yet — nothing has been charged."* Restore restores
receipts from the store, and there are no receipts.

**Proposal:** ships in the same piece of work as in-app purchase, never
before and never after. Add it to the IAP checklist now so it cannot be
forgotten at submission, which is the usual way apps discover this rule.

---

## 4. App lock — this one IS ours, and I think it matters more here than most apps

The Founder said: *"I think that's apple setting not ours."*

**It is ours.** The device passcode locks the phone. An **app-level** lock —
Face ID or a PIN to open ZYRA specifically — is implemented by the app.
Banking apps all do this. Flutter's `local_auth` handles Face ID, Touch ID
and Android biometrics, and **costs nothing**: it is the OS's own
authentication, not a paid service.

**Why this is worth more on ZYRA than on a typical app.** Phones get handed
around in families. A parent, a sibling or a spouse-to-be picking up an
unlocked phone and opening a marriage app is not a rare scenario in this
audience — it is a normal Tuesday. And what is on screen is not just
private, it is socially consequential: who you passed on, who you saved,
what your Guardian said.

An app lock is the difference between "my phone is private" and "this app is
private", and only the second is true when the phone is unlocked and on the
kitchen table.

**Proposal: build it.** Biometric with a 4-digit fallback, off by default,
one toggle. Deliberately NOT a security boundary — the data is protected by
RLS, not by this — it is a privacy screen against the person standing next
to you, which is the actual threat here.

---

## 5. Blocking phone contacts — the Founder's question answers itself, but not the way he expects

He asks: *"do we need block phone contacts if they can only sign up with
apple or google?"*

**Sign-in method is not the obstacle.** OAuth means we have no phone
numbers, but contact blocking never worked from the account's phone number —
it works from **the user's address book**, matched against other users.

**The real obstacle is what it costs the user.** To hide someone you know,
we must read your entire address book, hash it, and compare it against every
other user. That means:

- A contacts permission prompt, which many people decline outright
- Holding hashes of people who are **not ZYRA users and never consented** to
  anything — a genuine GDPR question about processing third-party data
- Matching only works if THEY also shared a number we can match on, which
  OAuth sign-in means we may not have

**But the underlying need is real and specific to this product.** "I do not
want my cousin, my colleague or my student to see me on a marriage app" is
one of the most common reasons people avoid these apps entirely. Muzz
implements exactly this.

**Proposal: not now, and not framed as contacts.** There is a cheaper first
step that gets most of the value: let a user **block someone by their ZYRA
reference code** — which OA-160 already plans — and keep the existing block
list. Contact matching is a large privacy project that should be taken on
deliberately, with a DPIA, not slipped in as a settings row.

**For review:** is there a middle option? Some apps let you enter phone
numbers to block manually, without reading the address book. Slower for the
user, dramatically cheaper on privacy.

---

## 6. Manage Account — the strongest idea in this list

The Founder's point: Delete Account is currently the only exit, and it is
the wrong shape for most of the reasons people leave.

**Five distinct exits, currently collapsed into one:**

| What they mean | What should happen | Exists? |
|---|---|---|
| **Take a break** | hide from Browse, keep everything, come back whenever | ✅ `profiles.is_active` |
| **Start again** | new profile, same account, fresh answers | ❌ |
| **I'm getting married** | leave, happily | ❌ |
| **Delete my profile** | remove the profile, keep the account | ❌ |
| **Delete everything** | GDPR erasure | ✅ `delete_own_account()` |

### "I'm getting married" deserves its own route, and not for sentimental reasons

On a marriage platform, **the successful outcome and the unsuccessful one
currently use the same button.** Someone whose search worked and someone who
gave up in frustration both press Delete Account and read a warning about
permanent data loss.

That is worth fixing on three grounds:

1. **It is the product's whole purpose.** An app that cannot tell the
   difference between success and failure cannot measure whether it works.
2. **It is the only moment someone will ever be glad to hear from you.**
   A testimonial, a review, a referral to a sibling — all reachable here and
   nowhere else in the lifecycle.
3. **It changes what should happen to the data.** Someone leaving because
   they married may want their Journey history kept, or may want it gone the
   most. Asking is better than assuming either way.

### Two questions "Start again" raises that need answering first

**What happens to everything attached to the old profile?**

- Guardians — kept, or re-invited? They linked to *them*, not to a profile
- Unlock credits — a paid balance survives, surely?
- Journeys — an Active Journey with another person cannot silently vanish;
  the other party is owed something
- The people who Considered them — do those decisions carry over?

**And is it distinguishable from delete-and-signup?** If not, it is a
convenience rather than a feature, and the honest version might be "clear my
answers and start onboarding again", which is much smaller.

### Proposal for the section

```
ACCOUNT
  Personal information
  Sign-in & security
  App lock                          ← §4
  Advanced  →
       Take a break
       Start again
       I'm getting married  💚
       Delete account
```

**Take a break** is first and reversible. **Delete** stays last. The married
route sits with them because that is where someone looks when they want to
leave — but it should not look like the others when they get there.

---

## Summary of what I would actually do

| # | Item | Verdict |
|---|---|---|
| 1 | Notifications | **Build** — OS state + our categories, two rows |
| 2 | Language | **Defer** — nothing to pick between. Decide target languages early because of RTL |
| 3 | Restore Purchases | **Required** — but only alongside IAP |
| 4 | App lock | **Build** — cheap, and more valuable here than in most apps |
| 5 | Contact blocking | **Defer** — do reference-code blocking first |
| 6 | Manage Account | **Build** — five exits, and the married one matters most |

**Two things I would like challenged:**

- Is an app lock really worth it, or does it just add friction to a product
  people already open furtively?
- Does "Start again" survive contact with the Guardian and Journey
  questions, or does it collapse into "clear my answers"?
