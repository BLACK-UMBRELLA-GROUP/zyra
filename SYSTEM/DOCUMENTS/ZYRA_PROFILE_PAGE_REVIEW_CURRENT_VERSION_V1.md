---
id: DOC-ZYRA-0085
type: REPORT
status: CURRENT
feature: BROWSE AND MATCHING
purpose: ZYRA — Profile Page: Holistic Review
links: []
owner: ZYRA chat
---

# ZYRA — Profile Page: Holistic Review

**Version:** V1
**Status:** PARTIALLY IMPLEMENTED — row tap-target correction checked, installed and post-verified locally; Founder acceptance pending; other historical review items unchanged
**Date:** 2026-10-21
**Owner:** Codex under Founder authority
**Original review:** 2026-08-06 · Founder review, 8 points
**Brief:** *"Profile should be where people feel proud of their profile…
'My profile and how other people see me.'"*

> **Current Profile tap-target and chevron correction — Founder direct
> instruction, 21 October 2026 / OA-ZYRA-151/304/305:** Compatibility unlocks
> text, balance, row padding and arrow must open the same existing destination.
> The shared Membership chevron must match the other current Profile arrows.
> The bounded app-wide navigation-row sweep also finds the standalone Unlocks
> Back word outside its arrow's target. The implementation addendum below owns
> this round's measured results; prior deliveries are not reused as its proof.
> This does not finalise the unresolved items in the historical review below.

> **Current protected Profile correction — 2026-10-20 / OA-ZYRA-305:**
> Founder requests the Compatibility unlocks Buy more pill become the same quiet
> chevron used by other Profile rows. The original action key, balance and store
> destination are retained. Long full names are measured against two reserved
> lines beside Switch; only names which cannot fit that space use the wider,
> natural-reading fallback. Font size is not reduced and Switch keeps its own
> touch target. This amends presentation only; no photo, account, unlock or
> membership logic changes. Tests and separate delivery status are in
> `SYSTEM/RESOURCES/REVIEWS/OA305_MY_ZYRA_ACTIVITY_2026_10_20.PrA0zH/`.
> This is not a new phone installation or physical acceptance of the layout.

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
| Edit Photos | ✓ ordered manager built — add, reorder and confirmed removal |
| **Preview Profile** | **built — read-only full-screen owner preview** |
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

**Implementation update — 2026-09-18.** *Preview Profile* is now built as a
read-only full-screen owner preview using the shared Seeker profile viewer.
It presents the owner's name, age, location and ordered moderated photos with
the established photo navigation, exact Browse identity typography, 130px
position and legibility scrim, and contains no Browse decision actions. The
preview dismisses with a downward swipe rather than a close button.
Ordinary accounts restore their own signed photo URLs; the isolated Founder
persona never reads live member rows and uses a clean no-photo state. The
temporary bottom snackbar has been removed.

---

## What I need from you

1. **Profile strength** — agree the weighting favours matching over
   appearance? And what counts?
2. **Profile Views** — leave out?
3. **Unlock counts** — show a count of Unlock+ only, or leave out until the
   disclosure is decided?
4. **Preview Profile** — implemented; Founder visual acceptance remains.

---

## 21 October 2026 — Profile/navigation row tap-target implementation

Authority is the Founder's direct text/arrow consistency and app-update request,
followed by the screenshot instruction to match Seeker One's lighter arrow.
The shared Membership row used foregroundMuted (about54% white in the normal
dark palette), while the current other Profile chevrons used ink(.28). The
shared row now uses the same palette-aware ink(.28), retaining size18,
alignment, text and callback. The icon is decorative beside readable labels.

Protected _UnlockBalance in lib/dev/zyra_one_journey_account_presentation.dart
and ordinary _UnlockBalanceRow in lib/screens/profile/profile_screen.dart now
put title, balance, spacing and trailing chevron inside one InkWell. They
retain their original balance/action keys and exact onBuyMore callbacks.
The ordinary older Buy more outline is retired to the same quiet chevron
already selected by the Founder for Profile. MergeSemantics exposes one
button/action with readable current/unknown/legacy balances; the decorative
chevron has no second focus/tap target. Tooltip wording remains available.
The protected caller's existing account/UI/role/page/tab/control/native-route
freshness guard is unchanged. No direct navigation bypass is added to a row.

The added 320px/200%-text ordinary Profile check also exposed an existing
personal-header overflow: the avatar, name and natural Switch width exceeded
the row. The same name/Switch typography is now measured at the actual text
scale, locale and bold setting. When two name lines cannot fit beside Switch,
the existing Switch moves below the avatar/name row, aligned right. Ordinary
widths retain the existing layout; no font reduction, new copy or account
switch logic is introduced. The immediate no-overflow assertion remains.

The navigation-row source audit covers protected and retained Profile,
Settings/Advanced/privacy destinations, profile editors, Membership, My ZYRA,
requests, Journey options/decisions/archive cards, Guardian management,
workspaces/Circles, code actions and shared action pills. Their inspected
navigation labels already share their row's InkWell/button, except for the
two Profile implementations above and standalone Unlocks Back. The latter
in lib/screens/subscription/upgrade_screen.dart is now one TextButton.icon:
word and arrow share the same one-route return, with mounted/current-route
checks preventing a disposed/covered callback popping a different parent.

Written exclusions: informational status/coverage/profile facts, page titles
beside menus/Close, score/page counters and cards with distinct deliberate
Add/Change/View/destructive actions are not single-destination navigation rows.
No blanket navigation action is added to them; doing so could misroute taps
or trigger an unintended action. No new OA is raised for these intentional
controls. This is a bounded source/hit-target audit, not a claim of a complete
physical phone walk-through or absence of every possible app defect.

Source and document preimages are preserved in
SYSTEM/RESOURCES/REVIEWS/OA305_ROW_TAP_TARGETS_2026_10_21.xAJ1eM.
Its true4,865-input SOURCE_PRE SHA256 is
8ae2786da598333f4c0c52f42aa73155082a81ddfe4be3281f70d497b4889bd8.
The existing contained native recipe is copied with only its exact packet
whitelist adapted; full Xcode/SwiftPM remains held. Fresh qualification passed
1,653 actual app cases across85 disjoint suites,46 separate recipe contracts,
analysis, format and no-Git policy checks.87 focused cases and26 documentation
unit checks passed separately. The final Poppins visual replay reported14
passes and emitted14 PNGs; the single-file reporter has no actual-case count.
Root opened images13/14 only; this is not an all-frame or physical-phone
visual acceptance claim. The failed working focus/visual runs and their
pre-repair evidence remain preserved; they are not counted as passing.

QUALIFICATION_PLAN SHA256 is
edeffd19768cddad0b31b03f04d077dcb2de7aeafea99dd0f48df7dcb454f901;
CHECKED_PREBUILD SHA256 is
ec977a315f74103b5aaa41f29e31ca6e06f565e9d4c522c43f283d41f9ed8093.
Eight existing Source paths changed. The contained current-Dart plus fresh
objective_c/retained-native-host build is HOST_PROFILE.IvKbjt/Runner.app.
Its compiler post-check verifies3,582 regular inputs and one dependency marker;
the4,865 Source inputs and14 recipe modules remain byte-equal to the frozen
plan after building. BUILD SHA256 is
b10e2682f6a7aa66ade5be4c706b1ff03652f6b52bd48f929948af635ffbab78;
artifact SHA256 is
fa106da74c95ed9a5faf534dd91d07a1d034b692d5abce7a7558a20d24d92eb9.

The new exact identity/signature check PASSED. The first fresh lock-state
check recognised the same paired iPhone but found it locked, so delivery
STOPPED before installation. CHECKED_BUILD_AND_DELIVERY_HOLD.json preserves
that snapshot. The Founder then directly replied "Unlocked now". The same
checked candidate passed fresh IDENTITY_2 and LOCK_2, then INSTALL, LAUNCH and
POST in sequence. Installation was12:20:28.996–12:20:40.902UTC on21 October;
post-verification completed12:20:55.427UTC. The exact installed main app's
container is2FE7B17E-1619-442D-9C4D-E363BDE01B3B and native PID30511. Main
identity1.0.0(5), existing signing/team/profile and account data are retained.
No previous delivery is reused as this build's proof.

DELIVERED_AS_BUILT.json binds this new delivery's exact receipts, candidate,
artifact, compiler proof, Source and recipe pins. SOURCE_POST_PHONE SHA256 is
22f60c65c1acd26d087d25732786ae61f7c409ff3931c752741740a68a30dd88;
its4,865 inputs and all14 recipe modules remain byte-equal to the frozen
qualification after delivery. Native process proof is not Founder physical
visual/flow acceptance, which remains pending.

Existing main identity and native delivery gates still apply. The app adds
no developer option, account state,
relationship stage, receipt/payment, credit spending, backend/provider/schema
change, permission grant, migration, signing/trust setup or release/upload.
Prior test-cache deletion authority remains consumed; no new deletion occurs.

OA151/304/305 own this bounded presentation/audit work; OA286 retains native
pipeline limits and OA253/296 retain live billing/permission authority.
Shared-register reconciliation is UNSENT under the existing one-writer hold.
Founder physical visual/flow acceptance is separate; no action is self-closed.
