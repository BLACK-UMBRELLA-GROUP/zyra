FEATURE NAME
ZYRA — Platform Architecture
Document: Guardian Architecture

============================================================
GUARDIAN ARCHITECTURE
============================================================

Version: V6
Status: CURRENT_VERSION
Last Updated: 2026-07-26

Governing Documents:
  — ZYRA Product Specification V5 (canonical relationship lifecycle)
  — ZYRA Journey Capability Grant Rules V3 (Guardian capability model)
  — AD-081 — Capability Independence Principle
  — AD-082 — State Integrity Principle

Change from V5:
  — Terminology only. Founder decision (2026-07-26): "Extended Guardian"
    renamed to Guardian+ throughout this document, matching the
    existing "ZYRA One" naming pattern (Seeker: ZYRA Basic/ZYRA One;
    Guardian: Guardian Basic/Guardian+). No capability, resolution rule,
    pricing, or architectural content changed — every occurrence
    below is the same concept under its new name. Previous version
    archived as WALI_ARCHITECTURE_2026-07-26_V5.md.

Change from V4:
  — Guardian+ concept formalised. A Guardian holds Guardian+
    capabilities when AIOS grants them — regardless of whether the
    source is the Seeker's included entitlement or the Guardian's own
    £9.99 Guardian+ subscription. Behaviour is identical.
  — Primary Guardian concept introduced. Primary is an authority
    designation per Journey, not a subscription tier. Any Guardian+
    may be designated Primary. Supporting Guardian+ holders retain
    their capabilities independently.
  — Included Guardian+ entitlement added. A Seeker holding ZYRA
    One includes one Guardian+ entitlement, assignable to any
    one linked Guardian. The entitlement belongs to the Seeker's
    subscription, not permanently to one individual.
  — Independent Guardian+ subscription path formalised at
    £9.99/month — purchasable by the Guardian directly.
  — Capability Grant Rules section updated to dual-source model.
  — Permissions model updated for Guardian+ framing.
  — ZYRA One for Guardian role confirmed: any user may purchase ZYRA
    One; role is chosen at onboarding.
  — Guardian account linking limits: flagged for formal review (pending).

Change from V3:
  — Pro Seat model removed. Capability Independence model introduced.
  — Guardian Tier Rules → Capability Grant Rules.
  — "Choose Tier: Basic / Pro" removed from Path 3.

Change from V2:
  — Compatibility filtering principle added (engine operates at
    Seeker level only, never at Guardian level)
  — Guardian Network aligned to Browse architecture

Change from V1:
  — Family Review Period added
  — Subscription model clarified
  — Guardian Network introduced

------------------------------------------------------------
DESIGN PRINCIPLE
------------------------------------------------------------

Support and guidance — not surveillance.

The Guardian's role is to support, guide and safeguard the
marriage journey. ZYRA treats the Guardian as a first-class
user with a full account, dedicated onboarding, and their
own navigation and dashboard.

The Guardian experience is not a web portal or add-on.
It is a complete parallel experience within ZYRA.

Neither the Seeker nor the Guardian is assumed to start first.
Both onboarding directions are fully supported and
designed as first-class paths.

------------------------------------------------------------
WHO IS A GUARDIAN
------------------------------------------------------------

The Guardian is a male guardian who supports a Seeker through
their marriage journey in accordance with Islamic guidance.

Eligible Guardian relationships include:
  — Father
  — Grandfather
  — Brother
  — Paternal Uncle
  — Other eligible male guardian per Islamic guidance

Exceptional cases (Seeker has no available Guardian) are
governed separately under ZYRA's Islamic Governance
documentation. The core onboarding flow assumes a Guardian
is available. Edge cases do not live inside onboarding.

------------------------------------------------------------
GUARDIAN ACCOUNT TYPE
------------------------------------------------------------

ZYRA has two primary account types at sign-up:
  — Seeker
  — Guardian

The Guardian account is entirely separate from a Seeker account.
A person cannot be both a Seeker and a Guardian on the same
account.

Guardian accounts carry identity only.

A Guardian account has no capability tier. Capabilities are
not stored on the Guardian account or derived from it.
For each Journey relationship, AIOS resolves the Guardian's
capabilities based on the applicable entitlement source.
That source may be: the Guardian's own account entitlement, or
an included entitlement granted by a linked Seeker's ZYRA One.

A Guardian linked to multiple Seekers may simultaneously hold
different capability grants for different Journey relationships.
This is the correct and expected behaviour, not a conflict.

See: ZYRA Journey Capability Grant Rules V3
See: AD-081 — Capability Independence Principle

------------------------------------------------------------
THREE ENTRY PATHS
------------------------------------------------------------

PATH 1 — Seeker Invites Guardian (Guardian receives included entitlement)

  The Seeker (on ZYRA One) completes onboarding and invites
  their Guardian. The Seeker assigns their included Guardian+
  entitlement to this Guardian.

  The Guardian creates a Guardian account (or is auto-linked if they
  already have one). AIOS grants Guardian+ capabilities
  immediately — no payment required from the Guardian.

  If the Seeker is on ZYRA Basic:
    The Guardian receives standard Guardian capabilities only.
    No included entitlement exists on ZYRA Basic.

PATH 2A — Guardian Purchases Guardian+ Independently

  A Guardian may independently purchase the Guardian+
  subscription (£9.99/month) without the Seeker holding
  ZYRA One.

  When the Guardian holds this subscription, AIOS grants Guardian+
  capabilities across all their Journey relationships.
  No Seeker action is required.

  The capability behaviour is identical to receiving the
  included entitlement. Capability source is irrelevant
  once AIOS has granted the capability. (AD-081)

PATH 2B — Guardian Purchases ZYRA One

  Any user may purchase ZYRA One (£34.99/month). During
  onboarding they choose their role: Seeker or Guardian.

  A Guardian who purchases ZYRA One holds the full account
  entitlement. AIOS resolves Guardian+ capabilities
  for all their Journey relationships.

PATH 3 — Guardian Starts First

  A parent or guardian organises everything before the Seeker
  joins. This reflects how many Muslim families naturally
  operate and is a first-class path.

  1. Guardian creates a Guardian account.
  2. Guardian completes Guardian onboarding.
  3. Guardian may optionally purchase Guardian+ at this stage.
  4. Guardian generates an invitation for their Seeker.
  5. Seeker joins using that invitation link.
  6. Both accounts are automatically linked.
  7. If the Seeker holds ZYRA One, they may assign their
     included entitlement to this Guardian (if not already using
     it for another Guardian).

  No tier selection occurs during Guardian account creation.
  Capability is not a property of the Guardian account identity.

------------------------------------------------------------
LINKING — HOW ACCOUNTS CONNECT
------------------------------------------------------------

Whether the Seeker starts or the Guardian starts, the end
result is the same linked state.

Accounts are linked using secure identity verification:
  — Verified email
  — Verified mobile number
  — Internal invitation token (generated per invite)

Users never manually search for each other.
The invitation token ensures the correct accounts
are linked automatically on account creation or sign-in.

------------------------------------------------------------
GUARDIAN ONE
------------------------------------------------------------

A Guardian+ is a Guardian who holds Guardian+ capabilities,
granted by AIOS. The Guardian+ designation describes a
capability state, not an account type or identity.

A Guardian becomes a Guardian+ when AIOS grants the Guardian+
capability set. There are two entitlement paths through which
this may happen:

  PATH A — Included entitlement from Seeker's ZYRA One
    The linked Seeker holds ZYRA One and assigns their one
    included Guardian+ entitlement to this Guardian.
    No cost to the Guardian.

  PATH B — Independent Guardian+ subscription
    The Guardian purchases the Guardian+ subscription
    directly (£9.99/month).

The capability source is irrelevant. Once AIOS grants the
Guardian+ capability set, behaviour is identical regardless
of which path applied. (AD-081 — Capability Independence)

STANDARD GUARDIAN CAPABILITIES (all Guardians)

  — View Seeker's active Journey progress
  — View messages between Seeker and their match
  — View Timeline
  — Receive notifications at each Family Review Period
  — Choose Continue or Pause during the Family Review Period
  — Raise a concern or flag to ZYRA support
  — Receive safety alerts

GUARDIAN ONE CAPABILITIES (AIOS-granted, in addition to above)

  — Browse Seeker profile cards in the Guardian Network
  — Send and receive Family Introduction Requests
  — Suggest profiles to their linked Seeker
  — View and deliver Guardian AI Summary

------------------------------------------------------------
PRIMARY GUARDIAN
------------------------------------------------------------

Primary Guardian is an authority designation, not a subscription
tier. Any linked Guardian+ may be designated as Primary
for a Journey.

PRIMARY IS:
  — The official representative for one specific Journey
  — The Guardian with authority to make official Continue / Pause
    decisions during the Family Review Period
  — The contact for external communication during that Journey
  — The Guardian who performs official Family Introduction actions
  — The official Journey representative

PRIMARY IS NOT:
  — A subscription tier
  — A permanent designation — authority may change
  — A capability modifier — supporting Guardian+ holders retain
    all their Guardian+ capabilities independently

CHANGING PRIMARY

  The Seeker may reassign the Primary designation to any other
  linked Guardian+ at any time. When Primary changes:
  — Authority transfers to the new Primary immediately
  — No subscription changes occur
  — The previous Primary retains their Guardian+ capabilities
    if their entitlement source remains active

  The Seeker's included entitlement is separate from the Primary
  designation. The included entitlement may remain with the
  previous Primary (who retains Guardian+ capabilities)
  while a new Primary is added via their own £9.99 subscription.
  OR the included entitlement may be reassigned to the new Primary.
  Both configurations are valid.

EXAMPLE — PRIMARY CHANGE

  Shakeel (ZYRA One Seeker)
  Included entitlement assigned to: Dad

  Dad: Guardian+ (via included entitlement) — Primary
  Mum: Standard Guardian

  Mum becomes Primary:

  Option A — Included entitlement stays with Dad
    Dad: Guardian+ (via included entitlement) — Supporting
    Mum: Guardian+ (via £9.99 own subscription) — Primary

  Option B — Included entitlement reassigned to Mum
    Dad: Standard Guardian — Supporting
    Mum: Guardian+ (via included entitlement) — Primary

------------------------------------------------------------
CAPABILITY GRANT RULES
------------------------------------------------------------

A Guardian's capabilities are granted by AIOS based on the
applicable entitlement. See: ZYRA Journey Capability Grant
Rules V3 for the authoritative specification.

ENTITLEMENT EXAMPLE — MULTIPLE SEEKERS

  Guardian Ahmed holds a Guardian+ subscription (£9.99/month).

  Ahmed is linked to:
    Daughter → AIOS grants Guardian+ capabilities
    Son      → AIOS grants Guardian+ capabilities

  Ahmed's own entitlement applies across all his Journey
  relationships. Each Seeker's own entitlement determines their
  Seeker capabilities independently.

  If Ahmed cancels his Guardian+ subscription:
  AIOS revokes Guardian+ capabilities across all his
  Journey relationships, unless he also receives an included
  entitlement from a linked Seeker's ZYRA One.

CAPABILITY CHANGES

  Guardian+ capabilities are granted or revoked as soon
  as the underlying entitlement changes.

  No manual action is required by either the Seeker or the Guardian.

GUARDIAN ACCOUNT LINKING LIMITS

  Linking limits for Guardian accounts are under review.
  A revised policy will be specified in a future update.

------------------------------------------------------------
GUARDIAN PERMISSIONS MODEL
------------------------------------------------------------

The following table shows what each Guardian can see and do,
differentiated by whether the Guardian holds Guardian+ capabilities.

                          | Standard Guardian     | Guardian+   |
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
Guardian Network access       |        ✗          |       ✓         |
Family Introductions      |        ✗          |       ✓         |
Suggest profiles          |        ✗          |       ✓         |
Guardian AI Summary           |        ✗          |       ✓         |

WHAT THE GUARDIAN CAN NEVER SEE (regardless of Seeker's subscription)

  — Chapter 3 (Values) answers
  — Chapter 4 (Preferences / compatibility settings)
    Compatibility settings remain private to Seeker only.
  — Match list / Browse activity

THE GUARDIAN DOES NOT:
  — See Chapter 3 or Chapter 4 answers
  — Control who the Seeker browses or expresses interest in
  — Accept on behalf of the Seeker — Seeker consent is always
    required before an Active Journey begins

------------------------------------------------------------
GUARDIAN RESPONSIBILITIES
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

BUILT 2026-07-26 (#31, DR-ZYRA-110): real for the 4 transitions
journey_flow_screen.dart treats as "both Seekers complete a
stage" (Phase 1->2, 2->3, 3->Family Stage, Family Stage->
Conversation) — see 20260726190000_family_review_period.sql
and DR-ZYRA-110 for exact v1 scope (main-Guardian-only
participation; a Pause is resolved by an explicit Reopen
action rather than an auto-resolution mechanic, since this
section doesn't specify one; per-Family-Review-Period Bell
notifications are a flagged follow-up, not yet built — the
Guardian sees live review state the moment they open their
Journey detail screen instead).

After both Seekers complete a Journey stage, the next stage
does not unlock immediately.

Instead, the Journey enters a 48-hour Family Review Period.

WHAT HAPPENS DURING THE REVIEW PERIOD

  1. Both Guardians receive a notification to review the
     completed stage.

  2. Each Guardian may:
       ✅ Continue  — explicitly confirms readiness
       ❌ Pause     — halts progression until resolved

  3. If neither Guardian raises a concern within 48 hours:
       → The Journey automatically continues.

PURPOSE

  The Family Review Period is not a permission gate.
  It is a deliberate pause that:

  — Encourages family awareness at each stage
  — Gives Guardians meaningful involvement without veto power
    over every micro-decision
  — Prevents a Journey from moving too fast

  Silence is treated as:
  "The family had the opportunity to review this stage."
  It is not an explicit approval.

PAUSE BEHAVIOUR

  If a Guardian selects Pause:
  — The Journey pauses immediately.
  — The matched Seekers are notified that the Journey
    has been paused for family review.
  — ZYRA support is available to assist if the pause
    cannot be resolved between both families.

  Pause does not mean rejection.
  It means the family needs more time.

  Note: "Pause Journey" as used here refers to the Guardian's
  action within the Family Review Period. This is distinct
  from the Seeker-side "Pause Journey" feature (both plans,
  capped 5/10 since DR-ZYRA-138, 2026-08-11 — errata 2026-08-12 stewardship pass),
  which pauses the Active Journey entirely.
  Both use the same term in their respective contexts.

------------------------------------------------------------
GUARDIAN SCREEN FLOW
------------------------------------------------------------

Path 1 — Seeker invites Guardian:
  [ Invite Your Guardian ] → ZYRA sends SMS/email
  → [ Guardian Invitation Landing ] → [ Create Account ]
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]

Path 2 — Seeker (on ZYRA One) invites Guardian:
  [ Invite Your Guardian ] → ZYRA sends SMS/email
  → [ Guardian Invitation Landing ] → [ Create / Sign In ]
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]
  (Guardian+ capabilities are AIOS-granted automatically
   — no activation step required from the Guardian)

Path 3 — Guardian starts first:
  [ Guardian Sign Up ] → [ Guardian Onboarding ]
  → [ Guardian Dashboard ] → [ Invite Seeker ]
  → Seeker receives SMS/email
  → [ Seeker Invitation Landing ] → Seeker onboarding
  → Accounts linked
  (Guardian capabilities determined by Seeker's subscription
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
GUARDIAN NAVIGATION
------------------------------------------------------------

Guardian accounts use a fixed 4-tab navigation:
  Dashboard · Seekers · Network · Profile

  — No Universal Toggle (Seeker-only mechanic)
  — All tabs equal size, all icons 18px
  — Floating glass pill: same design as Seeker nav

Network tab:
  — Accessible when the Guardian holds Guardian+ capabilities
    (via included entitlement OR own subscription)
  — A Standard Guardian tapping Network → sees an explanation
    that Network access requires Guardian+ capabilities

------------------------------------------------------------
GUARDIAN NETWORK — ARCHITECTURE
------------------------------------------------------------

Status: Approved
Last Updated: 2026-07-04

WHAT THE GUARDIAN NETWORK IS

The Guardian Network is not a second Browse page.
It is a family introduction facilitation layer,
visible only to Guardians who hold Guardian+ capabilities
(granted by AIOS via included entitlement or own subscription).

WHAT IS DISPLAYED

The cards shown in the Network are Seeker profile cards.
The Guardian is browsing on behalf of their linked Seeker.

The Guardian cannot edit or customise what is shown.
Cards are 100% system-controlled.

No free-text introductions.
No biographies.
No manually added information.

Reason:
Free text creates a privacy loophole. A Guardian could
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
  — Guardian relationship ("Guided by his father")
  — Verified Guardian badge

SEEKER CONSENT

Because the Network uses the Seeker's profile card,
explicit consent is required.

When a Seeker links a Guardian, they agree to Terms &
Conditions explaining:
  — What their linked Guardian can view
  — What information is displayed to other verified Guardians
    in the Network
  — That their profile card becomes visible in the Network
    if their subscription grants Guardian Network capabilities

Consent is collected during the Guardian linking flow.

GUARDIAN NETWORK FLOW

1. Guardian A discovers Seeker B's system-controlled card
   in the Network Discover feed.

2. Guardian A sends a Family Introduction Request to Guardian B.

3. Guardian B reviews Seeker A's system-controlled card.

4. Guardian B accepts or declines.

5. If both Guardians agree:
   The introduction is presented to both Seekers
   independently.

6. Each Seeker independently accepts or declines.

7. If both Seekers accept:
   The standard ZYRA Journey begins (Potential Journey
   created; Ritual required to create Active Journey).

Key principle:
Guardians agree that an introduction is worth presenting.
They do not accept on behalf of Seekers.
Seeker consent is always required before an Active
Journey begins.

INTRODUCTION LOGIC — MULTIPLE SEEKERS

When a Guardian taps Introduce from a Seeker card:

  If the Guardian has one eligible Seeker (gender-matched):
    → Automatically sends the introduction on their behalf.
    → No selection prompt.
    → "This introduction will be sent on behalf of [Name]."

  If the Guardian has two or more eligible Seekers:
    → A selection screen appears.
    → The Guardian selects which Seeker this introduction is for.
    → Maximum one per introduction request.

  Gender matching is automatic.

NETWORK TABS

  Discover  — Guardian browses system-controlled Seeker cards
  Requests  — Incoming Family Introduction Requests

------------------------------------------------------------
GUARDIAN NETWORK — COMPATIBILITY FILTERING PRINCIPLE
------------------------------------------------------------

RULE: The compatibility engine operates at the Seeker level.
It never operates at the Guardian level.

Each Seeker linked to a Guardian is evaluated independently
for compatibility, hard requirements, and visibility.
A Seeker's profile never affects another Seeker's visibility
simply because they share the same Guardian.

EXAMPLE

  Guardian Ahmed is linked to:
    Son A — smokes
    Son B — does not smoke

  Another Seeker has a Hard Requirement:
    🚫 Never show anyone who smokes.

  Incorrect (Guardian-level filtering):
    Guardian Ahmed disappears from the Network entirely
    because Son A does not satisfy the requirement.

  Correct (Seeker-level filtering):
    Son A → ❌ Fails Hard Requirement → Not shown.
    Son B → ✅ Passes Hard Requirement → Shown.
    Guardian Ahmed remains visible in the Network,
    showing only Son B's card.

CONSEQUENCES

  — A Guardian with multiple Seekers may have different numbers
    of Seeker rows visible to different Network viewers.

  — A Guardian card may show 2 Seekers to one viewer and
    1 Seeker to another, depending on compatibility.

  — If none of a Guardian's linked Seekers pass compatibility,
    the Guardian card does not appear at all for that viewer.

  — Each Seeker card in the Network has independent:
      · Compatibility filtering
      · Hard Requirement filtering
      · Visibility
      · Family Introduction requests

ALIGNMENT WITH BROWSE

  The Guardian Network uses the same compatibility engine,
  hard requirement rules, and visibility logic as Browse.

  The only architectural difference between Browse and
  the Guardian Network is who initiates the introduction:

    Browse:        Seeker initiates.
    Guardian Network:  Guardian initiates on behalf of their Seeker.

  The underlying engine is identical.

------------------------------------------------------------
EXCEPTIONAL CASES (DEFERRED)
------------------------------------------------------------

The following scenarios are not handled in core onboarding.
Deferred to ZYRA's Islamic Governance document:

  — Seeker has no living male guardian
  — Seeker is a revert with no Muslim male family member
  — Dispute over who has Guardian authority
  — Guardian becomes unavailable mid-journey
  — Female guardian acting in Guardian capacity in exceptional
    circumstances

------------------------------------------------------------
PENDING ITEMS
------------------------------------------------------------

The following items require formal resolution:

  GUARDIAN ACCOUNT LINKING LIMITS
  No artificial cap is currently imposed. A formal linking
  policy must be specified before production.
  Outstanding item: Guardian Account Linking Limits V1.

  INCLUDED ENTITLEMENT REASSIGNMENT RULES
  The exact rules for when and how the included entitlement
  may be reassigned (e.g. cooldown, frequency limits) are
  pending formal specification.

  FAMILY STAGE — GUARDIAN PARTICIPATION RULES
  Detailed Guardian conversation permissions during the Family
  Stage are deferred to the Family Stage specification.

  GUARDIAN ↔ GUARDIAN COMMUNICATION
  Private Guardian-to-Guardian communication rules depend on the
  Family Stage specification.

