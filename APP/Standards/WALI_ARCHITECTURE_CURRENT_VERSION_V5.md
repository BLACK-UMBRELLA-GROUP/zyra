FEATURE NAME
ZYRA — Platform Architecture
Document: Wali Architecture

============================================================
WALI ARCHITECTURE
============================================================

Version: V5
Status: CURRENT_VERSION
Last Updated: 2026-07-04

Governing Documents:
  — ZYRA Product Specification V3 (canonical relationship lifecycle)
  — ZYRA Journey Capability Grant Rules V3 (Wali capability model)
  — AD-081 — Capability Independence Principle
  — AD-082 — State Integrity Principle

Change from V4:
  — Extended Wali concept formalised. A Wali holds Extended Wali
    capabilities when AIOS grants them — regardless of whether the
    source is the Seeker's included entitlement or the Wali's own
    £9.99 Extended Wali subscription. Behaviour is identical.
  — Primary Wali concept introduced. Primary is an authority
    designation per Journey, not a subscription tier. Any Extended
    Wali may be designated Primary. Supporting Extended Walis retain
    their capabilities independently.
  — Included Extended Wali entitlement added. A Seeker holding ZYRA
    One includes one Extended Wali entitlement, assignable to any
    one linked Wali. The entitlement belongs to the Seeker's
    subscription, not permanently to one individual.
  — Independent Extended Wali subscription path formalised at
    £9.99/month — purchasable by the Wali directly.
  — Capability Grant Rules section updated to dual-source model.
  — Permissions model updated for Extended Wali framing.
  — ZYRA One for Wali role confirmed: any user may purchase ZYRA
    One; role is chosen at onboarding.
  — Wali account linking limits: flagged for formal review (pending).

Change from V3:
  — Pro Seat model removed. Capability Independence model introduced.
  — Wali Tier Rules → Capability Grant Rules.
  — "Choose Tier: Basic / Pro" removed from Path 3.

Change from V2:
  — Compatibility filtering principle added (engine operates at
    Seeker level only, never at Wali level)
  — Wali Network aligned to Browse architecture

Change from V1:
  — Family Review Period added
  — Subscription model clarified
  — Wali Network introduced

------------------------------------------------------------
DESIGN PRINCIPLE
------------------------------------------------------------

Support and guidance — not surveillance.

The Wali's role is to support, guide and safeguard the
marriage journey. ZYRA treats the Wali as a first-class
user with a full account, dedicated onboarding, and their
own navigation and dashboard.

The Wali experience is not a web portal or add-on.
It is a complete parallel experience within ZYRA.

Neither the Seeker nor the Wali is assumed to start first.
Both onboarding directions are fully supported and
designed as first-class paths.

------------------------------------------------------------
WHO IS A WALI
------------------------------------------------------------

The Wali is a male guardian who supports a Seeker through
their marriage journey in accordance with Islamic guidance.

Eligible Wali relationships include:
  — Father
  — Grandfather
  — Brother
  — Paternal Uncle
  — Other eligible male guardian per Islamic guidance

Exceptional cases (Seeker has no available Wali) are
governed separately under ZYRA's Islamic Governance
documentation. The core onboarding flow assumes a Wali
is available. Edge cases do not live inside onboarding.

------------------------------------------------------------
WALI ACCOUNT TYPE
------------------------------------------------------------

ZYRA has two primary account types at sign-up:
  — Seeker
  — Wali

The Wali account is entirely separate from a Seeker account.
A person cannot be both a Seeker and a Wali on the same
account.

Wali accounts carry identity only.

A Wali account has no capability tier. Capabilities are
not stored on the Wali account or derived from it.
For each Journey relationship, AIOS resolves the Wali's
capabilities based on the applicable entitlement source.
That source may be: the Wali's own account entitlement, or
an included entitlement granted by a linked Seeker's ZYRA One.

A Wali linked to multiple Seekers may simultaneously hold
different capability grants for different Journey relationships.
This is the correct and expected behaviour, not a conflict.

See: ZYRA Journey Capability Grant Rules V3
See: AD-081 — Capability Independence Principle

------------------------------------------------------------
THREE ENTRY PATHS
------------------------------------------------------------

PATH 1 — Seeker Invites Wali (Wali receives included entitlement)

  The Seeker (on ZYRA One) completes onboarding and invites
  their Wali. The Seeker assigns their included Extended Wali
  entitlement to this Wali.

  The Wali creates a Wali account (or is auto-linked if they
  already have one). AIOS grants Extended Wali capabilities
  immediately — no payment required from the Wali.

  If the Seeker is on ZYRA Basic:
    The Wali receives standard Wali capabilities only.
    No included entitlement exists on ZYRA Basic.

PATH 2A — Wali Purchases Extended Wali Independently

  A Wali may independently purchase the Extended Wali
  subscription (£9.99/month) without the Seeker holding
  ZYRA One.

  When the Wali holds this subscription, AIOS grants Extended
  Wali capabilities across all their Journey relationships.
  No Seeker action is required.

  The capability behaviour is identical to receiving the
  included entitlement. Capability source is irrelevant
  once AIOS has granted the capability. (AD-081)

PATH 2B — Wali Purchases ZYRA One

  Any user may purchase ZYRA One (£34.99/month). During
  onboarding they choose their role: Seeker or Wali.

  A Wali who purchases ZYRA One holds the full account
  entitlement. AIOS resolves Extended Wali capabilities
  for all their Journey relationships.

PATH 3 — Wali Starts First

  A parent or guardian organises everything before the Seeker
  joins. This reflects how many Muslim families naturally
  operate and is a first-class path.

  1. Wali creates a Wali account.
  2. Wali completes Wali onboarding.
  3. Wali may optionally purchase Extended Wali at this stage.
  4. Wali generates an invitation for their Seeker.
  5. Seeker joins using that invitation link.
  6. Both accounts are automatically linked.
  7. If the Seeker holds ZYRA One, they may assign their
     included entitlement to this Wali (if not already using
     it for another Wali).

  No tier selection occurs during Wali account creation.
  Capability is not a property of the Wali account identity.

------------------------------------------------------------
LINKING — HOW ACCOUNTS CONNECT
------------------------------------------------------------

Whether the Seeker starts or the Wali starts, the end
result is the same linked state.

Accounts are linked using secure identity verification:
  — Verified email
  — Verified mobile number
  — Internal invitation token (generated per invite)

Users never manually search for each other.
The invitation token ensures the correct accounts
are linked automatically on account creation or sign-in.

------------------------------------------------------------
EXTENDED WALI
------------------------------------------------------------

An Extended Wali is a Wali who holds Extended Wali capabilities,
granted by AIOS. The Extended Wali designation describes a
capability state, not an account type or identity.

A Wali becomes an Extended Wali when AIOS grants the extended
capability set. There are two entitlement paths through which
this may happen:

  PATH A — Included entitlement from Seeker's ZYRA One
    The linked Seeker holds ZYRA One and assigns their one
    included Extended Wali entitlement to this Wali.
    No cost to the Wali.

  PATH B — Independent Extended Wali subscription
    The Wali purchases the Extended Wali subscription
    directly (£9.99/month).

The capability source is irrelevant. Once AIOS grants the
Extended Wali capability set, behaviour is identical regardless
of which path applied. (AD-081 — Capability Independence)

STANDARD WALI CAPABILITIES (all Walis)

  — View Seeker's active Journey progress
  — View messages between Seeker and their match
  — View Timeline
  — Receive notifications at each Family Review Period
  — Choose Continue or Pause during the Family Review Period
  — Raise a concern or flag to ZYRA support
  — Receive safety alerts

EXTENDED WALI CAPABILITIES (AIOS-granted, in addition to above)

  — Browse Seeker profile cards in the Wali Network
  — Send and receive Family Introduction Requests
  — Suggest profiles to their linked Seeker
  — View and deliver Wali AI Summary

------------------------------------------------------------
PRIMARY WALI
------------------------------------------------------------

Primary Wali is an authority designation, not a subscription
tier. Any linked Extended Wali may be designated as Primary
for a Journey.

PRIMARY IS:
  — The official representative for one specific Journey
  — The Wali with authority to make official Continue / Pause
    decisions during the Family Review Period
  — The contact for external communication during that Journey
  — The Wali who performs official Family Introduction actions
  — The official Journey representative

PRIMARY IS NOT:
  — A subscription tier
  — A permanent designation — authority may change
  — A capability modifier — supporting Extended Walis retain
    all their Extended Wali capabilities independently

CHANGING PRIMARY

  The Seeker may reassign the Primary designation to any other
  linked Extended Wali at any time. When Primary changes:
  — Authority transfers to the new Primary immediately
  — No subscription changes occur
  — The previous Primary retains their Extended Wali capabilities
    if their entitlement source remains active

  The Seeker's included entitlement is separate from the Primary
  designation. The included entitlement may remain with the
  previous Primary (who retains Extended Wali capabilities)
  while a new Primary is added via their own £9.99 subscription.
  OR the included entitlement may be reassigned to the new Primary.
  Both configurations are valid.

EXAMPLE — PRIMARY CHANGE

  Shakeel (ZYRA One Seeker)
  Included entitlement assigned to: Dad

  Dad: Extended Wali (via included entitlement) — Primary
  Mum: Standard Wali

  Mum becomes Primary:

  Option A — Included entitlement stays with Dad
    Dad: Extended Wali (via included entitlement) — Supporting
    Mum: Extended Wali (via £9.99 own subscription) — Primary

  Option B — Included entitlement reassigned to Mum
    Dad: Standard Wali — Supporting
    Mum: Extended Wali (via included entitlement) — Primary

------------------------------------------------------------
CAPABILITY GRANT RULES
------------------------------------------------------------

A Wali's capabilities are granted by AIOS based on the
applicable entitlement. See: ZYRA Journey Capability Grant
Rules V3 for the authoritative specification.

ENTITLEMENT EXAMPLE — MULTIPLE SEEKERS

  Wali Ahmed holds an Extended Wali subscription (£9.99/month).

  Ahmed is linked to:
    Daughter → AIOS grants Extended Wali capabilities
    Son      → AIOS grants Extended Wali capabilities

  Ahmed's own entitlement applies across all his Journey
  relationships. Each Seeker's own entitlement determines their
  Seeker capabilities independently.

  If Ahmed cancels his Extended Wali subscription:
  AIOS revokes extended Wali capabilities across all his
  Journey relationships, unless he also receives an included
  entitlement from a linked Seeker's ZYRA One.

CAPABILITY CHANGES

  Extended Wali capabilities are granted or revoked as soon
  as the underlying entitlement changes.

  No manual action is required by either the Seeker or the Wali.

WALI ACCOUNT LINKING LIMITS

  Linking limits for Wali accounts are under review.
  A revised policy will be specified in a future update.

------------------------------------------------------------
WALI PERMISSIONS MODEL
------------------------------------------------------------

The following table shows what each Wali can see and do,
differentiated by whether the Wali holds Extended Wali capabilities.

                          | Standard Wali     | Extended Wali   |
--------------------------|-------------------|-----------------|
View Journey progress     |        ✓          |       ✓         |
View messages             |        ✓          |       ✓         |
View Timeline             |        ✓          |       ✓         |
Receive Family Review     |        ✓          |       ✓         |
  Period notifications    |                   |                 |
Continue / Pause at       |        ✓          |       ✓         |
  Family Review Period    |                   |                 |
Raise concern / flag      |        ✓          |       ✓         |
Receive safety alerts     |        ✓          |       ✓         |
Wali Network access       |        ✗          |       ✓         |
Family Introductions      |        ✗          |       ✓         |
Suggest profiles          |        ✗          |       ✓         |
Wali AI Summary           |        ✗          |       ✓         |

WHAT THE WALI CAN NEVER SEE (regardless of Seeker's subscription)

  — Chapter 3 (Values) answers
  — Chapter 4 (Preferences / compatibility settings)
    Compatibility settings remain private to Seeker only.
  — Match list / Browse activity

THE WALI DOES NOT:
  — See Chapter 3 or Chapter 4 answers
  — Control who the Seeker browses or expresses interest in
  — Accept on behalf of the Seeker — Seeker consent is always
    required before an Active Journey begins

------------------------------------------------------------
WALI RESPONSIBILITIES
------------------------------------------------------------

  ✓ Viewing the progress of each Journey
  ✓ Viewing messages between Seeker and their match
  ✓ Receiving notifications at each Family Review Period
  ✓ Choosing to Continue or Pause during the Review Period
  ✓ Participating in family introductions (when Seeker holds
    ZYRA One — AIOS-granted capability)
  ✓ Joining conversations when appropriate
  ✓ Receiving safety notifications when necessary
  ✓ Helping ensure the process remains respectful
    and family-oriented

------------------------------------------------------------
FAMILY REVIEW PERIOD
------------------------------------------------------------

After both Seekers complete a Journey stage, the next stage
does not unlock immediately.

Instead, the Journey enters a 48-hour Family Review Period.

WHAT HAPPENS DURING THE REVIEW PERIOD

  1. Both Walis receive a notification to review the
     completed stage.

  2. Each Wali may:
       ✅ Continue  — explicitly confirms readiness
       ❌ Pause     — halts progression until resolved

  3. If neither Wali raises a concern within 48 hours:
       → The Journey automatically continues.

PURPOSE

  The Family Review Period is not a permission gate.
  It is a deliberate pause that:

  — Encourages family awareness at each stage
  — Gives Walis meaningful involvement without veto power
    over every micro-decision
  — Prevents a Journey from moving too fast

  Silence is treated as:
  "The family had the opportunity to review this stage."
  It is not an explicit approval.

PAUSE BEHAVIOUR

  If a Wali selects Pause:
  — The Journey pauses immediately.
  — The matched Seekers are notified that the Journey
    has been paused for family review.
  — ZYRA support is available to assist if the pause
    cannot be resolved between both families.

  Pause does not mean rejection.
  It means the family needs more time.

  Note: "Pause Journey" as used here refers to the Wali's
  action within the Family Review Period. This is distinct
  from the "Pause Journey" feature available to ZYRA One
  Seekers (which pauses the Active Journey entirely).
  Both use the same term in their respective contexts.

------------------------------------------------------------
WALI SCREEN FLOW
------------------------------------------------------------

Path 1 — Seeker invites Wali:
  [ Invite Your Wali ] → ZYRA sends SMS/email
  → [ Wali Invitation Landing ] → [ Create Account ]
  → [ Wali Onboarding ] → [ Wali Dashboard ]

Path 2 — Seeker (on ZYRA One) invites Wali:
  [ Invite Your Wali ] → ZYRA sends SMS/email
  → [ Wali Invitation Landing ] → [ Create / Sign In ]
  → [ Wali Onboarding ] → [ Wali Dashboard ]
  (Extended capabilities are AIOS-granted automatically
   — no activation step required from the Wali)

Path 3 — Wali starts first:
  [ Wali Sign Up ] → [ Wali Onboarding ]
  → [ Wali Dashboard ] → [ Invite Seeker ]
  → Seeker receives SMS/email
  → [ Seeker Invitation Landing ] → Seeker onboarding
  → Accounts linked
  (Wali capabilities determined by Seeker's subscription
   — resolved automatically by AIOS on link)

------------------------------------------------------------
CONNECTIONS SECTIONS
------------------------------------------------------------

The Connections area is structured as follows:

  — Declined
  — Review
  — Family Introductions
  — Likes
  — Matches

Family Introductions is a dedicated section.
It is not merged into Review.
Consolidation can be considered once the full app
is designed and usage patterns are understood.

------------------------------------------------------------
WALI NAVIGATION
------------------------------------------------------------

Wali accounts use a fixed 4-tab navigation:
  Dashboard · Seekers · Network · Profile

  — No Universal Toggle (Seeker-only mechanic)
  — All tabs equal size, all icons 18px
  — Floating glass pill: same design as Seeker nav

Network tab:
  — Accessible when the Wali holds Extended Wali capabilities
    (via included entitlement OR own subscription)
  — A Standard Wali tapping Network → sees an explanation
    that Network access requires Extended Wali capabilities

------------------------------------------------------------
WALI NETWORK — ARCHITECTURE
------------------------------------------------------------

Status: Approved
Last Updated: 2026-07-04

WHAT THE WALI NETWORK IS

The Wali Network is not a second Browse page.
It is a family introduction facilitation layer,
visible only to Walis who hold Extended Wali capabilities
(granted by AIOS via included entitlement or own subscription).

WHAT IS DISPLAYED

The cards shown in the Network are Seeker profile cards.
The Wali is browsing on behalf of their linked Seeker.

The Wali cannot edit or customise what is shown.
Cards are 100% system-controlled.

No free-text introductions.
No biographies.
No manually added information.

Reason:
Free text creates a privacy loophole. A Wali could
reveal information that ZYRA intentionally hides
through progressive disclosure, including:
  — Occupation
  — Education
  — Religious practice
  — Previous marriage history
  — Compatibility answers

Only ZYRA determines what is displayed on each card.

CARD CONTENTS (system-controlled)

  — Seeker initial (e.g. K.)
  — Age
  — City
  — Wali relationship ("Guided by his father")
  — Verified Wali badge

SEEKER CONSENT

Because the Network uses the Seeker's profile card,
explicit consent is required.

When a Seeker links a Wali, they agree to Terms &
Conditions explaining:
  — What their linked Wali can view
  — What information is displayed to other verified Walis
    in the Network
  — That their profile card becomes visible in the Network
    if their subscription grants Wali Network capabilities

Consent is collected during the Wali linking flow.

WALI NETWORK FLOW

1. Wali A discovers Seeker B's system-controlled card
   in the Network Discover feed.

2. Wali A sends a Family Introduction Request to Wali B.

3. Wali B reviews Seeker A's system-controlled card.

4. Wali B accepts or declines.

5. If both Walis agree:
   The introduction is presented to both Seekers
   independently.

6. Each Seeker independently accepts or declines.

7. If both Seekers accept:
   The standard ZYRA Journey begins (Potential Journey
   created; Ritual required to create Active Journey).

Key principle:
Walis agree that an introduction is worth presenting.
They do not accept on behalf of Seekers.
Seeker consent is always required before an Active
Journey begins.

INTRODUCTION LOGIC — MULTIPLE SEEKERS

When a Wali taps Introduce from a Seeker card:

  If the Wali has one eligible Seeker (gender-matched):
    → Automatically sends the introduction on their behalf.
    → No selection prompt.
    → "This introduction will be sent on behalf of [Name]."

  If the Wali has two or more eligible Seekers:
    → A selection screen appears.
    → The Wali selects which Seeker this introduction is for.
    → Maximum one per introduction request.

  Gender matching is automatic.

NETWORK TABS

  Discover  — Wali browses system-controlled Seeker cards
  Requests  — Incoming Family Introduction Requests

------------------------------------------------------------
WALI NETWORK — COMPATIBILITY FILTERING PRINCIPLE
------------------------------------------------------------

RULE: The compatibility engine operates at the Seeker level.
It never operates at the Wali level.

Each Seeker linked to a Wali is evaluated independently
for compatibility, hard requirements, and visibility.
A Seeker's profile never affects another Seeker's visibility
simply because they share the same Wali.

EXAMPLE

  Wali Ahmed is linked to:
    Son A — smokes
    Son B — does not smoke

  Another Seeker has a Hard Requirement:
    🚫 Never show anyone who smokes.

  Incorrect (Wali-level filtering):
    Wali Ahmed disappears from the Network entirely
    because Son A does not satisfy the requirement.

  Correct (Seeker-level filtering):
    Son A → ❌ Fails Hard Requirement → Not shown.
    Son B → ✅ Passes Hard Requirement → Shown.
    Wali Ahmed remains visible in the Network,
    showing only Son B's card.

CONSEQUENCES

  — A Wali with multiple Seekers may have different numbers
    of Seeker rows visible to different Network viewers.

  — A Wali card may show 2 Seekers to one viewer and
    1 Seeker to another, depending on compatibility.

  — If none of a Wali's linked Seekers pass compatibility,
    the Wali card does not appear at all for that viewer.

  — Each Seeker card in the Network has independent:
      · Compatibility filtering
      · Hard Requirement filtering
      · Visibility
      · Family Introduction requests

ALIGNMENT WITH BROWSE

  The Wali Network uses the same compatibility engine,
  hard requirement rules, and visibility logic as Browse.

  The only architectural difference between Browse and
  the Wali Network is who initiates the introduction:

    Browse:        Seeker initiates.
    Wali Network:  Wali initiates on behalf of their Seeker.

  The underlying engine is identical.

------------------------------------------------------------
EXCEPTIONAL CASES (DEFERRED)
------------------------------------------------------------

The following scenarios are not handled in core onboarding.
Deferred to ZYRA's Islamic Governance document:

  — Seeker has no living male guardian
  — Seeker is a revert with no Muslim male family member
  — Dispute over who has Wali authority
  — Wali becomes unavailable mid-journey
  — Female guardian acting in Wali capacity in exceptional
    circumstances

------------------------------------------------------------
PENDING ITEMS
------------------------------------------------------------

The following items require formal resolution:

  WALI ACCOUNT LINKING LIMITS
  No artificial cap is currently imposed. A formal linking
  policy must be specified before production.
  Outstanding item: Wali Account Linking Limits V1.

  INCLUDED ENTITLEMENT REASSIGNMENT RULES
  The exact rules for when and how the included entitlement
  may be reassigned (e.g. cooldown, frequency limits) are
  pending formal specification.

  FAMILY STAGE — WALI PARTICIPATION RULES
  Detailed Wali conversation permissions during the Family
  Stage are deferred to the Family Stage specification.

  WALI ↔ WALI COMMUNICATION
  Private Wali-to-Wali communication rules depend on the
  Family Stage specification.

