FEATURE NAME
ZYRA — Platform Architecture
Document: Wali Architecture

============================================================
WALI ARCHITECTURE
============================================================

Status: CURRENT_VERSION_V1
Last Updated: 2026-06-28

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

------------------------------------------------------------
THREE ENTRY PATHS
------------------------------------------------------------

PATH 1 — Seeker Invites a Basic Wali

  The Seeker completes onboarding and invites their Wali.
  The invitation is sent via the Wali's email or mobile.
  The invitation creates a Basic Wali relationship.

  If the Wali does not have a ZYRA account:
    → They create a Wali account and are auto-linked.

  If the Wali already has a Basic Wali account:
    → Accepting the invitation links them immediately.
    → The Wali must not already hold an active Basic link.
      If they do, they are prompted to upgrade to Pro.

PATH 2 — Seeker Purchases Wali Pro

  The Seeker purchases a Wali Pro licence for their Wali.
  The invitation explains that a Pro seat has already been
  purchased and is waiting for the Wali to activate.

  When the Wali signs in or creates their account:
  ZYRA detects the waiting licence and prompts:
    "A Wali Pro licence has already been purchased for you.
     Would you like to activate it?"

  Once accepted, the Pro licence is attached to that
  Wali–Seeker relationship.

PATH 3 — Wali Starts First

  A parent or guardian organises everything before the
  Seeker joins. This reflects how many Muslim families
  naturally operate and is a first-class path.

  1. Wali creates a Wali account.
  2. Wali purchases Wali Pro — or remains on Basic.
  3. Wali generates an invitation for their son or daughter.
  4. Seeker joins using that invitation link.
  5. Both accounts are automatically linked.

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
WALI TIER RULES
------------------------------------------------------------

WALI BASIC (Free)

  Every Wali account includes one free Basic relationship.
  A Wali account may only hold one active Basic relationship
  at any time.

  Example:
    Father
    ✓ Daughter A — Basic (free, 1 of 1 allowed)

  If the father wants to supervise a second Seeker
  simultaneously, he must purchase Wali Pro for that
  additional relationship.

  This prevents one free Basic account from supporting
  unlimited Seekers.

WALI PRO (£9.99 / month per linked Seeker)

  Every Pro licence represents one additional linked Seeker.
  A Wali may purchase as many Pro licences as required.
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

  Either the Seeker or the Wali can pay for a Pro licence.
  The licence is attached to the Wali–Seeker relationship
  regardless of who purchased it.

  — Path 1: Seeker pays (Seeker purchases, invites Wali)
  — Path 2: Wali pays (Wali signs up and purchases their own)
  — Path 3: Seeker pays (Seeker invitation triggers Pro licence)

------------------------------------------------------------
WALI PERMISSIONS MODEL
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
WALI RESPONSIBILITIES
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

The Wali does not:
  — See Chapter 3 (Values) or Chapter 4 (Preferences) answers
  — Control who the Seeker browses or expresses interest in
  — Block introductions without cause

------------------------------------------------------------
SUBSCRIPTION MODEL
------------------------------------------------------------

WALI BASIC
  Cost:      Free
  Limit:     1 active Seeker relationship (hard cap)

WALI PRO
  Cost:      £9.99/month per linked Seeker
  Limit:     None — purchase as many licences as needed
  Who pays:  Either the Seeker or the Wali

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

  A Wali may optionally pay for the linked Seeker's
  Seeker subscription. This is separate from the Wali tier.

  Example: A father holds a Wali Pro licence AND pays
  for his daughter's Seeker Premium subscription.

  Two independent billing concepts:
    1. Wali tier (Basic = free / Pro = £9.99/month per Seeker)
    2. Seeker subscription — paid by Seeker or by Wali

------------------------------------------------------------
WALI SCREEN FLOW
------------------------------------------------------------

Path 1 — Seeker invites Wali (Basic):
  [ Invite Your Wali ] → ZYRA sends SMS/email (Basic)
  → [ Wali Invitation Landing ] → [ Create Account ]
  → [ Wali Onboarding ] → [ Wali Dashboard ]

Path 2 — Seeker purchases Wali Pro:
  [ Invite Your Wali ] → Seeker pays → ZYRA sends SMS/email (Pro)
  → [ Wali Invitation Landing ] → [ Create / Sign In ]
  → Prompt: "A Pro licence is waiting — activate it?"
  → [ Wali Onboarding ] → [ Wali Dashboard ]

Path 3 — Wali starts first:
  [ Wali Sign Up ] → [ Choose Tier: Basic / Pro ]
  → [ Wali Onboarding ] → [ Wali Dashboard ]
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
  — Dispute over who has Wali authority
  — Wali becomes unavailable mid-journey
  — Female guardian acting in Wali capacity in exceptional
    circumstances


------------------------------------------------------------
WALI NETWORK — ARCHITECTURE
------------------------------------------------------------

Status: Approved
Last Updated: 2026-06-28

WHAT THE WALI NETWORK IS

The Wali Network is not a second Browse page.
It is a family introduction facilitation layer,
visible only to verified Walis.

The entity shown in the Network is the Seeker's
profile card — the same card that exists on the
platform — but it is only surfaced to Walis.

Purpose:
  — Facilitate family introductions
  — Enable Wali-to-Wali connection
  — Not a shortcut around the normal matching flow

SYSTEM-CONTROLLED CARDS — NO FREE TEXT

Walis cannot write custom introductions or biographies
for the Seekers they represent.

Reason:
Free text creates a privacy loophole. A Wali could
reveal information that ZYRA intentionally hides
through progressive disclosure, including:
  — Occupation
  — Education
  — Religious practice
  — Previous marriage history
  — Financial situation
  — Compatibility answers

Every Wali Network card is entirely system-controlled.
The Wali cannot add, remove, or modify the information
shown. Only ZYRA determines what is displayed.

SEEKER CONSENT

Because the Wali Network uses the Seeker's profile card,
explicit consent is required.

When a Seeker links a Wali, they must agree to clear
Terms & Conditions explaining:
  — What their linked Wali can view
  — What information may be displayed to other verified
    Walis within the Wali Network
  — That their profile card becomes visible in the Network
    once a Wali is linked

The Seeker must knowingly consent before their profile
becomes available within the Network.
Consent is collected during the Wali linking flow
(Invite Your Wali screen, onboarding or post-onboarding).

WALI NETWORK FLOW

1. Wali A discovers Seeker B's system-controlled card
   through the Network.

2. Wali A sends a Family Introduction Request to Wali B.

3. Wali B reviews Seeker A's system-controlled card.

4. Wali B accepts or declines.

5. If both Walis agree:
   The introduction request is presented to both Seekers.

6. Each Seeker independently accepts or declines.

7. If both Seekers accept:
   The normal ZYRA Journey begins.

Key principle:
Walis agree that an introduction is worth presenting.
They are not accepting on behalf of Seekers.
Seeker consent is always required before a Journey begins.

WHAT THE NETWORK CONTAINS (current and future)

  — Family introduction requests
  — Wali-to-Wali communication (within introduction context)
  — Trusted family connections
  — Suggested introductions (future)
  — Community referrals (future)
  — Discovery features (if added, live inside Network —
    not as a separate Browse tab)

