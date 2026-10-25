---
id: DOC-ZYRA-0203
type: REPORT
status: DRAFT
feature: IDENTITY AND SIGN-IN
purpose: ZYRA — Identity Changes & the Sign-in Section
links: []
owner: ZYRA chat
---

# ZYRA — Identity Changes & the Sign-in Section

**Status:** FOR DISCUSSION — nothing built, nothing decided
**Date:** 2026-08-07 · **For:** ChatGPT review, then Founder confirmation
**Companion to:** `ZYRA_SETTINGS_ROUND2_FOR_REVIEW_2026-08-07.md`

Two questions from the Founder:

1. What happens if a user changes their **name**, **date of birth** or **gender** in the app — and what if it no longer matches their ID?
2. We should show **where they signed in**. Do we show the email address they used with Apple or Google?

Both were checked against the live database rather than answered from
design intent, and both turned out differently from the question's
assumption.

---

# PART A — Identity changes

## A0. The short answer: two of the three cannot be changed at all

The Founder's question assumes name, DOB and gender are editable. Two of
them are not — and not by convention, but because the database will not
accept the write.

`authenticated` holds a **column-level UPDATE grant on five columns only**:

```
bio · first_name · is_active · location_text · surname_line
```

`date_of_birth` and `gender` are **absent from that list**. A client
sending an update for either is rejected at the privilege layer, before
RLS is even consulted. There is no client path — no screen, no API call,
no hand-crafted request with a valid session — that changes a published
user's gender or date of birth.

That is a good piece of design and it is worth saying plainly, because it
means most of the "how does the app react" question has no answer: the
situation cannot arise.

| Field | Client can UPDATE? | Enforced by | Readable by others? |
|---|---|---|---|
| `first_name` | **Yes, freely** | — | Yes |
| `surname_line` | **Yes, freely** | — | Yes |
| `bio` | Yes, freely | — | Yes |
| `date_of_birth` | **No** | no column grant | **No** — others get a derived age via `ages_for()` |
| `gender` | **No** | no column grant | Yes |

---

## A1. The exception nobody designed — and it is real

Gender and DOB *can* still be written, by one route: `zyra_create_profile()`,
which runs `SECURITY DEFINER` and therefore ignores the column grants.

It guards itself deliberately:

> *"Already published: identity is frozen. Name stays editable through the
> ordinary column grant, so this is not a dead end for someone fixing a
> typo — only for someone changing who they are."*

If `profile_complete` is true it updates the name and nothing else. Correct.

**But `zyra_set_profile_complete(false)` un-publishes unconditionally.** Its
own comment explains why, and the reasoning is sound:

> *"Un-publishing is always allowed: nobody should need permission to
> withdraw themselves."*

Put the two together:

```
zyra_set_profile_complete(false)   →  profile_complete = false
zyra_create_profile(..., gender, dob)  →  "still onboarding, everything is
                                           correctable"  →  gender AND dob change
zyra_set_profile_complete(true)    →  republished, new identity
```

Each function is right on its own. Neither knows the other exists. The
freeze is therefore a **policy with an undesigned exit**, not a guarantee.

**This is not a security hole** — nothing crosses a user boundary, and
someone can only do it to themselves. It is a correctness question: we
either mean the freeze or we do not, and right now the code says both.

**Two ways to resolve it, and they are genuinely different decisions:**

| Option | What it means |
|---|---|
| **Close it** — `zyra_create_profile` refuses gender/DOB changes on any profile that has *ever* been published (needs a `published_at` or a flag, since `profile_complete` is reversible) | The freeze becomes true. Corrections need a support route. |
| **Keep it open, deliberately** | Un-publishing becomes the sanctioned correction route — but then it must be visible, and the consequences below must be handled. |

**I recommend closing it**, for the reasons in A3. But it should be a
decision, not a side effect.

---

## A2. Changing your name — what actually happens

Name is the one field that *is* freely editable, and the app's reaction to
a change is mostly correct and quietly wrong in three places.

**Follows the change immediately (correct):** Browse cards, profile
headers, `guardians_for_unlocked()`, `zyra_guardian_activity()`,
`preview_wali_invite()`, `accept_wali_invite()`. All read `first_name`
live.

**Does NOT follow — frozen snapshots:**

- **`notifications.body`.** Both notification triggers bake the name into
  free text at the moment of writing:
  `create_notification(a_id, 'new_match', 'New Match', b_name || ' matched with you.')`
  and `notify_new_message` uses the sender's name as the notification
  **title**. Change your name and every past notification still shows the
  old one, forever. The other person's history says "Aisha matched with
  you" while their Connections list says Sara.
- **`profile_reports`.** Stores `reported_id` only — no name snapshot. The
  ID trail is intact, which is the important half. But a moderator opening
  a three-week-old report sees today's name with **no indication it ever
  changed**, and "they gave a different name" is itself a reportable
  pattern.
- **There is no history at all.** The only trigger on `profiles` is
  `profiles_updated_at`. A name change moves a timestamp and overwrites the
  value. Nothing records what it was.

**And it is unvalidated on the path the app actually uses.**
`zyra_create_profile` checks `char_length ≤ 60` and trims — but the app
edits names through the *column grant*, not that RPC. On the column path
there is **no length limit, no trim, and no character rule**, because there
is no CHECK constraint on `first_name`. A 4,000-character name is currently
accepted and will be rendered on a Browse card.

**Proposal:** add the constraint at the table so both paths obey it; leave
name editable; and record name changes in a small append-only log — for the
same reason `notification_preferences` is append-only. On a platform where
a Guardian vouches for a person and strangers meet on the strength of it,
"this person has changed their name four times this month" is a signal
safety needs and cannot currently see.

---

## A3. Changing DOB and gender — the right answer is a *route*, not a *field*

Because both are frozen, the real question is not "how does the app react"
but **"what does someone do when it is genuinely wrong?"** — and today the
answer is: delete the account and start again, losing Guardians, Journeys,
unlock credits and any subscription.

That is not sustainable, for one reason:

> **UK GDPR Article 16 gives a data subject the right to have inaccurate
> personal data rectified without undue delay.**

A permanent lock with no correction route is not a compliant position. But
neither is a free edit field. **The correct design is a supported
correction route** — a request that a human handles — and the two fields
need different ones.

### Date of birth — a correction, and it should be rare and reviewed

Mistyping a birth year in onboarding is common and completely innocent. But
DOB is also the field an underage user would change, so it cannot be
self-service.

Note what makes this cheaper than it looks: **DOB is not client-readable at
all.** It is absent from the `authenticated` SELECT grant, and other users
only ever see an age derived by `ages_for()`. So a correction changes a
displayed number and nothing else — no denormalised copy has to be chased.

Note also that `profiles_adult_only` — `date_of_birth <= CURRENT_DATE - 18
years` — is evaluated **only when the row is written**. Existing rows are
never re-checked. That is harmless in this direction (people only get
older) but it means the constraint proves someone was 18 *at the moment of
writing*, not that they are now, and it is not the thing keeping minors off
the platform. Nothing is. That belongs in the safety review, not here.

### Gender — should stay frozen, and here is the specific damage

`zyra_can_view_profile()` decides Browse visibility with:

```sql
and p.gender <> viewer.gender
```

A gender flip therefore **inverts the entire visible population** — you
vanish from everyone who could see you and appear to everyone who could
not.

**But existing matches survive it.** Visibility for a matched pair comes
from a different clause — the attempt-participant set — which never
consults gender. So a flip leaves live same-gender Journeys running, in
conversation, invisible to the very rule that exists to prevent them. On
this product that is not an edge case, it is a breach of the premise.

It also lands on: the male-Guardian model (`createWaliProfile` hardcodes
`gender: 'male'`, and V6 is the approved source of truth), the entire app
colour scheme (`ZyraColors.genderGradient(state.gender)`), and every
gender-scoped modesty and photo rule.

**Proposal:** gender stays frozen permanently. A genuine correction — a
mis-tap in onboarding, caught within days — is handled as a support case
that recreates the profile, with the person told plainly that Journeys
cannot survive it. That is honest, and it is also true.

---

## A4. "…and it's not the same as their ID"

Worth naming directly: **ZYRA has no ID verification.** No document check,
no `verified` column on `profiles`, no provider integration. The Verified
badge was removed from the Guardian page on the Founder's own instruction
this week. So today there is no ID for a name to disagree with.

The question is therefore really *"should there be?"* — and the honest
framing is that **identity verification and identity mutability are one
decision, not two.** If verification is ever added:

- **The freeze becomes an asset.** A verified DOB that cannot be edited is
  worth something. A verified DOB behind an editable field is worth nothing.
- **Name must gain a legal-change route.** Marriage and deed poll are
  ordinary events, and on a *marriage* platform a surname change is a
  foreseeable one. A route that assumes names never change will break for
  exactly the users the product succeeded for.
- **A name changed after verification must lose the badge**, not silently
  keep it. Verification that survives the thing it verified is worse than
  none, because people trust it.

**For review:** is verification in scope at all before launch? It changes
the shape of A2 and A3 substantially, and it interacts with the contact
blocking and safety questions in the Round 2 document. I have not assumed
either way.

---

# PART B — The Sign-in section

## B1. What is already built, and the bug in it

Settings already has a **Sign-in & security** row that opens a dialog
showing the provider and the email, plus a line explaining ZYRA stores no
password. The summary card also shows "Signed in with —".

The provider comes from:

```dart
final p = u?.appMetadata['provider'] as String?;
return switch (p) {
  'google' => 'Google',
  'apple'  => 'Apple',
  _        => 'Your provider',
};
```

**Every account in the database today falls through to the default.** All
**149** `auth.identities` rows have `provider = 'email'` — every one is a
seeded test account created through the password provider that remains
enabled server-side. **Not one Google or Apple identity has ever been
created.**

So right now the panel reads *"Signed in with Your provider"*, and the
supporting line reads *"…managed by Your provider."* It will keep reading
that way through every dev and TestFlight session until real OAuth is wired
up — which is precisely when nobody is looking at it any more.

**Small fix, worth doing now:** make the fallback name the truth
(`'Email & password (test account)'` in debug, and treat an unknown
provider as a state to log rather than paper over). A default branch that
produces a plausible-looking string is how a display bug survives to
launch.

---

## B2. Do we show the email address? Yes — but it means two different things

**With Google** the address is the user's real Google address. Showing it
is useful and expected.

**With Apple it usually is not.** If the user picks *Hide My Email*, Apple
mints a random relay address ending `@privaterelay.appleid.com` and
forwards to their real inbox. That relay string is the only address ZYRA
ever receives. (The Founder's own Apple-relay address in this session is
exactly this shape.)

Showing a bare `k7xq2p…@privaterelay.appleid.com` with no explanation is
honest and useless. Worse, it reads as an error — the user concludes ZYRA
has the wrong address and goes looking for a way to correct it, which does
not exist.

**Three further facts that make this section carry more weight than it looks:**

1. **Apple returns the user's full name only on the *first* authorization.**
   Never again on any subsequent sign-in. If ZYRA does not capture it at
   that moment it is gone permanently — reinstalling does not bring it
   back. This is documented Apple behaviour, not a bug, and it is a common
   way apps ship with empty name fields.
2. **A user can deactivate a relay alias at any time** from Apple ID
   settings, and mail to it then stops being delivered. **We are never
   told.** Our email simply stops arriving. This section is the only place
   we can set that expectation.
3. **A Google user can change their Google account's primary address.** The
   Supabase-stored `email` goes stale. Sign-in keeps working because the
   identity is keyed on the provider's subject ID, not the email — so
   nothing breaks, the displayed address is just quietly wrong.

### Proposed content

```
Sign-in & security

  Signed in with Apple
  k7xq2p9v4t@privaterelay.appleid.com

  Apple is hiding your real address. Email from ZYRA is
  forwarded to you by Apple, and you can stop that at any
  time in your Apple ID settings.

  ZYRA never stores a password, and cannot change your
  email address — Apple manages both.
```

For Google, the same row with the real address and without the relay
paragraph.

**The distinguishing rule:** show the address always; explain it only when
it is a relay (`@privaterelay.appleid.com`). One row, two meanings, and the
copy should not pretend otherwise.

---

## B3. The thing this section should say and currently doesn't

**There is no account recovery.** No password, no secondary factor, no
recovery address of our own. If someone loses access to their Apple ID or
Google account, their ZYRA account — Guardians, Journeys, paid credits — is
unreachable, and there is nothing support can do that is not also the exact
procedure an attacker would use.

This is the standard cost of OAuth-only sign-in and it is not a reason to
change that decision. But it is the largest single support burden such apps
carry, and Sign-in & security is the honest place to say so once, calmly,
before it is discovered by someone in distress.

**For review:** is one plain sentence here the right treatment, or does
this need a real answer before launch — and if a real answer, what, given
that any recovery channel we build becomes the weakest point in an account
holding a family's private matchmaking history?

---

# Summary

| # | Question | Finding |
|---|---|---|
| A1 | Is identity frozen? | **Intended, and nearly true** — but un-publish + re-run onboarding reopens gender and DOB. Undesigned. Close it. |
| A2 | Name changes | Editable and mostly live — but **unvalidated** on the app's own path, **snapshotted** into notification text, and **unrecorded**. |
| A3 | DOB / gender changes | **Impossible via any client.** Right outcome — but a permanent lock with no correction route sits badly against **Article 16**. Needs a supported route, not an open field. |
| A4 | Mismatch with ID | **No ID verification exists.** Verification and mutability are one decision. |
| B1 | Show the provider | **Already built, and broken** — every current account reads "Your provider". |
| B2 | Show the email | **Yes** — but Apple relay addresses need a sentence of explanation or they read as an error. |
| B3 | Recovery | **None exists.** Say so here, or decide otherwise before launch. |

**Three things I would like challenged:**

- Is closing the un-publish route worth it, or is "un-publish, fix, republish"
  actually the humane correction mechanism we would otherwise have to build
  on purpose?
- Is a name-change log proportionate, or is it surveillance of an ordinary
  act on a platform whose users are already nervous about being seen?
- Should the Apple relay explanation appear at **sign-up** instead — at the
  moment the user chooses Hide My Email and could still choose otherwise —
  rather than in Settings where it only ever explains a past decision?
