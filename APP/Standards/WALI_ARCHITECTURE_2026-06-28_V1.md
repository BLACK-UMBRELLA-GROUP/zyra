FEATURE NAME
ZYRA — Platform Architecture
Document: Guardian Architecture

============================================================
GUARDIAN ARCHITECTURE
============================================================

Status: CURRENT_VERSION_V1
Last Updated: 2026-06-28

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

------------------------------------------------------------
THREE ENTRY PATHS
------------------------------------------------------------

PATH 1 — Seeker Invites a Basic Guardian

  The Seeker completes onboarding and invites their Guardian.
  The invitation is sent via the Guardian's email or mobile.
  The invitation creates a Basic Guardian relationship.

  If the Guardian does not have a ZYRA account:
    → They create a Guardian account and are auto-linked.

  If the Guardian already has a Basic Guardian account:
    → Accepting the invitation links them immediately.
    → The Guardian must not already hold an active Basic link.
      If they do, they are prompted to upgrade to Pro.

PATH 2 — Seeker Purchases Guardian Pro

  The Seeker purchases a Guardian Pro licence for their Guardian.
  The invitation explains that a Pro seat has already been
  purchased and is waiting for the Guardian to activate.

  When the Guardian signs in or creates their account:
  ZYRA detects the waiting licence and prompts:
    "A Guardian Pro licence has already been purchased for you.
     Would you like to activate it?"

  Once accepted, the Pro licence is attached to that
  Guardian–Seeker relationship.

PATH 3 — Guardian Starts First

  A parent or guardian organises everything before the
  Seeker joins. This reflects how many Muslim families
  naturally operate and is a first-class path.

  1. Guardian creates a Guardian account.
  2. Guardian purchases Guardian Pro — or remains on Basic.
  3. Guardian generates an invitation for their son or daughter.
  4. Seeker joins using that invitation link.
  5. Both accounts are automatically linked.

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
GUARDIAN TIER RULES
------------------------------------------------------------

GUARDIAN BASIC (Free)

  Every Guardian account includes one free Basic relationship.
  A Guardian account may only hold one active Basic relationship
  at any time.

  Example:
    Father
    ✓ Daughter A — Basic (free, 1 of 1 allowed)

  If the father wants to supervise a second Seeker
  simultaneously, he must purchase Guardian Pro for that
  additional relationship.

  This prevents one free Basic account from supporting
  unlimited Seekers.

GUARDIAN PRO (£9.99 / month per linked Seeker)

  Every Pro licence represents one additional linked Seeker.
  A Guardian may purchase as many Pro licences as required.
  Licences are independent and each supports one Seeker.

  Examples:
    1 daughter → 1 Pro licence  → £9.99/month
    2 daughters → 2 Pro licences → £19.98/month
    4 daughters → 4 Pro licences → £39.96/month

COMBINED EXAMPLE (Father with 3 daughters):

    Daughter A → Basic     (free — the 1 allowed Basic)
    Daughter B → Pro       (£9.99/month)
    Daughter C → Pro       (£9.99/month)
    Total: £19.98/month

    The father cannot hold 2 active Basic relationships.
    Daughters B and C must each have their own Pro licence.

WHO PAYS FOR PRO

  Either the Seeker or the Guardian can pay for a Pro licence.
  The licence is attached to the Guardian–Seeker relationship
  regardless of who purchased it.

  — Path 1: Seeker pays (Seeker purchases, invites Guardian)
  — Path 2: Guardian pays (Guardian signs up and purchases their own)
  — Path 3: Seeker pays (Seeker invitation triggers Pro licence)

------------------------------------------------------------
GUARDIAN PERMISSIONS MODEL
------------------------------------------------------------

Can See:
  — Seeker's public profile (as it appears to others)
  — Messages between Seeker and their match (from start)
  — Journey stage and progression status
  — Milestone events (Introduction accepted, Stage 2, etc.)
  — Safety alerts and notifications
  — Family introduction messages (when invited)

Cannot See:
  — Chapter 3 (Values) answers
  — Chapter 4 (Preferences / compatibility settings)
    Compatibility settings remain private to Seeker only.
  — Match list / Browse activity

Can Act:
  — Approve/gate Journey stage progression
  — Accept/decline family introduction invitations
  — Send messages within family introduction context
  — Raise a concern or flag to ZYRA support

------------------------------------------------------------
GUARDIAN RESPONSIBILITIES
------------------------------------------------------------

  ✓ Viewing the progress of each Journey
  ✓ Viewing messages between Seeker and their match
  ✓ Receiving invitations to key milestones
  ✓ Participating in family introductions
  ✓ Joining conversations when appropriate
  ✓ Approving progression at defined Journey gates
  ✓ Receiving safety notifications when necessary
  ✓ Helping ensure the process remains respectful
    and family-oriented

The Guardian does not:
  — See Chapter 3 (Values) or Chapter 4 (Preferences) answers
  — Control who the Seeker browses or expresses interest in
  — Block introductions without cause

------------------------------------------------------------
SUBSCRIPTION MODEL
------------------------------------------------------------

GUARDIAN BASIC
  Cost:      Free
  Limit:     1 active Seeker relationship (hard cap)

GUARDIAN PRO
  Cost:      £9.99/month per linked Seeker
  Limit:     None — purchase as many licences as needed
  Who pays:  Either the Seeker or the Guardian

PRO LICENCE REASSIGNMENT SAFEGUARDS

  To prevent a Pro licence rotating between Seekers:

  1. Cooldown on reassignment
     A 5-day cooldown applies when a Pro licence is
     reassigned. The licence is inactive for the new
     Seeker until the cooldown elapses.

  2. Reassignment frequency cap
     A Pro licence may only be reassigned once every
     3 months.

  3. Active Journey block
     Reassignment is blocked if the current linked Seeker
     is in an Active Journey. Reassignment only becomes
     available once that Journey has ended or been
     formally closed.

  These safeguards allow genuine family transitions
  (one child's journey ends, another begins) while
  preventing a single Pro licence from supporting
  multiple active Seekers in rotation.

  Basic links: The 1-Seeker cap is strictly enforced.
  Basic cannot rotate or be reassigned without the same
  cooldown and frequency safeguards.

SEEKER SUBSCRIPTION SPONSORSHIP

  A Guardian may optionally pay for the linked Seeker's
  Seeker subscription. This is separate from the Guardian tier.

  Example: A father holds a Guardian Pro licence AND pays
  for his daughter's Seeker Premium subscription.

  Two independent billing concepts:
    1. Guardian tier (Basic = free / Pro = £9.99/month per Seeker)
    2. Seeker subscription — paid by Seeker or by Guardian

------------------------------------------------------------
GUARDIAN SCREEN FLOW
------------------------------------------------------------

Path 1 — Seeker invites Guardian (Basic):
  [ Invite Your Guardian ] → ZYRA sends SMS/email (Basic)
  → [ Guardian Invitation Landing ] → [ Create Account ]
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]

Path 2 — Seeker purchases Guardian Pro:
  [ Invite Your Guardian ] → Seeker pays → ZYRA sends SMS/email (Pro)
  → [ Guardian Invitation Landing ] → [ Create / Sign In ]
  → Prompt: "A Pro licence is waiting — activate it?"
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]

Path 3 — Guardian starts first:
  [ Guardian Sign Up ] → [ Choose Tier: Basic / Pro ]
  → [ Guardian Onboarding ] → [ Guardian Dashboard ]
  → [ Invite Seeker ] → Seeker receives SMS/email
  → [ Seeker Invitation Landing ] → Seeker onboarding
  → Accounts linked

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
GUARDIAN NETWORK — ARCHITECTURE
------------------------------------------------------------

Status: Approved
Last Updated: 2026-06-28

WHAT THE GUARDIAN NETWORK IS

The Guardian Network is not a second Browse page.
It is a family introduction facilitation layer,
visible only to verified Guardians.

The entity shown in the Network is the Seeker's
profile card — the same card that exists on the
platform — but it is only surfaced to Guardians.

Purpose:
  — Facilitate family introductions
  — Enable Guardian-to-Guardian connection
  — Not a shortcut around the normal matching flow

SYSTEM-CONTROLLED CARDS — NO FREE TEXT

Guardians cannot write custom introductions or biographies
for the Seekers they represent.

Reason:
Free text creates a privacy loophole. A Guardian could
reveal information that ZYRA intentionally hides
through progressive disclosure, including:
  — Occupation
  — Education
  — Religious practice
  — Previous marriage history
  — Financial situation
  — Compatibility answers

Every Guardian Network card is entirely system-controlled.
The Guardian cannot add, remove, or modify the information
shown. Only ZYRA determines what is displayed.

SEEKER CONSENT

Because the Guardian Network uses the Seeker's profile card,
explicit consent is required.

When a Seeker links a Guardian, they must agree to clear
Terms & Conditions explaining:
  — What their linked Guardian can view
  — What information may be displayed to other verified
    Guardians within the Guardian Network
  — That their profile card becomes visible in the Network
    once a Guardian is linked

The Seeker must knowingly consent before their profile
becomes available within the Network.
Consent is collected during the Guardian linking flow
(Invite Your Guardian screen, onboarding or post-onboarding).

GUARDIAN NETWORK FLOW

1. Guardian A discovers Seeker B's system-controlled card
   through the Network.

2. Guardian A sends a Family Introduction Request to Guardian B.

3. Guardian B reviews Seeker A's system-controlled card.

4. Guardian B accepts or declines.

5. If both Guardians agree:
   The introduction request is presented to both Seekers.

6. Each Seeker independently accepts or declines.

7. If both Seekers accept:
   The normal ZYRA Journey begins.

Key principle:
Guardians agree that an introduction is worth presenting.
They are not accepting on behalf of Seekers.
Seeker consent is always required before a Journey begins.

WHAT THE NETWORK CONTAINS (current and future)

  — Family introduction requests
  — Guardian-to-Guardian communication (within introduction context)
  — Trusted family connections
  — Suggested introductions (future)
  — Community referrals (future)
  — Discovery features (if added, live inside Network —
    not as a separate Browse tab)

